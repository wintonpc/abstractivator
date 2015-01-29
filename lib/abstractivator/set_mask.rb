module Abstractivator
  class SetMask
    def initialize(mask, key_func)
      @key_func = key_func
      @mask = Hash[mask.map { |item| [get_key(item), item] }] #TODO: replace with hash_map when available
    end

    def first
      @mask.first.last
    end

    def any?
      @mask.any?
    end

    def to_set
      Set.new(@mask.values)
    end

    def get_key(item)
      @key_func.call(item)
    end

    def [](key)
      @mask[key]
    end

    def drop(key)
      SetMask.new(@mask.reject { |k, _| k == key }.values, @key_func)
    end
  end
end
