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
    it 'coerces the args to a proc with to_proc' do
      p = Proc.compose(:abs, :first)
      expect(p.call([-5, 6])).to eql 5
    end
  end

  describe 'Proc::pipe' do
    it 'composes procs in reverse order' do
      expect(Proc.pipe.call(3)).to eql 3
      expect(Proc.pipe(double).call(3)).to eql 6
      expect(Proc.pipe(double, square).call(3)).to eql 36
      expect(Proc.pipe(double, square, negate).call(3)).to eql -36
    end
    it 'coerces the args to a proc with to_proc' do
      p = Proc.pipe(:first, :abs)
      expect(p.call([-5, 6])).to eql 5
    end
  end

  describe 'Proc::pipe_value' do
    it 'makes a Proc::pipe pipeline and applies it to a value' do
      expect(Proc.pipe_value(3, double, square, negate)).to eql -36
    end
  end

  describe 'Proc#reverse_args' do
    it 'reverse argument order' do
      divide = proc {|a, b| a / b}
      expect(divide.reverse_args.call(4.0, 1.0)).to eql 0.25
    end
  end

  shared_examples 'an arity loosener' do
    it 'calls the proc with an appropriate number of arguments' do
      events = []
      args = [:here, :are, :some, :arguments]
      do_call(->{events << 0}, args)
      do_call(->(a){events << 1}, args)
      do_call(->(a, b){events << 2}, args)
      do_call(->(a, b, c){events << 3}, args)
      expect(events).to eql [0, 1, 2, 3]  # lambdas are strict in arity,
      # so if their bodies executed, then we know
      # they were called with the correct number of arguments

    end
    it 'pads with nils' do
      verify_called_with ->(a, b) {[a, b]},
                         [1],
                         [1, nil]
    end
    it 'passes optional arguments, while preserving defaults' do
      verify_called_with ->(a, b=2, c=3) {[a, b, c]},
                         [11, 22],
                         [11, 22, 3]
    end
    it 'works with variable-arity procs' do
      verify_called_with ->(*args) {args},
                         [1, 2],
                         [1, 2]
      verify_called_with ->(first, *rest) {[first, rest]},
                         [1, 2, 3],
                         [1, [2, 3]]
    end
    it 'passes the block' do
      expect(do_call(proc{|&b| b.call}, []) {42}).to eql 42
    end
    it 'calls the proc with the declared keyword arguments, while preserving defaults' do
      verify_called_with_keywords ->(a: 1, b: 2, c: 3) {[a, b, c]},
                                  {a: 11, b: 22, d: 44},
                                  [11, 22, 3]
    end
    it 'calls the proc with the declared required keyword arguments' do
      verify_called_with_keywords ->(a:, b:) {[a, b]},
                                  {a: 1, b: 2, c: 3},
                                  [1, 2]
    end
    it 'replaces missing required keyword arguments with nil' do
      verify_called_with_keywords ->(a:, b:) {[a, b]},
                                  {a: 1},
                                  [1, nil]
    end
    it 'works with variable-keyword procs' do
      verify_called_with_keywords ->(**kws) {kws},
                                  {a: 1, b: 2, c: 3},
                                  {a: 1, b: 2, c: 3}
      verify_called_with_keywords ->(a:, **kws) {[a, kws]},
                                  {a: 1, b: 2, c: 3},
                                  [1, {b: 2, c: 3}]
    end
    it 'works with a mixture of argument types' do
      p = ->(a, b=2, c=3, d: 4, e: 5, f:, &block){[a, b, c, d, e, f, block.call]}
      result = do_call(p, [11, 22], {d: 44, z: 5}) { 42 }
      expect(result).to eql [11, 22, 3, 44, 5, nil, 42]
    end
    it 'works with a mixture of splat types' do
      p = ->(*args, **kws, &block){[args, kws, block.call]}
      result = do_call(p, [1, 2], {c: 3, d: 4}) { 42 }
      expect(result).to eql [[1, 2], {c: 3, d: 4}, 42]
    end

    def verify_called_with(p, input_args, output)
      expect(do_call(p, input_args, {})).to eql output
    end

    def verify_called_with_keywords(p, input_kws, output)
      expect(do_call(p, [], input_kws)).to eql output
    end
  end

  describe 'Proc::loose_call' do
    it_behaves_like 'an arity loosener'

    it 'returns the first argument if it is not a proc' do
      expect(Proc.loose_call('a', ['b', 'c'])).to eql 'a'
    end
    it 'attempts to convert the first argument to proc' do
      expect(Proc.loose_call(:to_s, ['5'])).to eql '5'
    end

    def do_call(p, args, kws={}, &block)
      Proc.loose_call(p, args, kws, &block)
    end
  end

  describe 'Proc#loosen_args' do
    it_behaves_like 'an arity loosener'

    def do_call(p, args, kws={}, &block)
      p.loosen_args.call(*args, **kws, &block)
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

describe 'Object#callable?' do
  it 'determines whether or not the object has a public :call method' do
    expect(1.callable?).to be_falsey
    expect(proc{}).to be_truthy
    expect(double(call: 1)).to be_truthy
  end
end
