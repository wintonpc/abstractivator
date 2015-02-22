require 'active_support/inflector'

module Enum
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def values
      self.constants.map{|sym| self.const_get(sym)}
    end

    def name_for(value)
      self.constants.detect{|sym| self.const_get(sym) == value}
    end

    def from_symbol(sym)
      safe_constantize("#{self.name}::#{sym.to_s.upcase}")
    end

    def safe_constantize(str)
      begin
        str.constantize
      rescue NameError
        fail "'#{str}' has not been defined as a constant"
      end
    end
  end
end
