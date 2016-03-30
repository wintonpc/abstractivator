require 'rspec'
require 'abstractivator/trees/tree_compare'
require 'json'
require 'rails'
require 'pp'

describe Abstractivator::Trees do

  include Abstractivator::Trees

  describe '#tree_compare' do

    extend Abstractivator::Trees

    def self.example(description, values)
      it description do
        tree, mask, expected = values[:tree], values[:mask], values[:result]
        expect(tree_compare(tree, mask)).to eql expected
      end
    end

    example 'returns an empty list if the tree is comparable to the mask',
            tree:   {a: 1},
            mask:   {a: 1},
            result: []

    example 'only requires the mask to match a subtree',
            tree:   {a: 1, b: 1},
            mask:   {a: 1},
            result: []

    example 'returns a list of differences',
            tree:   {a: 1, b: {c: [8, 8]}},
            mask:   {a: 2, b: {c: [8, 9]}},
            result: [{path: 'a', tree: 1, mask: 2},
                     {path: 'b/c/1', tree: 8, mask: 9}]

    example 'returns a list of differences for missing values',
            tree:   {},
            mask:   {a: 2, b: nil},
            result: [{path: 'a', tree: :__missing__, mask: 2}, {path: 'b', tree: :__missing__, mask: nil}]

    example 'compares hash values',
            tree:   {a: 1},
            mask:   {a: 2},
            result: [{path: 'a', tree: 1, mask: 2}]

    example 'compares array values',
            tree:   {a: [1, 2]},
            mask:   {a: [1, 3]},
            result: [{path: 'a/1', tree: 2, mask: 3}]

    example 'compares with predicates',
            tree:   {a: 1},
            mask:   {a: proc {|x| x.even?}},
            result: [{path: 'a', tree: 1, mask: :__predicate__}]

    example 'can ensure values are absent with :-',
            tree:   {a: 1},
            mask:   {a: :-},
            result: [{path: 'a', tree: 1, mask: :__absent__}]

    example 'can check for any value being present with :+',
            tree:   {a: 1, b: [1, 2, 3]},
            mask:   {a: :+, b: [1, :+, 3]},
            result: []

    context 'when comparing arrays' do
      example 'reports the tree being shorter',
              tree:   {a: [1]},
              mask:   {a: [1, 2]},
              result: [{path: 'a/1', tree: :__missing__, mask: [2]}]

      example 'reports the mask being shorter',
              tree:   {a: [1, 2]},
              mask:   {a: [1]},
              result: [{path: 'a/1', tree: [2], mask: :__absent__}]

      example 'can allow arbitrary tails with :*',
              tree:   {a: [1, 2, 3], b: [1], c: [2]},
              mask:   {a: [1, :*], b: [1, :*], c: [1, :*]},
              result: [{path: 'c/0', tree: 2, mask: 1}]
    end

    context 'when comparing sets' do

      def self.get_name
        ->(x){ x[:name] }
      end

      example 'allows out-of-order arrays',
              tree:   {set: [{id: 2, name: 'b'}, {id: 1, name: 'a'}]},
              mask:   {set: set_mask([{id: 1, name: 'a'}, {id: 2, name: 'b'}], get_name)},
              result: []

      example 'reports missing set attribute in the tree',
              tree:   {},
              mask:   {set: set_mask([{id: 1, name: 'a'}], get_name)},
              result: [{path: 'set', tree: :__missing__, mask: [{id: 1, name: 'a'}]}]

      example 'reports missing items in the tree',
              tree:   {set: []},
              mask:   {set: set_mask([{id: 1, name: 'a'}], get_name)},
              result: [{path: 'set/a', tree: :__missing__, mask: {id: 1, name: 'a'}}]

      example 'reports extra items in the tree',
              tree:   {set: [{id: 1, name: 'a'}]},
              mask:   {set: set_mask([], get_name)},
              result: [{path: 'set/a', tree: {id: 1, name: 'a'}, mask: :__absent__}]

      example 'reports duplicate keys in the tree',
              tree:   {set: [{id: 1, name: 'a'}, {id: 2, name: 'a'}]},
              mask:   {set: set_mask([:*], get_name)},
              result: [{path: 'set', tree: [:__duplicate_keys__, ['a']], mask: nil}]

      example 'reports duplicate keys in the mask',
              tree:   {set: [{id: 1, name: 'a'}]},
              mask:   {set: set_mask([{id: 1, name: 'a'}, {id: 2, name: 'a'}], get_name)},
              result: [{path: 'set', tree: nil, mask: [:__duplicate_keys__, ['a']]}]

      example 'can test for only a subset',
              tree:   {set: [{id: 1, name: 'a'}, {id: 2, name: 'b'}]},
              mask:   {set: set_mask([{id: 2, name: 'b'}, :*], get_name)},
              result: []
    end



    context 'reports mismatched types' do
      example 'hash for primitive',
              tree:   {a: {b: 1}},
              mask:   {a: 1},
              result: [{path: 'a', tree: {b: 1}, mask: 1}]

      example 'primitive for hash',
              tree:   {a: 1},
              mask:   {a: {b: 1}},
              result: [{path: 'a', tree: 1, mask: {b: 1}}]

      example 'array for primitive',
              tree:   {a: [1, 2]},
              mask:   {a: 1},
              result: [{path: 'a', tree: [1, 2], mask: 1}]

      example 'primitive for array',
              tree:   {a: 1},
              mask:   {a: [1, 2]},
              result: [{path: 'a', tree: 1, mask: [1, 2]}]

      example 'primitive for set',
              tree:   {set: 1},
              mask:   {set: set_mask([{x: 1}], ->(item) { item[:x] })},
              result: [{path: 'set', tree: 1, mask: [{x: 1}]}]
    end
  end
end
