require 'active_support/core_ext/object/deep_dup'
require 'abstractivator/trees/block_collector'
require 'abstractivator/proc_ext'
require 'sourcify'
require 'delegate'
require 'set'
require 'immutable_struct'

module Abstractivator
  module Trees

    Diff = ImmutableStruct.new(:path, :tree, :mask, :error)

    # Compares a tree to a mask.
    # Returns a diff of where the tree differs from the mask.
    # Ignores parts of the tree not specified in the mask.
    def tree_compare(tree, mask, path=[], index=nil)
      if mask == [:*] && tree.is_a?(Enumerable)
        []
      elsif mask == :+ && tree != :__missing__
        []
      elsif mask == :- && tree != :__missing__
        [diff(path, tree, :__absent__)]
      elsif (custom_mask = as_custom_mask(mask))
        custom_mask.call(tree, path, index)
      elsif mask.callable?
        are_equivalent = mask.call(tree)
        are_equivalent ? [] : [diff(path, tree, mask)]
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
              # if the mask is programmatically generated (unlikely), then
              # the mask might be really big and this could blow the stack.
              # don't support this case for now.
              tree_compare(tree.first, mask.first, push_path(path, index.to_s)) +
                  tree_compare(tree.drop(1), mask.drop(1), path, index + 1)
            end
          else
            [diff(path, tree, mask)]
          end
        else
          tree == mask ? [] : [diff(path, tree, mask)]
        end
      end
    end

    private

    def as_custom_mask(x)
      return x.method(:compare) if x.respond_to?(:compare)
      return x.method(:call) if x.callable? && x.parameters.size == 3
      nil
    end

    def push_path(path, name)
      path + [name]
    end

    def diff(*args)
      Trees.diff(*args)
    end

    def self.diff(path, tree, mask, error=nil)
      Diff.new(path_string(path), tree, massage_mask_for_diff(mask), error)
    end

    def self.path_string(path)
      path.join('/')
    end

    def self.massage_mask_for_diff(mask)
      if mask.callable?
        massaged = :__predicate__
        begin
          massaged = mask.to_source
        rescue Exception => e
          raise unless e.class.name.start_with?('Sourcify')
        end
        massaged
      else
        mask
      end
    end
  end
end
