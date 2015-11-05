require 'rspec'
require 'abstractivator/enumerator_ext'

describe 'Enumerator' do
  describe '::unfold' do
    it 'generates an enumerator based on state changes over time' do
      naturals = Enumerator.unfold(1) { |nxt| [nxt, nxt + 1] }
      expect(naturals.take(5)).to eql [1,2,3,4,5]
    end
    it 'stops when state becomes nil' do
      xs = [1,2,3]
      tails = Enumerator.unfold(xs) { |xs| xs.empty? ? [nil, nil] : [xs, xs.drop(1)] }
      expect(tails.to_a).to eql [[1,2,3],[2,3],[3]]
    end
    it 'returns an empty array if the initial state is nil' do
      expect(Enumerator.unfold(nil){}.to_a).to eql []
    end
    it 'raises an error if no block is provided' do
      expect{Enumerator.unfold(nil)}.to raise_error
    end
  end

  describe '#memoized' do
    it 'returns a memoized version of the enumerator' do
      work = []
      naturals = Enumerator.new do |y|
        i = 1
        loop do
          # puts "calculating #{i}"
          work << i
          y << i
          i += 1
        end
      end

      wrapped = naturals.memoized
      expect(wrapped.take(3)).to eql [1,2,3]
      expect(work).to eql [1,2,3]

      # reenumerating doesn't do additional work
      expect(wrapped.take(3)).to eql [1,2,3]
      expect(work).to eql [1,2,3]

      # enumerating more does the minimum amount of work
      expect(wrapped.take(5)).to eql [1,2,3,4,5]
      expect(work).to eql [1,2,3,4,5]

      # subsequent calls share the memo
      wrapped2 = naturals.memoized
      expect(wrapped2.take(5)).to eql [1,2,3,4,5]
      expect(work).to eql [1,2,3,4,5]

      # wrapped instances are independent
      a = naturals.memoized
      b = naturals.memoized
      expect(a.next).to eql 1
      expect(a.next).to eql 2
      expect(b.next).to eql 1
      expect(a.next).to eql 3
      expect(b.next).to eql 2

      # wrapped enumerator is unaffected
      expect(naturals.next).to eql 1
      expect(naturals.take(3)).to eql [1,2,3]
    end
  end
end
