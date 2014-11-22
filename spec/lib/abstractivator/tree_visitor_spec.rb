require 'rspec'
require 'abstractivator/tree_visitor'

describe Abstractivator::TreeVisitor do

  let!(:hash) do
    {
      a: {
        b1: {
          c: 'a.b1.c'
        },
        b2: {
          c: 'a.b2.c'
        }
      },
      d: [
           {
             e: 'd.0.e',
             f: 'd.0.f'
           },
           {
             e: 'd.1.e',
             f: 'd.1.f'
           }
         ]
    }
  end
  describe '#visit' do
    context 'when no block is specified' do
      it 'returns a deep copy' do
        result = transform_tree(hash)
        expect(result).to eql hash
        expect(result.equal?(hash)).to be_falsey
      end
    end
  end
end