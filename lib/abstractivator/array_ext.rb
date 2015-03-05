class Array
  def key
    size == 2 or raise 'array must contain exactly two elements'
    first
  end

  def value
    size == 2 or raise 'array must contain exactly two elements'
    last
  end

  unless instance_methods.include?(:to_h)
    define_method(:to_h) do
      Hash[self]
    end
  end
end
