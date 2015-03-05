require 'rspec'
require 'abstractivator/array_ext'

describe Array do
  describe '#key' do
    it 'returns the first element' do
      expect([:k, :v].key).to eql :k
    end
    it 'raises an error if the array is not of size 2' do
      expect{[:k].key}.to raise_error
      expect{[:k, :v, :z].key}.to raise_error
    end
  end

  describe '#value' do
    it 'returns the second element' do
      expect([:k, :v].value).to eql :v
    end
    it 'raises an error if the array is not of size 2' do
      expect{[:k].value}.to raise_error
      expect{[:k, :v, :z].value}.to raise_error
    end
  end

  describe '#to_h' do
    it 'makes a hash out of an array of pairs' do
      expect([[:a, 1], [:b, 2]].to_h).to eql({a: 1, b: 2})
    end
  end
end
