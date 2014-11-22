require 'abstractivator/collections'
require 'abstractivator/cons'
require 'abstractivator/tree_visitor/path'

module Abstractivator
  module TreeVisitor

    def transform_tree(hash, &block)
      Closure.new(block).transform(hash, Cons.empty_list, 0)
    end

    class Closure
      include Abstractivator::Cons

      def transform(x, path, depth)
        case x
          when Hash
            new_val, cont = visit(path, depth, x)
            if cont.nil? || cont
              x.each_with_object({}) do |(key, value), hash|
                hash[key] = transform(value, cons(key.to_s, path), depth + 1)
              end
            else
              new_val
            end
          when Array
            new_val, cont = visit(path, depth, x)
            if cont.nil? || cont
              arr = []
              x.each_with_index do |v, i|
                new_val = transform(v, cons(i.to_s, path), depth + 1)
                arr << new_val if new_val
              end
              arr
            else
              new_val
            end
          else
            visit(path, depth, x)
        end
      end

      def visit(path, depth, value)
        @block.call(Path.new(path, depth, @patterns), value)
      end

      def initialize(block)
        raise ArgumentError.new('Must provide a transformer block') unless block
        @block = block
        @patterns = {}
      end

    end
  end
end