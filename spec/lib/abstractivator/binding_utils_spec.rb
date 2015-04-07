require 'rspec'
require 'abstractivator/binding_utils'

describe Abstractivator::BindingUtils do
  describe '::frame_args' do

    def foo(a, b)
      @foo_args = Abstractivator::BindingUtils.frame_args
      bar(a * 10, b * 100)
    end

    def bar(c, d)
      @bar_args = Abstractivator::BindingUtils.frame_args
      @foo_args_from_bar = Abstractivator::BindingUtils.frame_args(1)
    end

    it 'returns the arguments of the method at the specified frame depth' do
      foo(1, 2)
      expect(@foo_args).to eql [[:a, 1], [:b, 2]]
      expect(@bar_args).to eql [[:c, 10], [:d, 200]]
      expect(@foo_args_from_bar).to eql [[:a, 1], [:b, 2]]
    end
  end
end
