require 'rspec'
require 'abstractivator/callable_class'

class Foo
  extend CallableClass
  attr_reader :v
  def initialize(v)
    @v = v
  end
end

describe CallableClass do
  it 'should provide a [] constructor' do
    f = Foo[5]
    expect(f).to be_a Foo
    expect(f.v).to eql 5
  end
end
