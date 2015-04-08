require 'abstractivator/callable_class'
require 'abstractivator/trees/tree_compare'
require 'abstractivator/args_of/compound_constraint'

class Any
  def self.compare(_tree, _path, _index)
    []
  end
end

class Or
  include Abstractivator::ArgsOf::CompoundConstraint

  def initialize(*masks)
    @masks = masks
  end

  def compare(tree, path, index)
    diffs = @masks.flat_map{|mask| Abstractivator::Trees.tree_compare(tree, mask, path, index) }
    if diffs.none?(&:empty?)
      [Abstractivator::Trees::Diff.new(path, tree, self, message)]
    end
  end
end
