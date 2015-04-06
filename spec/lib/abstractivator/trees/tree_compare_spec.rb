require 'rspec'
require 'abstractivator/trees/tree_compare'
require 'json'
require 'rails'
require 'pp'

describe Abstractivator::Trees do

  include Abstractivator::Trees

  describe '#tree_compare' do

    extend Abstractivator::Trees

    def verify(values)
      tree, mask, expected = values[:tree], values[:mask], values[:result]
      expect(tree_compare(tree, mask)).to eql expected
    end

    def diffs(*attrs_array)
      attrs_array.map(&method(:make_diff))
    end

    def make_diff(values)
      Abstractivator::Trees::Diff.new(values[:path], values[:tree], values[:mask], values[:error])
    end

    it 'returns an empty list if the tree is comparable to the mask' do
      verify tree:   {a: 1},
             mask:   {a: 1},
             result: []
    end

    it 'only requires the mask to match a subtree' do
      verify tree:   {a: 1, b: 1},
             mask:   {a: 1},
             result: []
    end

    it 'returns a list of differences' do
      verify tree:   {a: 1, b: {c: [8, 8]}},
             mask:   {a: 2, b: {c: [8, 9]}},
             result: diffs({path: 'a', tree: 1, mask: 2},
                           {path: 'b/c/1', tree: 8, mask: 9})
    end

    it 'returns a list of differences for missing values' do
      verify tree:   {},
             mask:   {a: 2, b: nil},
             result: diffs({path: 'a', tree: :__missing__, mask: 2},
                           {path: 'b', tree: :__missing__, mask: nil})
    end

    it 'compares hash values' do
      verify tree:   {a: 1},
             mask:   {a: 2},
             result: diffs({path: 'a', tree: 1, mask: 2})
    end

    it 'compares array values' do
      verify tree:   {a: [1, 2]},
             mask:   {a: [1, 3]},
             result: diffs({path: 'a/1', tree: 2, mask: 3})
    end

    it 'compares with predicates' do
      verify tree:   {a: 1},
             mask:   {a: proc {|x| x.even?}},
             result: diffs({path: 'a', tree: 1, mask: 'proc { |x| x.even? }'})
    end

    it 'compares with predicates (degrades gracefully when source code is unavailable)' do
      verify tree:   {a: 1},
             mask:   {a: :even?.to_proc},
             result: diffs({path: 'a', tree: 1, mask: :__predicate__})
    end

    it 'compares with predicates (lets non-sourcify errors through)' do
      expect{tree_compare({a: 1}, {a: proc { raise 'oops' }})}.to raise_error
    end

    it 'can ensure values are absent with :-' do
      verify tree:   {a: 1},
             mask:   {a: :-},
             result: diffs({path: 'a', tree: 1, mask: :__absent__})
    end

    it 'can check for any value being present with :+' do
      verify tree:   {a: 1, b: [1, 2, 3]},
             mask:   {a: :+, b: [1, :+, 3]},
             result: []
    end

    context 'when comparing arrays' do
      it 'reports the tree being shorter' do
        verify tree:   {a: [1]},
               mask:   {a: [1, 2]},
               result: diffs({path: 'a/1', tree: :__missing__, mask: [2]})
      end

      it 'reports the mask being shorter' do
        verify tree:   {a: [1, 2]},
               mask:   {a: [1]},
               result: diffs({path: 'a/1', tree: [2], mask: :__absent__})
      end

      it 'can allow arbitrary tails with :*' do
        verify tree:   {a: [1, 2, 3], b: [1], c: [2]},
               mask:   {a: [1, :*], b: [1, :*], c: [1, :*]},
               result: diffs({path: 'c/0', tree: 2, mask: 1})
      end
    end

    context 'when comparing sets' do

      def get_name
        ->(x){ x[:name] }
      end

      it 'allows out-of-order arrays' do
        verify tree:   {set: [{id: 2, name: 'b'}, {id: 1, name: 'a'}]},
               mask:   {set: set_mask([{id: 1, name: 'a'}, {id: 2, name: 'b'}], get_name)},
               result: []
      end

      it 'reports missing set attribute in the tree' do
        verify tree:   {},
               mask:   {set: set_mask([{id: 1, name: 'a'}], get_name)},
               result: diffs({path: 'set', tree: :__missing__, mask: [{id: 1, name: 'a'}]})
      end

      it 'reports missing items in the tree' do
        verify tree:   {set: []},
               mask:   {set: set_mask([{id: 1, name: 'a'}], get_name)},
               result: diffs({path: 'set/a', tree: :__missing__, mask: {id: 1, name: 'a'}})
      end

      it 'reports extra items in the tree' do
        verify tree:   {set: [{id: 1, name: 'a'}]},
               mask:   {set: set_mask([], get_name)},
               result: diffs({path: 'set/a', tree: {id: 1, name: 'a'}, mask: :__absent__})
      end

      it 'reports duplicate keys in the tree' do
        verify tree:   {set: [{id: 1, name: 'a'}, {id: 2, name: 'a'}]},
               mask:   {set: set_mask([:*], get_name)},
               result: diffs({path: 'set', tree: [:__duplicate_keys__, ['a']], mask: nil})
      end

      it 'reports duplicate keys in the mask' do
        verify tree:   {set: [{id: 1, name: 'a'}]},
               mask:   {set: set_mask([{id: 1, name: 'a'}, {id: 2, name: 'a'}], get_name)},
               result: diffs({path: 'set', tree: nil, mask: [:__duplicate_keys__, ['a']]})
      end

      it 'can test for only a subset' do
        verify tree:   {set: [{id: 1, name: 'a'}, {id: 2, name: 'b'}]},
               mask:   {set: set_mask([{id: 2, name: 'b'}, :*], get_name)},
               result: []
      end
    end

    context 'reports mismatched types' do
      it 'hash for primitive' do
        verify tree:   {a: {b: 1}},
               mask:   {a: 1},
               result: diffs({path: 'a', tree: {b: 1}, mask: 1})
      end

      it 'primitive for hash' do
        verify tree:   {a: 1},
               mask:   {a: {b: 1}},
               result: diffs({path: 'a', tree: 1, mask: {b: 1}})
      end

      it 'array for primitive' do
        verify tree:   {a: [1, 2]},
               mask:   {a: 1},
               result: diffs({path: 'a', tree: [1, 2], mask: 1})
      end

      it 'primitive for array' do
        verify tree:   {a: 1},
               mask:   {a: [1, 2]},
               result: diffs({path: 'a', tree: 1, mask: [1, 2]})
      end

      it 'primitive for set' do
        verify tree:   {set: 1},
               mask:   {set: set_mask([{x: 1}], ->(item) { item[:x] })},
               result: diffs({path: 'set', tree: 1, mask: [{x: 1}]})
      end
    end
  end
end
