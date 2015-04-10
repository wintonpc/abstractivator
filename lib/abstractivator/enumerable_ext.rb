require 'set'
require 'abstractivator/proc_ext'

module Enumerable

  # joins items from left with items from right based on their keys.
  # get_{left,right}_key are callables which, given an item, return the item's key.
  # the defaults are used to form a pair for items which have no match.
  # returns an array of pairs (a pair is a 2-element array), each of which contains
  # a left and a right item.
  # @param left [Array] the left array
  # @param right [Array] the right array
  # @param get_left_key [Proc] a procedure that, given a left item, returns its key
  # @param get_right_key [Proc] a procedure that, given a right item, returns its key
  # @param left_default [Proc, Object] an object called with loose call semantics
  #   (@see Proc::loose_call) to obtain the default left value for a given right value.
  #   It is passed the right value.
  # @param right_default [Proc, Object] an object called with loose call semantics
  #   (@see Proc::loose_call) to obtain the default right value for a given left value.
  #   It is passed the left value.
  def self.outer_join(left, right, get_left_key, get_right_key, left_default, right_default)
    ls = left.hash_map(get_left_key)
    rs = right.hash_map(get_right_key)

    left_default = Proc.loosen_args(left_default)
    right_default = Proc.loosen_args(right_default)

    raise 'duplicate left keys' if ls.size < left.size
    raise 'duplicate right keys' if rs.size < right.size

    result = []

    ls.each_pair do |k, l|
      r = rs[k]
      if r
        rs.delete(k)
      else
        r = right_default.call(l)
      end
      result.push [l, r]
    end

    rs.each_pair do |_, r|
      result.push [left_default.call(r), r]
    end

    result
  end

  def outer_join(right, get_left_key, get_right_key, default_value)
    Enumerable.outer_join(self, right, get_left_key, get_right_key, default_value, default_value)
  end

  # like outer_join, except unmatched items are excluded, rather than being
  # paired with a default value.
  def self.inner_join(left, right, get_left_key, get_right_key)
    sentinel = Object.new
    result = self.outer_join(left, right, get_left_key, get_right_key, sentinel, sentinel)
    result.reject { |pair| pair.first == sentinel || pair.last == sentinel }
  end

  def inner_join(right, get_left_key, get_right_key)
    Enumerable.inner_join(self, right, get_left_key, get_right_key)
  end

  # Creates a map from the enumerable.
  # @param get_key [Proc, Object] A proc (called with loose call semantics) used to obtain
  #   the key for the given item. Defaults to the identity function.
  # @param get_value [Block] A block that returns value for the given item. Defaults to
  #   the identity function.
  def hash_map(get_key=Proc.identity, &get_value)
    Hash[self.map{|x| [Proc.loose_call(get_key, [x]), get_value ? get_value.call(x) : x]}]
  end

  # True if the enuemration items are unique; otherwise false.
  def uniq?
    seen = Set.new
    each_with_index do |x, i|
      seen << (block_given? ? yield(x) : x)
      return false if seen.size < i + 1
    end
    true
  end

  # An extension to Enumerable#detect that offers two additional
  # calling styles to simplify typical use cases. See specs
  # for usage.
  orig_detect = instance_method(:detect)
  define_method :detect do |*args, &block|
    detect = orig_detect.bind(self)

    if args.size == 1 && !args.first.callable? && block
      value = args.first
      detect.call {|x| block.call(x) == value}
    elsif args.size == 2 && !block
      attr_name, value = args
      detect.call {|x| x.send(attr_name) == value}
    else
      detect.call(*args, &block)
    end
  end

  # #inject is "left fold". #inject_right is "right fold".
  # @see http://en.wikipedia.org/wiki/Fold_%28higher-order_function%29
  def inject_right(*args, &block)
    self.reverse_each.inject(*args, &block) # reverse_each to avoid duplicating the enumerable, when possible
  end

  # Pads the end of an enumeration with additional values, up to a given total size
  # @param n [Integer] The final size
  # @param value [Object] The object to pad with. Defaults to nil.
  # @yieldreturn [Object] If provided, the block overrides the value argument
  #   and is called to obtain the padding value, once for each item.
  def pad_right(n, value=nil, &block)
    block ||= proc { value }
    self + ([n-self.size, 0].max).times.map(&block)
  end

  # Like #sort, but does not reorder comparable items.
  def stable_sort(&compare)
    compare = compare || ->(a, b){a <=> b}
    xis = self.each_with_index.map{|x, i| [x, i]}
    sorted = xis.sort do |(a, ai), (b, bi)|
      primary = compare.call(a, b)
      primary != 0 ? primary : (ai <=> bi)
    end
    sorted.map(&:first)
  end
end
