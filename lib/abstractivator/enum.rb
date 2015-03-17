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
      self.constants.map{|sym| self.const_get(sym)}.reject{|x| x.is_a?(Class) || x.is_a?(Module)}
    end

    def name_for(value)
      self.constants.detect{|sym| self.const_get(sym) == value}
    end

    def from_symbol(sym)
      safe_constantize("#{self.name}::#{sym.to_s.upcase}")
    end

    def from(x)
      values.find{|v| v.value == x}
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
    Module.new do
      include Enum
      value_class =
          const_set(:Value,
                    Class.new do
                      attr_reader :enum_type, :value
                      define_method(:initialize) do |enum_type, value|
                        @enum_type, @value = enum_type, value
                      end
                      define_method(:inspect) do
                        "#<#{self.class.name} #{value.inspect}>"
                      end
                      alias_method :to_s, :inspect
                    end)
      fields.each_pair do |k, v|
        val = value_class.new(self, v)
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
