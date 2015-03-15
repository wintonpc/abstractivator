require 'abstractivator/enumerable_ext'

module MethodAndProcExtensions
  def loosen_args
    proc do |*args, &block|
      Proc.loose_call(self, args, &block)
    end
  end
end

class Proc
  include MethodAndProcExtensions

  def compose(other)
    proc{|x| self.call(other.call(x))}
  end

  def self.compose(*procs)
    procs.map(&:to_proc).inject_right(identity) { |inner, p| p.compose(inner) }
  end

  def self.identity
    proc {|x| x}
  end

  def reverse_args
    proc do |*args, &block|
      self.call(*args.reverse, &block)
    end
  end

  def self.loose_call(x, args, &block)
    x = x.to_proc if x.respond_to?(:to_proc)
    x.callable? or return x
    args = args.take(x.arity).pad_right(x.arity) if x.arity >= 0
    x.call(*args, &block)
  end
end

class Method
  include MethodAndProcExtensions
end

class UnboundMethod
  def explicit_receiver
    proc do |receiver, *args, &block|
      self.bind(receiver).call(*args, &block)
    end
  end
end

class Array
  def to_proc
    raise 'size must be exactly one' unless size == 1
    proc{|x| x[first]}
  end
end

class Object
  def callable?
    respond_to?(:call)
  end
end
