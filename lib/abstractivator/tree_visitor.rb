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
            new_val, cont = visit(path, x)
            if cont.nil? || cont
              x.each_with_object({}) do |(key, value), hash|
                hash[key] = transform(value, cons(key.to_s, path))
              end
            else
              new_val
            end
          when Array
            new_val, cont = visit(path, x)
            if cont.nil? || cont
              arr = []
              x.each_with_index do |v, i|
                new_val = transform(v, cons(i.to_s, path))
                arr << new_val if new_val
              end
              arr
            else
              new_val
            end
          else
            visit(path, x)
        end
      end

      def visit(path, value)
        @block.call(Path.new(list_to_enum(path).to_a.reverse!), value)
        # @block.call(Path.new(nil), value)
      end

      def initialize(block)
        raise ArgumentError.new('Must provide a transformer block') unless block
        @block = block
      end
    end

    class Path < OpenStruct
      include Abstractivator::Cons

      def initialize(names)
        super(nil)
        @names = names
      end

      def to_s
        @names.join('/')
      end

      def ===(other)
        onames = other.split('/')

        # is it a wildcard?
        wildcard_result = try_match_wildcard(onames)
        return wildcard_result unless wildcard_result.nil?

        # not a wildcard, so path lengths must match
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

      def try_match_wildcard(onames)
        wildcards = onames.select{|x| x == '*'}
        if wildcards.size == 0
          return nil
        elsif wildcards.size > 1
          raise ArgumentError.new('Cannot have more than one wildcard')
        end
        if onames.any?{|x| x[0] == ':'}
          raise ArgumentError.new('Cannot mix wildcard with pattern variables')
        end

        matching(enum_to_list(@names), enum_to_list(onames))
      end

      def matching(path, pat)
        if path == empty_list && pat == empty_list
          true
        elsif path == empty_list || pat == empty_list
          false
        elsif pat.head == '*'
          wildcarding(path, pat.tail)
        elsif pat.head != path.head
          false
        else
          matching(path.tail, pat.tail)
        end
      end

      def wildcarding(path, pat)
        if pat == empty_list
          true
        elsif path == empty_list
          false
        elsif path.head == pat.head
          matching(path.tail, pat.tail)
        else
          wildcarding(path.tail, pat)
        end
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