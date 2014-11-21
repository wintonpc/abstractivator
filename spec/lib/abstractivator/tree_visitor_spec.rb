require 'rspec'
require 'abstractivator/tree_visitor'

describe Abstractivator::TreeVisitor do

  describe '#visit' do
    it 'visits stuff' do
      paths = [
          'a/b1',
          'compounds/*/view_order'
      ]
      hash = {
          a: {
              b1: {
                  c: 'a.b1.c'
              },
              b2: {
                  c: 'a.b2.c'
              }
          }
      }
      visited = []
      visit_tree(hash, paths) do |path, value|
        visited << value
      end
      expect(visited).to eql ['a.b1.c']
    end
  end
end