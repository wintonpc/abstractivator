require 'rspec'
require 'abstractivator/tree_visitor'

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
    Path = Abstractivator::TreeVisitor::Path
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
    it 'rejects multiple wildcards' do
      path = Path.new(%w(a b))
      expect{path === '*/*'}.to raise_error ArgumentError, 'Cannot have more than one wildcard'
    end
    it 'rejects mixtures of wildcards and pattern variables' do
      path = Path.new(%w(a b))
      expect{path === '*/:x'}.to raise_error ArgumentError, 'Cannot mix wildcard with pattern variables'
    end
    it 'allows a wildcard' do
      path = Path.new(%w(foo things 3 thing _id))
      expect(path === 'foo/things/*/_id').to be_truthy
      expect(path === 'foo/things/*/xyz').to be_falsey
      expect(path === 'foo/things/a/b/c/d*/xyz').to be_falsey
      expect(path === 'foo/things/*/a/b/c/d/xyz').to be_falsey
      expect(path === 'foo/*/xyz').to be_falsey
    end
    it 'wildcard matches zero or more' do
      path = Path.new(%w(foo bar))
      expect(path === 'foo/*/bar').to be_truthy
    end
    it 'wilcards can be open ended' do
      path = Path.new(%w(a b c))
      expect(path === 'a/*').to be_truthy
      expect(path === '*/c').to be_truthy
    end
  end
end