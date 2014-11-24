require 'abstractivator/collections'
require 'abstractivator/cons'
require 'abstractivator/tree_visitor/path'

module Abstractivator
  module TreeVisitor

    def transform_tree2(h)
      raise ArgumentError.new('Must provide a transformer block') unless block_given?
      config = BlockCollector.new
      yield(config)
      do_obj(h, config.get_path_tree)
    end

    private

    def do_obj(obj, path_tree)
      case obj
        when nil; nil
        when Array; do_array(obj, path_tree)
        else; do_hash(obj, path_tree)
      end
    end

    def do_hash(h, path_tree)
      h = h.dup
      path_tree.each_pair do |name, path_tree|
        if path_tree.respond_to?(:call)
          if (hash_name = try_get_hash_name(name))
            h[hash_name] = h[hash_name].each_with_object(h[hash_name].dup) do |(key, value), fh|
              fh[key] = path_tree.call(value.deep_dup)
            end
          elsif (array_name = try_get_array_name(name))
            h[array_name] = h[array_name].map(&:deep_dup).map(&path_tree)
          else
            h[name] = path_tree.call(h[name].deep_dup)
          end
        else
          h[name] = do_obj(h[name], path_tree)
        end
      end
      h
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


    class BlockCollector
      def initialize
        @config = {}
      end

      def when(path, &block)
        @config[path] = block
      end

      def get_path_tree
        path_tree = {}
        @config.each_pair do |path, block|
          # set_hash_path(path_tree, path.split('/').map(&:to_sym), block)
          set_hash_path(path_tree, path.split('/'), block)
        end
        path_tree
      end

      private

      def set_hash_path(h, names, block)
        orig = h
        while names.size > 1
          h = (h[names.shift] ||= {})
        end
        h[names.shift] = block
        orig
      end
    end

  end
end