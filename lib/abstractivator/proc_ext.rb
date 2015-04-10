require 'abstractivator/enumerable_ext'

module MethodAndProcExtensions
  # returns a version of the procedure with loose call semantics.
  # @see Proc::loose_call
  def loosen_args
    Proc.loosen_args(self)
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

  # composes procedures in reverse order.
  # useful for applying a series of transformations.
  # pipe(f, g, h) returns the procedure
  # proc { |x| h.call(g.call(f.call(x))) }
  def self.pipe(*procs)
    Proc.compose(*procs.reverse)
  end

  # makes a pipeline transform and applies it to the given value.
  # @see Proc::pipe
  def self.pipe_value(value, *procs)
    Proc.pipe(*procs).call(value)
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

  # Tries to coerce x into a procedure with to_proc, then calls it with
  # the given argument list. If x cannot be coerced into a procedure,
  # returns x.
  #
  # If more arguments are provided than the procedure accepts, the argument
  # list is truncated before calling the proc. If fewer arguments are provided
  # than the procedure accepts, the argument list is padded with nils before
  # calling the proc.
  #
  # If the procedure takes a splatted parameter, e.g., *args, then arg list
  # is neither truncated nor padded.
  #
  # If the procedure has optional arguments, the argument list is padded
  # just enough to satisfy the number of required parameters. Nils are
  # not passed for optional arguments. This prevents the default values
  # from being overridden with nil.
  def self.loose_call(x, args, &block)
    x = x.to_proc if x.respond_to?(:to_proc)
    x.callable? or return x
    args = args.take(x.parameters.size).pad_right(x.arity) if x.arity >= 0
    x.call(*args, &block)
  end

  # returns a version of the procedure/object with loose call semantics.
  # @param x [Object] a Proc or something that can be coerced into a Proc
  # @see Proc::loose_call
  def self.loosen_args(x)
    proc do |*args, &block|
      Proc.loose_call(x, args, &block)
    end
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
  # true if the object responds to 'call'; otherwise false.
  def callable?
    respond_to?(:call)
  end
end
