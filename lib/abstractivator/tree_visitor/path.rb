require 'abstractivator/cons'
require 'ostruct'

module Abstractivator
  module TreeVisitor
    class Path < OpenStruct
      include Abstractivator::Cons

      def initialize(names, name_count, patterns)
        super(nil)
        @names = names
        @name_count = name_count
        @patterns = patterns
      end

      class Pattern
        include Abstractivator::Cons

        attr_reader :is_wildcard, :length, :names

        def initialize(pat_str)
          names_array = pat_str.split('/').reverse
          @length = names_array.size
          @names = enum_to_list(names_array)

          wildcards = names_array.select{|x| x == '*'}
          if wildcards.size == 0
            @is_wildcard = false
          elsif wildcards.size > 1
            raise ArgumentError.new('Cannot have more than one wildcard')
          elsif names_array.any?{|x| x[0] == ':'}
            raise ArgumentError.new('Cannot mix wildcard with pattern variables')
          else
            @is_wildcard = true
          end
        end
      end

      # def to_s
      #   @names.join('/')
      # end

      def ===(other)
        pat = @patterns[other]
        unless pat
          pat = Pattern.new(other)
          @patterns[other] = pat
        end

        if pat.is_wildcard
          matching(@names, pat.names)
        elsif @name_count != pat.length # not a wildcard, so path lengths must match
          false
        else
          match_no_wildcards(@names, pat.names)
        end
      end

      def match_no_wildcards(path, pat)
        if path == empty_list
          true
        else
          pat_name = pat.head.to_s
          if pat_name[0] == ':'
            self[pat_name[1..-1].to_sym] = path.head
            match_no_wildcards(path.tail, pat.tail)
          elsif path.head != pat.head
            false
          else
            match_no_wildcards(path.tail, pat.tail)
          end
        end
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