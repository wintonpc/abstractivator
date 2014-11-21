require 'set'
require 'ostruct'
require 'abstractivator/collections'
require 'abstractivator/cons'

module Abstractivator
  class TreeVisitor
    include Abstractivator::Collections
    include Abstractivator::Cons

    def self.visit(hash, paths, &block)
      self.new(hash, paths, block).visit_level(hash, 0, [])
    end

    def visit_level(x, n, path)
      case x
        when Hash
          keys_to_visit = n > @keys_by_level.size || @keys_by_level[n].include?('*') ? x.keys : @keys_by_level[n]
          keys_to_visit.each do |name|
            v = x[name.to_sym]
            visit_level(v, n + 1, cons(name, path)) if v
          end
        when Array
          x.each_with_index{|v, i| visit_level(v, n + 1, cons(i.to_s, path))}
        else
          @block.(Path.new(list_to_enum(path).to_a.reverse), x)
      end
    end

    private

    def initialize(hash, paths, block)
      @hash = hash
      init_paths(paths)
      @block = block
    end

    def init_paths(paths)
      @keys_by_level = multizip(paths.map{|p| p.split('/')}, nil).map{|names| Set.new(names.reject(&:nil?))}
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

def visit_tree(*args, &block)
  Abstractivator::TreeVisitor.visit(*args, &block)
end