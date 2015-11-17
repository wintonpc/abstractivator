require 'abstractivator/enumerable_ext'
require 'abstractivator/array_ext'

module MethodAndProcExtensions
  # returns a version of the procedure that accepts any number of arguments
  def loosen_args
    proc do |*args, **kws, &block|
      Proc.loose_call(self, args, kws, &block)
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

  # composes procedures in reverse order.
  # useful for applying a series of transformations.
  # pipe(f, g, h) returns the procedure
  # proc { |x| h.call(g.call(f.call(x))) }
  def self.pipe(*procs)
    Proc.compose(*procs.reverse)
  end

  # makes a pipeline transform as with Proc::pipe
  # and applies it to the given value.
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

  # tries to coerce x into a procedure, then calls it with
  # the given argument list.
  # If x cannot be coerced into a procedure, returns x.
  def self.loose_call(x, args, kws={}, &block)
    x = x.to_proc if x.respond_to?(:to_proc)
    x.callable? or return x
    arg_types = x.parameters.map(&:first)
    # customize args
    req_arity = arg_types.select{|x| x == :req}.size
    total_arity = req_arity + arg_types.select{|x| x == :opt}.size
    accepts_arg_splat = arg_types.include?(:rest)
    unless accepts_arg_splat
      args = args.take(total_arity).pad_right(req_arity)
    end
    # customize keywords
    accepts_kw_splat = arg_types.include?(:keyrest)
    unless accepts_kw_splat
      opt_key_names = x.parameters.select{|(type, name)| type == :key && !name.nil?}.map(&:value)
      req_key_names = x.parameters.select{|(type, name)| type == :keyreq && !name.nil?}.map(&:value)
      all_key_names = opt_key_names + req_key_names
      padding = req_key_names.hash_map{nil}
      kws = padding.merge(kws.select{|k| all_key_names.include?(k)})
    end
    if kws.any?
      x.call(*args, **kws, &block)
    else
      x.call(*args, &block)
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
  def callable?
    respond_to?(:call)
  end
end
