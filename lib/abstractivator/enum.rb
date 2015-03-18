require 'active_support/inflector'
require 'abstractivator/enumerable_ext'
require 'delegate'

module Enum

  attr_reader :value

  def initialize(value)
    @value = value
  end

  def inspect
    "#<#{self.class.name} #{value.inspect}>"
  end
  alias_method :to_s, :inspect

  def as_json(_opts={})
    value.as_json
  end

  def to_json
    value.to_json
  end

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def values
      constants.map{|sym| const_get(sym)}.reject{|x| x == Enum::ClassMethods}
    end

    def name_for(value)
      constants.detect{|sym| const_get(sym) == value}
    end

    def from_symbol(sym)
      safe_constantize("#{name}::#{sym.to_s.upcase}")
    end

    def from(x)
      if x.is_a?(Enum)
        x
      else
        values.find{|v| v.value == x}
      end
    end

    private

    def safe_constantize(str)
      begin
        str.constantize
      rescue NameError
        fail "'#{str}' has not been defined as a constant"
      end
    end
  end
end

def define_enum(name, *fields)
  if respond_to?(:const_set)
    const_set(name, make_enum(*fields))
  else # top-level
    Object.send(:const_set, name, make_enum(*fields))
  end
end

def make_enum(*fields)
  if fields.size == 1 && fields.first.is_a?(Hash) && fields.first.keys.all?{|f| f.is_a?(Symbol)}
    fields = fields.first
    Class.new do
      include Enum
      private_class_method :new
      fields.each_pair do |k, v|
        val = new(v)
        fld = k.to_s.upcase.to_sym
        const_set(fld, val)
      end
    end
  elsif fields.all?{|f| f.is_a?(Symbol)}
    make_enum(fields.hash_map(&:to_s))
  else
    raise 'Arguments must be one or more symbols or a single symbol-keyed hash'
  end
end
