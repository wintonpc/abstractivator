require 'abstractivator/trees/tree_compare'
require 'abstractivator/array_ext'
require 'enumerable_ext'
require 'abstractivator/binding_utils'
require 'abstractivator/args_of/builtin_constraints'

module Kernel
  private
  def args_of(*patterns)
    caller_args = Abstractivator::BindingUtils.frame_args(1).map(&:value)
    error = Abstractivator::ArgsOf.test_args(patterns, caller_args)
    fail error if error
  end
end

module Abstractivator
  class ArgsOf
    class << self

      def test_args(patterns, args)
        masks = patterns.deep_map(&ArgsOf.method(:mask_for))
        diffs = Abstractivator::Trees.tree_compare(args, masks)
        diffs.any? && make_argument_error(diffs)
      end

      def make_argument_error(diffs)
        ArgumentError.new(diffs.first.error)
      end

      private

      def mask_for(pattern)
        if pattern.is_a?(Class) && !pattern.respond_to?(:compare)
          type_mask(pattern)
        else
          pattern
        end
      end

      def type_mask(pattern)
        proc do |tree, path, index|
          if tree.is_a?(pattern)
            []
          else
            [Abstractivator::Trees::Diff.new(path, tree, self, "Expected #{pattern.name} but got #{tree.class.name} (#{tree})")]
          end
        end
      end

    end
  end
end

