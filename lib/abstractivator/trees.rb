require 'active_support/core_ext/object/deep_dup'
require 'abstractivator/trees/block_collector'
require 'sourcify'

module Abstractivator
  module Trees

    def recursive_delete!(hash, keys)
      x = hash # hash is named 'hash' for documentation purposes but may be anything
      case x
        when Hash
          keys.each{|k| x.delete(k)}
          x.each_value{|v| recursive_delete!(v, keys)}
        when Array
          x.each{|v| recursive_delete!(v, keys)}
      end
      x
    end

    def tree_compare(tree, mask, path=[], index=nil)
      if mask == [:*] && tree.is_a?(Enumerable)
        []
      elsif mask == :+ && tree != :__missing__
        []
      elsif mask == :- && tree != :__missing__
        [diff(path, tree, :__absent__)]
      elsif mask.respond_to?(:call)
        comparable = mask.call(tree)
        mask_text = :__predicate__
        begin
          mask_text = mask.to_source
        rescue Exception => e
          raise unless e.class.name.start_with?('Sourcify')
        end
        comparable ? [] : [diff(path, tree, mask_text)]
      else
        case mask
          when Hash
            if tree.is_a?(Hash)
              mask.each_pair.flat_map do |k, v|
                tree_compare(tree.fetch(k, :__missing__), v, push_path(path, k))
              end
            else
              [diff(path, tree, mask)]
            end
          when Enumerable
            if tree.is_a?(Enumerable)
              index ||= 0
              if !tree.any? && !mask.any?
                []
              elsif !tree.any?
                [diff(push_path(path, index.to_s), :__missing__, mask)]
              elsif !mask.any?
                [diff(push_path(path, index.to_s), tree, :__absent__)]
              else
                tree_compare(tree.first, mask.first, push_path(path, index.to_s)) +
                    tree_compare(tree.drop(1), mask.drop(1), path, index + 1)
              end
            else
              [diff(path, tree, mask)]
            end
          when SetMask
            if tree.is_a? Enumerable
              if !tree.any? && !mask.any?
                []
              elsif !tree.any?
                [diff(push_path(path, mask.get_key(mask.first)), :__missing__, mask.to_set)]
              elsif !mask.any?
                [diff(push_path(path, mask.get_key(tree.first)), tree, :__absent__)]
              else
                key = mask.get_key(tree.first)
                tree_compare(tree.first, mask[key], push_path(path, key)) +
                    tree_compare(tree.drop(1), mask.drop(key), path)
              end
            else
              [diff(path, tree, mask.to_set)]
            end
          else
            tree == mask ? [] : [diff(path, tree, mask)]
        end
      end
    end

    def diff(path, tree, mask)
      {path: path_string(path), tree: tree, mask: mask}
    end

    def push_path(path, name)
      path + [name]
    end

    def path_string(path)
      path.join('/')
    end

    def tree_map(h)
      raise ArgumentError.new('Must provide a transformer block') unless block_given?
      config = BlockCollector.new
      yield(config)
      TransformTreeClosure.new.do_obj(h, config.get_path_tree)
    end

    class TransformTreeClosure
      def initialize
        @bias = 0 # symbol = +, string = -
      end

      def do_obj(obj, path_tree)
        case obj
          when nil; nil
          when Array; do_array(obj, path_tree)
          else; do_hash(obj, path_tree)
        end
      end

      private

      def do_hash(h, path_tree)
        h = h.dup
        path_tree.each_pair do |name, path_tree|
          if path_tree.respond_to?(:call)
            if (hash_name = try_get_hash_name(name))
              hash_name, old_fh = get_key_and_value(h, hash_name)
              unless old_fh.nil?
                h[hash_name] = old_fh.each_with_object(old_fh.dup) do |(key, value), fh|
                  fh[key] = path_tree.call(value.deep_dup)
                end
              end
            elsif (array_name = try_get_array_name(name))
              array_name, value = get_key_and_value(h, array_name)
              unless value.nil?
                h[array_name] = value.map(&:deep_dup).map(&path_tree)
              end
            else
              name, value = get_key_and_value(h, name)
              h[name] = path_tree.call(value.deep_dup)
            end
          else
            name, value = get_key_and_value(h, name)
            h[name] = do_obj(value, path_tree)
          end
        end
        h
      end

      def get_key_and_value(h, string_key)
        tried_symbol = @bias >= 0
        trial_key = tried_symbol ? string_key.to_sym : string_key
        value = h[trial_key]

        if value.nil? # failed
          @bias += (tried_symbol ? -1 : 1)
          key = tried_symbol ? string_key : string_key.to_sym
          [key, h[key]]
        else
          @bias += (tried_symbol ? 1 : -1)
          [trial_key, value]
        end
      end

      def do_array(a, path_tree)
        a.map{|x| do_obj(x, path_tree)}
      end

      def try_get_hash_name(p)
        p =~ /(.+)\{\}$/ ? $1 : nil
      end

      def try_get_array_name(p)
        p =~ /(.+)\[\]$/ ? $1 : nil
      end
    end

  end
end
