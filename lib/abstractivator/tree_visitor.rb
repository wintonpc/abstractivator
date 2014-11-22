require 'set'
require 'ostruct'
require 'abstractivator/collections'
require 'abstractivator/cons'

module Abstractivator
  module TreeVisitor

    def transform_tree(hash, &block)
      Closure.new(block).transform(hash, Cons.empty_list)
    end

    class Closure
      include Abstractivator::Cons

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

      def initialize(block)
        @block = block || ->(_, value){value}
      end
    end

    class Path < OpenStruct
      def initialize(names)
        super(nil)
        @names = names
      end

      def to_s
        @names.join('/')
      end

      def ===(other)
        onames = other.split('/')
        return false if @names.size != onames.size
        @names.zip(onames).map {|a, b|
          bstr = b.to_s
          if bstr[0] == ':'
            self[bstr[1..-1].to_sym] = a
            true
          else
            a == b
          end
        }.all?
      end
    end
  end
end

class String
  def ===(other)
    case other
      when Abstractivator::TreeVisitor::Path
        other === self
      else
        super(other)
    end
  end
end