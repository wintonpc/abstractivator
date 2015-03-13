require 'rspec'
require 'abstractivator/enum'

class Container
  module Traditional
    include Enum
    FOO = 'foo'
    BAR = 'bar'
  end

  define_enum(:Fruits, :apple, :orange)
  define_enum(:Vegetables, cucumber: 'Cucumis sativus', eggplant: 8)
end

describe Enum do
  describe '::values' do
    it 'enumerates the values' do
      expect(Container::Traditional.values).to eql %w(foo bar)
    end
  end
  describe '::name_for' do
    it 'returns the symbol name of an enum value' do
      expect(Container::Traditional.name_for('foo')).to eql :FOO
    end
    it 'return nil if the value does not belong to the enumeration' do
      expect(Container::Traditional.name_for('baz')).to be_nil
    end
  end
  describe '::from_symbol' do
    it 'coerces a symbol to an enum value' do
      expect(Container::Traditional.from_symbol(:bar)).to eql 'bar'
    end
    it 'raises an error if no such value exists in the enumeration' do
      expect{Container::Traditional.from_symbol(:baz)}.to raise_error
    end
  end
  describe '::from' do
    it 'returns the typed version of the value' do
      x = 'apple'
      expect(x.enum_type).to be_nil
      result = Container::Fruits.from(x)
      expect(result.enum_type).to eql Container::Fruits
    end
  end
end

describe '#define_enum' do
  it 'defines an enum given an array of symbols' do
    expect(Container::Fruits::APPLE).to eql 'apple'
    expect(Container::Fruits::ORANGE).to eql 'orange'
  end
  it 'defines an enum given a hash' do
    expect(Container::Vegetables::CUCUMBER).to eql 'Cucumis sativus'
    expect(Container::Vegetables::EGGPLANT).to eql 8
  end
  it 'values know their parent' do
    expect(Container::Fruits::APPLE.enum_type).to eql Container::Fruits
    expect(Container::Fruits::ORANGE.enum_type).to eql Container::Fruits
    expect(Container::Vegetables::CUCUMBER.enum_type).to eql Container::Vegetables
    expect(Container::Vegetables::EGGPLANT.enum_type).to eql Container::Vegetables
  end
  it 'raises an error when called with bad arguments' do
    expect{define_enum(:Stuff, 5)}.to raise_error /Arguments must be/
    expect{define_enum(:Stuff, '!@$' => '')}.to raise_error /Arguments must be/
  end
end
