require 'active_support/core_ext/object/deep_dup'
require 'abstractivator/trees/block_collector'
require 'delegate'
require 'set'

module Abstractivator
  module Trees

    # Transforms a tree at certain paths.
    # The transform is non-destructive and reuses untouched substructure.
    # For efficiency, it first builds a "path_tree" that describes
    # which paths to transform. This path_tree is then used as input
    # for a data-driven algorithm.
    def tree_map(h)
      raise ArgumentError.new('Must provide a transformer block') unless block_given?
      config = BlockCollector.new
      yield(config)
      TransformTreeClosure.new(config).do_obj(h, config.get_path_tree)
    end

    class TransformTreeClosure
      def initialize(config)
        @config = config
        @bias = 0 # symbol = +, string = -
        @no_value = Object.new
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
          if leaf?(path_tree)
            if hash_name = try_get_hash_name(name)
              hash_name, old_fh = get_key_and_value(h, hash_name)
              unless old_fh == @no_value || old_fh.nil?
                old_fh.is_a?(Hash) or raise "Expected a hash but got #{old_fh.class.name}: #{old_fh.inspect}"
                h[hash_name] = old_fh.each_with_object(old_fh.dup) do |(key, value), fh|
                  replacement = path_tree.call(value.deep_dup, key)
                  if deleted?(replacement)
                    fh.delete(key)
                  else
                    fh[key] = replacement
                  end
                end
              end
            elsif array_name = try_get_array_name(name)
              array_name, value = get_key_and_value(h, array_name)
              unless value == @no_value || value.nil?
                value.is_a?(Array) or raise "Expected an array but got #{value.class.name}: #{value.inspect}"
                h[array_name] = value.map(&:deep_dup).each_with_index.map(&path_tree).reject(&method(:deleted?))
              end
            else
              name, value = get_key_and_value(h, name)
              unless value == @no_value
                replacement = path_tree.call(value.deep_dup)
                if deleted?(replacement)
                  h.delete(name)
                else
                  h[name] = replacement
                end
              end
            end
          else # not leaf
            name, value = get_key_and_value(h, name)
            h[name] = do_obj(value, path_tree) unless value == @no_value
          end
        end
        h
      end

      def leaf?(path_tree)
        path_tree.callable?
      end

      def deleted?(value)
        value == @config.delete
      end

      def get_key_and_value(h, string_key)
        tried_symbol = @bias >= 0
        trial_key = tried_symbol ? string_key.to_sym : string_key
        value = try_fetch(h, trial_key)

        if value == @no_value # failed
          @bias += (tried_symbol ? -1 : 1)
          key = tried_symbol ? string_key : string_key.to_sym
          [key, try_fetch(h, key)]
        else
          @bias += (tried_symbol ? 1 : -1)
          [trial_key, value]
        end
      end

      def try_fetch(h, trial_key)
        h.fetch(trial_key, @no_value)
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
