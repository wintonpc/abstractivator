class Array
  # returns the first element of a 2-element array.
  # useful when dealing with hashes in array form.
  # e.g., pairs.map(&:key)
  def key
    size == 2 or raise 'array must contain exactly two elements'
    first
  end

  # returns the second element of a 2-element array.
  # useful when dealing with hashes in array form.
  # e.g., pairs.map(&:value)
  def value
    size == 2 or raise 'array must contain exactly two elements'
    last
  end

  # A backport of Array@to_h from Ruby 2.1
  unless instance_methods.include?(:to_h)
    define_method(:to_h) do
      Hash[self]
    end
  end
end
