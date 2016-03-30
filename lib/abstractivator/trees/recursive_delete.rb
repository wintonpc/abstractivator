require 'active_support/core_ext/object/deep_dup'
require 'abstractivator/trees/block_collector'
require 'delegate'
require 'set'

module Abstractivator
  module Trees
    # recursively deletes the specified keys
    def recursive_delete!(hash, keys)
      x = hash # hash is named 'hash' for documentation purposes but may be anything
      case x
        when Hash
          keys.each{|k| x.delete(k)}
          x.each_value{|v| recursive_delete!(v, keys)}
        when Array
          x.each{|v| recursive_delete!(v, keys)}
      end
      x
    end
  end
end
