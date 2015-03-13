require 'active_support/inflector'
require 'abstractivator/enumerable_ext'
require 'delegate'

module Enum
  def self.included(base)
    base.extend ClassMethods
    # base.extend Dsl
  end

  module ClassMethods
    def values
      self.constants.map{|sym| self.const_get(sym)}.reject{|x| x == Enum::ClassMethods}
    end

    def name_for(value)
      self.constants.detect{|sym| self.const_get(sym) == value}
    end

    def from_symbol(sym)
      safe_constantize("#{self.name}::#{sym.to_s.upcase}")
    end

    def from(x)
      values.find{|v| v == x}
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

module EnumMember
  attr_accessor :enum_type
end

class Object
  include EnumMember
end

class WrappedEnumValue < SimpleDelegator
  include EnumMember
  attr_reader :class # pure evil
  def initialize(value)
    __setobj__(value)
    @class = value.class
  end
end

def define_enum(name, *fields)
  const_set(name, make_enum(*fields))
end

def make_enum(*fields)
  if fields.size == 1 && fields.first.is_a?(Hash) && fields.first.keys.all?{|f| f.is_a?(Symbol)}
    fields = fields.first
    Module.new do
      include Enum
      fields.each_pair do |k, v|
        val = v.frozen? ? WrappedEnumValue.new(v) : v
        val.enum_type = self
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
