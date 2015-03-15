require 'active_support/core_ext/object/deep_dup'
require 'abstractivator/trees/block_collector'
require 'sourcify'
require 'delegate'
require 'set'

module Abstractivator
  module Trees
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
