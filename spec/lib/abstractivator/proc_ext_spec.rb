require 'abstractivator/proc_ext'

context 'in the world of functional programming' do
  let!(:double) { proc{|x| x * 2} }
  let!(:square) { proc{|x| x ** 2} }
  let!(:negate) { proc{|x| -x} }

  describe 'Proc#compose' do
    it 'composes procs' do
      expect(double.compose(square).call(3)).to eql 18
      expect(square.compose(double).call(3)).to eql 36
    end
  end

  describe 'Proc::compose' do
    it 'composes procs' do
      expect(Proc.compose.call(3)).to eql 3
      expect(Proc.compose(double).call(3)).to eql 6
      expect(Proc.compose(square, double).call(3)).to eql 36
      expect(Proc.compose(negate, square, double).call(3)).to eql -36
    end
  end

  describe 'Proc#reverse_args' do
    it 'reverse argument order' do
      divide = proc {|a, b| a / b}
      expect(divide.reverse_args.call(4.0, 1.0)).to eql 0.25
    end
  end

  describe 'Proc::loose_call' do
    it 'returns the first argument if it is not a proc' do
      expect(Proc.loose_call(:a, [:b, :c])).to eql :a
    end
    it 'calls the proc with an appropriate number of arguments' do
      events = []
      args = [:here, :are, :some, :arguments]
      Proc.loose_call(->{events << 0}, args)
      Proc.loose_call(->(a){events << 1}, args)
      Proc.loose_call(->(a, b){events << 2}, args)
      Proc.loose_call(->(a, b, c){events << 3}, args)
      expect(events).to eql [0, 1, 2, 3]
    end
    it 'pads with nils' do
      expect(Proc.loose_call(->(a, b) {[a, b]}, [1])).to eql [1, nil]
    end
  end

  describe 'Proc#loosen_args' do
    it 'returns a procedure with loose arity semantics' do
      p = ->(a, b, c) { [a, b, c] }
      lp = p.loosen_args
      expect(lp.call(1, 2)).to eql [1, 2, nil]
    end
  end
end

describe 'UnboundMethod#explicit_receiver' do
  it 'returns a proc that takes an explicit self to bind to as the first argument' do
    m = Array.instance_method(:<<)
    a = []
    m.explicit_receiver.call(a, 42)
    expect(a).to eql [42]
  end
end

describe 'Array#to_proc' do
  it 'makes a hash-accessor proc' do
    expect([{a: 1, b: 2}, {a: 3, b: 3}].map(&[:a])).to eql [1, 3]
    expect([{'a' => 1, 'b' => 2}, {'a' => 3, 'b' => 3}].map(&['a'])).to eql [1, 3]
  end
  it 'raises an error if you use it wrong' do
    expect{[].to_proc}.to raise_error 'size must be exactly one'
    expect{[:a, :b].to_proc}.to raise_error 'size must be exactly one'
  end
end
