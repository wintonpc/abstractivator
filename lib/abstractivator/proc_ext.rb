require 'abstractivator/enumerable_ext'

module MethodAndProcExtensions
  # returns a version of the procedure that accepts any number of arguments
  def loosen_args
    proc do |*args, &block|
      Proc.loose_call(self, args, &block)
    end
  end
end

class Proc
  include MethodAndProcExtensions

  # composes this procedure with another procedure
  # f.compose(g) ==> proc { |x| f.call(g.call(x)) }
  def compose(other)
    proc{|x| self.call(other.call(x))}
  end

  # composes procedures.
  # compose(f, g, h) returns the procedure
  # proc { |x| f.call(g.call(h.call(x))) }
  def self.compose(*procs)
    procs.map(&:to_proc).inject_right(identity) { |inner, p| p.compose(inner) }
  end

  # returns the identity function
  def self.identity
    proc {|x| x}
  end

  # returns a version of the procedure with the argument list reversed
  def reverse_args
    proc do |*args, &block|
      self.call(*args.reverse, &block)
    end
  end

  # tries to coerce x into a procedure, then calls it with
  # the given argument list.
  # If x cannot be coerced into a procedure, returns x.
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
  # returns a version of the procedure that takes the receiver
  # (that would otherwise need to be bound with .bind()) as
  # the first argument
  def explicit_receiver
    proc do |receiver, *args, &block|
      self.bind(receiver).call(*args, &block)
    end
  end
end

class Array
  # A syntactic hack to get hash values.
  # xs.map(&:name)      works when xs is an array of objects, each with a #name method. (built into ruby)
  # xs.map(&[:name])    works when xs is an array of hashes, each with a :name key.
  # xs.map(&['name'])   works when xs is an array of hashes, each with a 'name' key.
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
