require 'rspec'
require 'abstractivator/args_of'

describe Kernel do
  describe '#args_of' do

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
  end
end

describe Abstractivator::ArgsOf do
  describe '::test_args' do
    it 'does not raise an error when there are no argument errors' do
      expect{test([Numeric], [3.14])}.to_not raise_error
    end
    context 'constraints can be' do
      it 'types' do
        expect_error([String], [8], 'Expected String but got Fixnum (8)')
        expect_error([Integer], [3.14], 'Expected Integer but got Float (3.14)')
      end
    end
  end

  def expect_error(patterns, args, message)
    result = test(patterns, args)
    expect(result).to be_an ArgumentError
    expect(result.message).to eql message
  end

  def test(patterns, args)
    Abstractivator::ArgsOf.test_args(patterns, args)
  end
end
