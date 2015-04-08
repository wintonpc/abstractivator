require 'abstractivator/enumerable_ext'

describe Enumerable do
  let!(:x) {[
      { a: 5, b: 6, c: 'asdf' },
      { a: 8, b: 5, c: 'ffffsfsf' },
      { a: 3, b: 2, c: 'rwrwrwr' }
  ]}

  let!(:y) {[
      { a: 9, b: 10, c: 'aaaaaarghj' },
      { a: 3, b: 2, c: 'ggggggg' },
      { a: 5, b: 6, c: 'rrrrrrrrrr' }
  ]}
  let!(:get_key) { ->(z) { [z[:a], z[:b]] } }

  describe '::inner_join' do
    it 'returns only the matched values' do
      result = Enumerable.inner_join(x, y, get_key, get_key)
      expect(result.size).to eql 2
      expect(result).to include([{ a: 5, b: 6, c: 'asdf' }, { a: 5, b: 6, c: 'rrrrrrrrrr' }])
      expect(result).to include([{ a: 3, b: 2, c: 'rwrwrwr' }, { a: 3, b: 2, c: 'ggggggg' }])
    end
  end

  describe '::outer_join' do
    it 'matches up elements by key' do
      result = Enumerable.outer_join(x, y, get_key, get_key, -1, -100)
      expect(result).to include([{ a: 5, b: 6, c: 'asdf' }, { a: 5, b: 6, c: 'rrrrrrrrrr' }])
      expect(result).to include([{ a: 3, b: 2, c: 'rwrwrwr' }, { a: 3, b: 2, c: 'ggggggg' }])
    end

    it 'matches a left value up with the right default when the right is missing' do
      result = Enumerable.outer_join(x, y, get_key, get_key, -1, -100)
      expect(result).to include([{ a: 8, b: 5, c: 'ffffsfsf' }, -100])
    end

    it 'matches a right value up with the left default when the left is missing' do
      result = Enumerable.outer_join(x, y, get_key, get_key, -1, -100)
      expect(result).to include([-1, { a: 9, b: 10, c: 'aaaaaarghj' }])
    end

    it 'invokes default value procs' do
      result = Enumerable.outer_join(x, y, get_key, get_key, ->(x){x[:c]}, ->(x){x[:c]})
      expect(result).to include([{ a: 8, b: 5, c: 'ffffsfsf' }, 'ffffsfsf'])
      expect(result).to include(['aaaaaarghj', { a: 9, b: 10, c: 'aaaaaarghj' }])
    end

    it 'returns the correct number of pairs' do
      result = Enumerable.outer_join(x, y, get_key, get_key, -1, -100)
      expect(result.size).to eql 4
    end

    it 'works when left is empty' do
      result = Enumerable.outer_join([], y, get_key, get_key, -1, -100)
      expect(result.size).to eql 3
    end

    it 'works when right is empty' do
      result = Enumerable.outer_join(x, [], get_key, get_key, -1, -100)
      expect(result.size).to eql 3
    end

    it 'works when both are empty' do
      result = Enumerable.outer_join([], [], get_key, get_key, -1, -100)
      expect(result.size).to eql 0
    end

    it 'throws an exception when left values have overlapping keys' do
      x.push({ a: 8, b: 5, c: 'oops' })
      expect { Enumerable.outer_join(x, y, get_key, get_key, -1, -100) }.to raise_error
    end

    it 'throws an exception when right values have overlapping keys' do
      y.push({ a: 5, b: 6, c: 'oops' })
      expect { Enumerable.outer_join(x, y, get_key, get_key, -1, -100) }.to raise_error
    end
  end

  describe '#uniq?' do
    it 'returns true if the items are unique' do
      expect([1,2,3].uniq?).to be true
    end
    it 'returns false if the items are unique' do
      expect([1,2,2].uniq?).to be false
    end
    it 'accepts a block' do
      expect([[1, 99], [2, 99]].uniq?(&:first)).to be true
      expect([[1, 99], [2, 99]].uniq?(&:last)).to be false
    end
  end

  describe '#detect' do
    let!(:xs) { [Array, Hash] }
    it 'falls back to the default behavior' do
      expect(xs.detect{|x| x.name == 'Hash'}).to eql Hash
    end
    it 'falls back to the default behavior' do
      expect(xs.detect(proc{'123'}){|x| x.name == 'Object'}).to eql '123'
    end
    context 'with attr_name and value' do
      it 'returns the matching element' do
        expect(xs.detect(:name, 'Hash')).to eql Hash
      end
      it 'returns nil if not found' do
        expect([].detect(:name, 'Hash')).to be_nil
      end
    end
    context 'with value and block' do
      it 'returns the matching element' do
        expect(xs.detect('Hash', &:name)).to eql Hash
      end
      it 'returns the matching element' do
        expect([].detect('Hash', &:name)).to be_nil
      end
    end
  end

  describe '#inject_right' do
    it 'injects, starting at the right' do
      expect([1, 2, 3].inject_right([]){|acc, x| acc << x}).to eql [3, 2, 1]
    end
  end

  describe '#pad_right' do
    it 'pads values at the end' do
      a = [1, 2]
      expect(a.pad_right(4, :x)).to eql [1, 2, :x, :x]
      expect(a.pad_right(2, :x)).to eql [1, 2]
      expect(a.pad_right(1, :x)).to eql [1, 2]
      expect(a.pad_right(-1, :x)).to eql [1, 2]
    end
    it 'does not mutate the receiver' do
      a = [1, 2]
      a.pad_right(4, :x)
      expect(a).to eql [1, 2]
    end
    it 'accepts a block to create values' do
      n = 0
      result = [:x].pad_right(4) { n += 1 }
      expect(result).to eql [:x, 1, 2, 3]
    end
  end

  describe '#hash_map' do
    let!(:xs) { [Object, Hash, Array] }
    it 'turns an array into a map' do
      result = xs.hash_map(proc{|x| x.to_s[0]}) {|x| x.to_s }
      expect(result).to eql({ 'O' => 'Object', 'H' => 'Hash', 'A' => 'Array' })
    end
    it 'the value transformer can be omitted' do
      result = xs.hash_map(proc{|x| x.to_s[0]})
      expect(result).to eql({ 'O' => Object, 'H' => Hash, 'A' => Array })
    end
    it 'the key transformer can be omitted' do
      result = xs.hash_map(&:to_s)
      expect(result).to eql({ Object => 'Object', Hash => 'Hash', Array => 'Array' })
    end
    it 'the key transformer is called loosely' do
      result = xs.hash_map(:to_s)
      expect(result).to eql({ 'Object' => Object, 'Hash' => Hash, 'Array' => Array })
    end
  end

  describe '#deep_map' do
    it 'maps nested arrays' do
      mapped = [1,[2,3],4].deep_map{|x| x*2}
      expect(mapped).to eql [2,[4,6],8]
    end
    it 'maps hashes' do
      mapped = [{a: 1, b: [2, 3]}].deep_map{|x| x*2}
      expect(mapped).to eql [{a: 2, b: [4, 6]}]
    end
  end
end
