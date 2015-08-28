require 'rspec'
require 'enumerable_ext'

describe Enumerable do
  describe '#stable_sort' do
    it 'sorts stably' do
      xs = [-2, 2, 1, -1]
      result = xs.stable_sort{|a, b| a.abs <=> b.abs}
      expected_result = [1, -1, -2, 2]
      expect(result).to eql expected_result
    end

    it 'does not require a block' do
      expect([3, 2, 1].stable_sort).to eql [1, 2, 3]
    end
  end
end
