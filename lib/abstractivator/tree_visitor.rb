class Abstractivator
  class TreeVisitor
    def visit(hash, paths, &block)
      self.new(hash, paths, block).go
    end

    private

    def initialize(hash, paths, &block)
      @hash = hash
      init_paths(paths)
      @block = block
    end

    def init_paths(paths)

    end
  end
end