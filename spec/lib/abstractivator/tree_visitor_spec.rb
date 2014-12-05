require 'rspec'
require 'abstractivator/tree_visitor'
require 'json'
require 'rails'
require 'pp'

describe Abstractivator::TreeVisitor do

  include Abstractivator::TreeVisitor

  describe '#transform_tree' do

    context 'when no block is provided' do
      it 'raises an exception' do
        expect{ transform_tree(hash) }.to raise_error ArgumentError, 'Must provide a transformer block'
      end
    end

    it 'handles both string and symbol keys' do
      h = {:a => 1, 'b' => 2}
      result = transform_tree(h) do |t|
        t.when('a') {|v| v + 10}
        t.when('b') {|v| v + 10}
      end
      expect(result).to eql({:a => 11, 'b' => 12})
    end

    it 'replaces primitive-type hash fields' do
      h = {'a' => 1}
      result = transform_one_path(h, 'a') { 2 }
      expect(result).to eql({'a' => 2})
    end

    it 'replaces nil hash fields' do
      h = {'a' => nil}
      result = transform_one_path(h, 'a') {|v| v.to_s}
      expect(result).to eql({'a' => ''})
    end

    it 'replaces hash-type hash fields' do
      h = {'a' => {'b' => 1}}
      result = transform_one_path(h, 'a') { {'z' => 99} }
      expect(result).to eql({'a' => {'z' => 99}})
    end

    it 'replaces array-type hash fields' do
      h = {'a' => [1,2,3]}
      result = transform_one_path(h, 'a') {|v| v.reverse}
      expect(result).to eql({'a' => [3,2,1]})
    end

    it 'replaces primitive-type hash members' do
      h = {'a' => {'b' => 'foo', 'c' => 'bar'}}
      result = transform_one_path(h, 'a{}') {|v| v.reverse}
      expect(result).to eql({'a' => {'b' => 'oof', 'c' => 'rab'}})
    end

    it 'replaces hash-type hash members' do
      h = {'a' => {'b' => {'x' => 88}, 'c' => {'x' => 88}}}
      result = transform_one_path(h, 'a{}') {|v| {'y' => 99}}
      expect(result).to eql({'a' => {'b' => {'y' => 99}, 'c' => {'y' => 99}}})
    end

    it 'replaces array-type hash members' do
      h = {'a' => {'b' => [1,2,3], 'c' => [4,5,6]}}
      result = transform_one_path(h, 'a{}') {|v| v.reverse}
      expect(result).to eql({'a' => {'b' => [3,2,1], 'c' => [6,5,4]}})
    end

    it 'replaces primitive-type array members' do
      h = {'a' => [1, 2]}
      result = transform_one_path(h, 'a[]') {|v| v + 10}
      expect(result).to eql({'a' => [11, 12]})
    end

    it 'replaces hash-type array members' do
      h = {'a' => [{'b' => 1}, {'c' => 2}]}
      result = transform_one_path(h, 'a[]') { {'z' => 99} }
      expect(result).to eql({'a' => [{'z' => 99}, {'z' => 99}]})
    end

    it 'replaces array-type array members' do
      h = {'a' => [[1,2,3], [4,5,6]]}
      result = transform_one_path(h, 'a[]') {|v| v.reverse}
      expect(result).to eql({'a' => [[3,2,1], [6,5,4]]})
    end

    context 'when replacing array members' do
      it 'allows the array to be nil' do
        h = {'a' => nil}
        result = transform_one_path(h, 'a[]') {|v| v + 1}
        expect(result).to eql({'a' => nil})
      end
    end

    context 'when replacing hash members' do
      it 'allows the hash to be nil' do
        h = {'a' => nil}
        result = transform_one_path(h, 'a{}') {|v| v + 1}
        expect(result).to eql({'a' => nil})
      end
    end

    context 'mutation' do
      before(:each) do
        @old = {'a' => {'x' => 1, 'y' => 2}, 'b' => {'x' => 17, 'y' => 23}}
        @new = transform_one_path(@old,'a') {|v|
          v['z'] = v['x'] + v['y']
          v
        }
      end
      it 'does not mutate the input' do
        expect(@old).to eql({'a' => {'x' => 1, 'y' => 2}, 'b' => {'x' => 17, 'y' => 23}})
        expect(@new).to eql({'a' => {'x' => 1, 'y' => 2, 'z' => 3}, 'b' => {'x' => 17, 'y' => 23}})
      end
      it 'preserves unmodified substructure' do
        expect(@old['a'].equal?(@new['a'])).to be_falsey
        expect(@old['b'].equal?(@new['b'])).to be_truthy
      end

      it 'really does not mutate the input' do
        old = JSON.parse(File.read('assay.json'))
        old2 = old.deep_dup
        transform_tree(old) do |t|
          t.when('compound_methods/calibration/normalizers[]') {|v| v.to_s.reverse}
          t.when('compound_methods/calibration/responses[]') {|v| v.to_s.reverse}
          t.when('compound_methods/rule_settings{}') {|v| v.to_s.reverse}
          t.when('compound_methods/chromatogram_methods/rule_settings{}') {|v| v.to_s.reverse}
          t.when('compound_methods/chromatogram_methods/peak_integration/retention_time') do |ret_time|
            if ret_time['reference_type_source'] == 'chromatogram'
              ret_time['reference'] = ret_time['reference'].to_s.reverse
            end
            ret_time
          end
        end
        expect(old).to eql old2
      end
    end

    def transform_one_path(h, path, &block)
      transform_tree(h) do |t|
        t.when(path, &block)
      end
    end
  end

  describe '#recursive_delete!' do
    it 'deletes keys in the root hash' do
      h = {a: 1, b: 2}
      recursive_delete!(h, [:a])
      expect(h).to eql({b: 2})
    end
    it 'deletes keys in sub hashes' do
      h = {a: 1, b: {c: 3, d: 4}}
      recursive_delete!(h, [:c])
      expect(h).to eql({a: 1, b: {d: 4}})
    end
    it 'deletes keys in hashes inside arrays' do
      h = {a: [{b: 1, c: 2}, {b: 3, c: 4}]}
      recursive_delete!(h, [:b])
      expect(h).to eql({a: [{c: 2}, {c: 4}]})
    end
  end

  describe '#tree_compare' do

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

    example 'can ensure values are absent with :-',
            tree:   {a: 1},
            mask:   {a: :-},
            result: [{path: 'a', tree: 1, mask: :__absent__}]

    example 'can check for any value being present with :+',
            tree:   {a: 1, b: [1, 2, 3]},
            mask:   {a: :+, b: [1, :+, 3]},
            result: []

    context 'when comparing arrays' do
      example 'handles the tree being shorter',
              tree:   {a: [1]},
              mask:   {a: [1, 2]},
              result: [{path: 'a/1', tree: :__missing__, mask: [2]}]

      example 'handles the mask being shorter',
              tree:   {a: [1, 2]},
              mask:   {a: [1]},
              result: [{path: 'a/1', tree: [2], mask: :__absent__}]

      example 'can allow arbitrary tails with :*',
              tree:   {a: [1, 2, 3], b: [1], c: [2]},
              mask:   {a: [1, :*], b: [1, :*], c: [1, :*]},
              result: [{path: 'c/0', tree: 2, mask: 1}]
    end

    context 'handles mismatched types' do
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
    end
  end
end