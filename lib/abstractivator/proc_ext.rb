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
    procs.inject_right(identity) { |inner, p| p.compose(inner) }
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
    x.respond_to?(:call) ? x.call(*args.take(x.arity).pad_right(x.arity), &block) : x
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
