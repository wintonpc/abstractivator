require 'rspec'
require 'abstractivator/tree_visitor'

Path = Abstractivator::TreeVisitor::Path

describe Abstractivator::TreeVisitor do

  include Abstractivator::TreeVisitor

  let!(:hash) do
    {
      a: {
        b1: {
          _id: 1,
          c: 'a.b1.c'
        },
        b2: {
          _id: 2,
          c: 'a.b2.c'
        }
      },
      d: [
           {
             _id: 3,
             e: 'd.0.e',
             f: 'd.0.f'
           },
           {
             _id: 3,
             e: 'd.1.e',
             f: 'd.1.f'
           }
         ]
    }
  end
  describe '#visit' do
    context 'when no block is provided' do
      it 'returns a deep copy' do
        result = transform_tree(hash)
        expect(result).to eql hash
        expect(result.equal?(hash)).to be_falsey
      end
    end
    context 'when a block is provided' do
      it 'replaces the value with the return value of the block' do
        result = transform_tree(hash) do |path, value|
          case path
            when 'a/:x/c'
              "#{path.x}!!"
            else
              value
          end
        end
        expect(result[:a][:b1][:c]).to eql 'b1!!'
        expect(result[:a][:b2][:c]).to eql 'b2!!'
      end
    end
  end
  describe '::Path' do
    it 'matches with ===' do
      path = Path.new(%w(a b c))
      expect(path === 'a/b/c').to be_truthy
      expect(path === 'a/b/d').to be_falsey
      expect(path === 'a/b').to be_falsey
    end
    it 'captures match groups' do
      path = Path.new(%w(a b c d))
      expect(path === 'a/:x/c/:y').to be_truthy
      expect(path.x).to eql 'b'
      expect(path.y).to eql 'd'
    end
  end
end