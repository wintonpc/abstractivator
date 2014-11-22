require 'rspec'
require 'abstractivator/tree_visitor'

describe Abstractivator::TreeVisitor do

  include Abstractivator::TreeVisitor

  let!(:hash) do
    {
      a: {
        b1: {
          _id: :asdf,
          c: 'a.b1.c'
        },
        b2: {
          _id: :qwerty,
          c: 'a.b2.c'
        }
      },
      d: [
           {
             _id: :smbc,
             e: 'd.0.e',
             f: 'd.0.f'
           },
           {
             _id: :roygbiv,
             e: 'd.1.e',
             f: 'd.1.f'
           }
         ]
    }
  end

  describe '#visit' do

    context 'when no block is provided' do
      it 'raises an exception' do
        expect{ transform_tree(hash) }.to raise_error ArgumentError, 'Must provide a transformer block'
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

      context 'examples' do
        it 'replace all ids' do
          result = transform_tree(hash) do |path, value|
            case path
              when '*/_id'
                value.to_s.reverse
              else
                value
            end
          end
          result.to_s
        end
      end

      it 'when visiting a hash, if the block returns true, hash members are visited' do
        test_hash_visiting(true, nil)
      end

      it 'when visiting a hash, if the block returns false, hash members are not visited' do
        test_hash_visiting(false, nil)
      end

      it 'when visiting an array, if the block returns true, array elements are visited' do
        test_array_visiting(true, nil)
      end

      it 'when visiting an array, if the block returns false, array elements are not visited' do
        test_array_visiting(false, nil)
      end

      def test_hash_visiting(should_visit, replacement)
        test_visiting(should_visit, replacement, 'a', 'a/b1')
      end

      def test_array_visiting(should_visit, replacement)
        test_visiting(should_visit, replacement, 'd', 'd/0')
      end

      def test_visiting(should_visit, replacement, key, subkey)
        saw_it = false
        transform_tree(hash) do |path, value|
          case path
            when key
              [replacement, should_visit]
            when subkey
              saw_it = true
            else
              value
          end
        end
        expect(saw_it).to eql should_visit
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