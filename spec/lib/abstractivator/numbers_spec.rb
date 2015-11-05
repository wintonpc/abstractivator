require 'rspec'
require 'abstractivator/numbers'

describe Numbers do
  describe '::from' do
    it 'returns a stream of numbers starting at the given number' do
      expect(Numbers.from(1).take(3)).to eql [1,2,3]
    end
    it 'accepts an interval' do
      expect(Numbers.from(0, 5).take(3)).to eql [0,5,10]
      expect(Numbers.from(3, -1).take(3)).to eql [3,2,1]
    end
  end
end
