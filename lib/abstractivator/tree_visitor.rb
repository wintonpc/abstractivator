require 'set'
require 'ostruct'
require 'abstractivator/collections'
require 'abstractivator/cons'

module Abstractivator
  class TreeVisitor
    include Abstractivator::Cons

    def self.transform(hash, &block)
      self.new(block).transform(hash, Cons.empty_list)
    end

    def transform(x, path)
      case x
        when Hash
          Hash[x.map{|kv| [kv.first, transform(kv.last, cons(kv.first.to_s, path))]}]
        when Array
          x.each_with_index.map{|v, i| transform(v, cons(i.to_s, path))}
        else
          @block.call(Path.new(list_to_enum(path).to_a.reverse), x)
      end
    end

    private

    def initialize(block)
      @block = block || ->(_, value){value}
    end

    class Path
      def initialize(names)
        @names = names
      end

      def to_s
        @names.join('/')
      end
    end
  end
end

def transform_tree(*args, &block)
  Abstractivator::TreeVisitor.transform(*args, &block)
end