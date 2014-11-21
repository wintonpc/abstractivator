require 'rspec'
require 'abstractivator/cons'

describe Abstractivator::Cons do

  include Abstractivator::Cons

  describe '#empty_list' do
    it 'is a singleton' do
      expect(empty_list).to eql empty_list
    end
  end

  describe '#cons' do
    it 'creates a cons cell' do
      expect(cons(1, 2)).to eql [1,2 ]
    end
  end

  describe '#head' do
    it 'returns the head' do
      cell = cons(1, 2)
      expect(head(cell)).to eql 1
    end
  end

  describe '#tail' do
    it 'returns the tail' do
      cell = cons(1, 2)
      expect(tail(cell)).to eql 2
    end
  end

  describe '#enum_to_list' do
    it 'returns the list form of an enumerable' do
      expect(enum_to_list([])).to eql empty_list
      expect(enum_to_list([1,2,3])).to eql [1, [2, [3, empty_list]]]
    end
  end

  describe '#list_to_enum' do
    it 'returns the enumerable form of a list' do
      expect(list_to_enum(empty_list).to_a).to eql []
      expect(list_to_enum(cons(1, cons(2, cons(3, empty_list)))).to_a).to eql [1, 2, 3]
    end
  end

end