require 'set'
require 'abstractivator/array_ext'

module Abstractivator
  module Trees

    def set_mask(items, get_key)
      SetMask.new(items, get_key)
    end

    class SetMask
      include Trees

      def initialize(items, get_key)
        @items, @get_key = items, get_key
      end

      def compare(tree, path, index)
        if tree.is_a?(Enumerable)
          # convert the enumerables to hashes, then compare those hashes
          tree_items = tree
          mask_items = @items.dup
          get_key = @get_key

          be_strict = !mask_items.delete(:*)
          new_tree = hashify_set(tree_items, get_key)
          new_mask = hashify_set(mask_items, get_key)
          tree_keys = Set.new(new_tree.keys)
          mask_keys = Set.new(new_mask.keys)
          tree_only = tree_keys - mask_keys

          # report duplicate keys
          if new_tree.size < tree_items.size
            diff(path, [:__duplicate_keys__, duplicates(tree_items.map(&get_key))], nil)
          elsif new_mask.size < mask_items.size
            diff(path, nil, [:__duplicate_keys__, duplicates(mask_items.map(&get_key))])
            # hash comparison allows extra values in the tree.
            # report extra values in the tree unless there was a :* in the mask
          elsif be_strict && tree_only.any?
            tree_only.map{|k| diff(push_path(path, k), new_tree[k], :__absent__)}
          else # compare as hashes
            tree_compare(new_tree, new_mask, path, index)
          end
        else
          [diff(path, tree, @items)]
        end
      end

      private

      def duplicates(xs)
        xs.group_by{|x| x}.each_pair.select{|_k, v| v.size > 1}.map(&:key)
      end

      def hashify_set(items, get_key)
        Hash[items.map{|x| [get_key.call(x), x] }]
      end
    end
  end
end
