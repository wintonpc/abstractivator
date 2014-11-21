module Abstractivator
  module Collections
    def multizip(enumerables, pad_value=nil)
      es = enumerables.map(&:each)
      result = []
      fail_count = 0
      while fail_count < es.size do
        fail_count = 0
        heads = es.map do |e|
          begin
            e.next
          rescue StopIteration
            fail_count += 1
            pad_value
          end
        end
        result << heads if fail_count < es.size
      end
      result
    end
  end
end