require 'rspec'
require 'abstractivator/collections'

describe Abstractivator::Collections do

  include Abstractivator::Collections

  describe '#multizip' do
    it 'transposes' do
      xs = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
      expect(multizip(xs)).to eql [[1, 4, 7], [2, 5, 8], [3, 6, 9]]
      expect(multizip([])).to eql []
    end
    it 'uses a default value past the end of shorter enumerables' do
      xs = [[1, 2, 3], [4], [7, 8, 9]]
      expect(multizip(xs)).to eql [[1, 4, 7], [2, nil, 8], [3, nil, 9]]
      expect(multizip(xs, -1)).to eql [[1, 4, 7], [2, -1, 8], [3, -1, 9]]
    end
  end
end