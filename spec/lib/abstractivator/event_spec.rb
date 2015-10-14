require 'rspec'
require 'abstractivator/event'

describe Abstractivator::Event do

  class EventedObject
    include Abstractivator::Event
    event :arrived, :departed
  end

  subject { EventedObject.new }

  describe 'the "do" method' do
    context 'when there are no hooks' do
      it 'does nothing' do
        subject.do_arrived
      end
    end
    it 'calls the hooks in the order in which they were added' do
      log = []
      subject.on_arrived { log << 'hello' }
      subject.on_arrived { log << 'hello again'}
      expect(log).to eql []
      subject.do_arrived
      expect(log).to eql ['hello', 'hello again']
    end
    it 'passes arguments to the hooks' do
      observed_args = nil
      subject.on_arrived { |*args| observed_args = args }
      subject.do_arrived(2, 3)
      expect(observed_args).to eql [2, 3]
    end
    it 'passes keyword arguments to the hooks' do
      observed_keywords = nil
      subject.on_arrived { |a: nil, b: nil| observed_keywords = [a, b] }
      subject.do_arrived(a: 2, b: 3)
      expect(observed_keywords).to eql [2, 3]
    end
    it 'passes the block to the hooks' do
      manifest = {1 => 'Bob', 2 => 'Fred'}
      greeting = nil
      subject.on_arrived { |id, &greet| greet.call(manifest[id]) }
      subject.do_arrived(1) { |name| greeting = "Hello, #{name}" }
      expect(greeting).to eql 'Hello, Bob'
    end
  end

  describe 'the "on" method' do
    it 'returns an unhook procedure' do
      log = []
      unhook = subject.on_arrived { log << 'hello' }
      subject.do_arrived
      expect(log).to eql %w(hello)

      unhook.call
      subject.do_arrived
      expect(log).to eql %w(hello)
    end
  end

  describe 'the unhook procedure' do
    it 'returns the initial hook procedure' do
      log = []
      unhook = subject.on_arrived { log << 'hello' }
      subject.do_arrived
      expect(log).to eql %w(hello)

      hook = unhook.call
      subject.on_arrived(&hook)
      subject.do_arrived
      expect(log).to eql %w(hello hello)
    end
    it 'returns nil if called more than once' do
      unhook = subject.on_arrived { log << 'hello' }
      expect(unhook.call).to be_a Proc
      expect(unhook.call).to be nil
    end
  end

  it 'hooks are independent' do
    arrived_list = []
    departed_list = []
    subject.on_arrived { |who| arrived_list << who }
    subject.on_departed { |who| departed_list << who }

    subject.do_arrived('Fred')
    expect(arrived_list).to eql %w(Fred)
    expect(departed_list).to eql []

    subject.do_departed('Bob')
    expect(arrived_list).to eql %w(Fred)
    expect(departed_list).to eql %w(Bob)

  end
end
