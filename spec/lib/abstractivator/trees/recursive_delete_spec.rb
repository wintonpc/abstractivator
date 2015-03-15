require 'rspec'
require 'abstractivator/trees/recursive_delete'
require 'json'
require 'rails'
require 'pp'

describe Abstractivator::Trees do

  include Abstractivator::Trees

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
end
