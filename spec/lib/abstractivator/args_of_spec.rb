require 'rspec'
require 'abstractivator/args_of'

describe 'Kernel#args_of' do

  def foo(a, b)
    args_of String, Integer
    "#{a} #{b}"
  end

  it 'allows valid arguments' do
    expect(foo('magic', 8)).to eql 'magic 8'
  end

  it 'raises an error on invalid arguments' do
    expect{foo('magic', '8')}.to raise_error ArgumentError, 'Expected Integer but got String (8)'
  end

  context 'constraints can be' do
    it 'types' do
      expect{test_args([String], [8])}.to raise_error ArgumentError, 'Expected String but got Fixnum (8)'
    end
  end
end
