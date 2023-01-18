# frozen_string_literal: true

class Hash
  class << self
    # Returns a hash that automatically adds nested hashes out to the given depth when a key is missing, and
    # calls the given proc to make leaf level items when an item isn't found.
    # @param [Integer] depth How deep in the leaves are.  1 means the values returned hash are leaves. 2
    # means this hash contains hashes, which in turn contain leaves.
    # @param [Proc] make_item Called with the key to make leaf values, when a key is missing.
    def with_default(depth=1, &make_item)
      Hash.new do |h, k|
        if depth == 1
          h[k] = make_item.(k)
        else
          h[k] = Hash.with_default(depth - 1, &make_item)
        end
      end
    end

    def deep_flatten(hash)
      result = {}
      f = lambda do |x, path|
        if x.is_a?(Hash)
          x.each_pair { |k, v| f.(v, [*path, k]) }
        elsif x.is_a?(Enumerable)
          x.each_with_index { |v, i| f.(v, [*path, i]) }
        else
          result[path.join(".")] = x
        end
      end
      f.(hash, [])
      result
    end
  end

  # Returns a new hash with the same leaf values, where each key is the string path to the leaf, joined by periods.
  # Example: {a: 1, b: [2, {c: 3}]}.deep_flatten returns {"a" => 1, "b.0" => 2, "b.1.c" => 3}
  def deep_flatten
    Hash.deep_flatten(self)
  end

  # Fetches the value for key. If there is no value for key, the block is invoked and the return value associated
  # with the key and then returned; if there is no block, the default value is associated and returned.
  # @param key [Object]
  # @param default [Object]
  # @yieldparam k [Object] the unassociated key
  # @yieldreturn [Object] the value to associate with the key
  def get_or_add(key, default=nil)
    fetch(key) { |k| store(k, block_given? ? yield(k) : default) }
  end
end
