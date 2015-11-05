class Enumerator
  # @param state [Object] The initial state
  # @yieldparam state [Object] the current state
  # @yieldreturn [Array] a 2-element array containing the next value and the next state
  def self.unfold(state)
    raise 'block is required' unless block_given?
    Enumerator.new do |y|
      unless state.nil?
        loop do
          next_value, state = yield(state)
          break if state.nil?
          y << next_value
        end
      end
    end
  end

  attr_accessor :__memo__, :__memo_instance__

  def memoized
    @__memo_instance__ ||= self.dup
    inner = __memo_instance__
    inner.__memo__ ||= []
    Enumerator.new do |y|
      i = 0
      loop do
        inner.__memo__ << inner.next while inner.__memo__.size <= i
        y << inner.__memo__[i]
        i += 1
      end
    end
  end
end
