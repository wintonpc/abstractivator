module Abstractivator
  module Trees

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
          set_hash_path(path_tree, path.split('/'), block)
        end
        path_tree
      end

      def delete
        @delete ||= Object.new
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
