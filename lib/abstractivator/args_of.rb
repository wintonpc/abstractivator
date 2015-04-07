require 'abstractivator/trees/tree_compare'
require 'binding_of_caller'
require 'abstractivator/array_ext'

module Kernel
  private

  def args_of(*patterns)
    caller_args = ArgsOf.frame_args(1).map(&:value)
    error = test_args(patterns, caller_args)
    fail error if error
  end

  def test_args(patterns, args)
    masks = patterns.map(&ArgsOf.method(:mask_for))
    diffs = Abstractivator::Trees.tree_compare(args, masks)
    diffs.any? and raise make_argument_error(diffs)
  end

  def make_argument_error(diffs)
    ArgumentError.new(diffs.first.error)
  end

  class ArgsOf
    class << self
      def frame_args(offset=0)
        parent_binding = binding.of_caller(offset + 1)
        parameter_names = parent_binding.eval('method(__method__)').parameters.map(&:last)
        parameter_names.map{|p| [p, parent_binding.eval(p.to_s)]}
      end

      def mask_for(pattern)
        if pattern.is_a?(Class)
          proc do |tree, path, index|
            if tree.is_a?(pattern)
              []
            else
              [Abstractivator::Trees::Diff.new(path, tree, self, "Expected #{pattern.name} but got #{tree.class.name} (#{tree})")]
            end
          end
        else
          proc{true}
        end
      end
    end
  end
end
