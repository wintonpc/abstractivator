require 'rspec'
require 'abstractivator/tree_visitor'
require 'json'
require 'rails'

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

      it 'drops the array element if the block returns nil' do
        result = transform_tree(hash) do |path, value|
          case path
            when 'd/0'
              [nil, false]
            else
              value
          end
        end
        expect(result[:d].size).to eql 1
        expect(result[:d][0][:e]).to eql 'd.1.e'
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

    include Abstractivator::Cons

    it 'matches with ===' do
      path = make_path(%w(a b c))
      expect(path === 'a/b/c').to be_truthy
      expect(path === 'a/b/d').to be_falsey
      expect(path === 'a/b').to be_falsey
    end

    it 'captures match groups' do
      path = make_path(%w(a b c d))
      expect(path === 'a/:x/c/:y').to be_truthy
      expect(path.x).to eql 'b'
      expect(path.y).to eql 'd'
    end

    it 'rejects multiple wildcards' do
      path = make_path(%w(a b))
      expect{path === '*/*'}.to raise_error ArgumentError, 'Cannot have more than one wildcard'
    end

    it 'rejects mixtures of wildcards and pattern variables' do
      path = make_path(%w(a b))
      expect{path === '*/:x'}.to raise_error ArgumentError, 'Cannot mix wildcard with pattern variables'
    end

    it 'allows a wildcard' do
      path = make_path(%w(foo things 3 thing _id))
      expect(path === 'foo/things/*/_id').to be_truthy
      expect(path === 'foo/things/*/xyz').to be_falsey
      expect(path === 'foo/things/a/b/c/d*/xyz').to be_falsey
      expect(path === 'foo/things/*/a/b/c/d/xyz').to be_falsey
      expect(path === 'foo/*/xyz').to be_falsey
    end

    it 'wildcard matches zero or more' do
      path = make_path(%w(foo bar))
      expect(path === 'foo/*/bar').to be_truthy
    end

    it 'wildcards can be open ended' do
      path = make_path(%w(a b c))
      expect(path === 'a/*').to be_truthy
      expect(path === '*/c').to be_truthy
    end

    def make_path(names)
      Path.new(enum_to_list(names.reverse), names.size, {})
    end
  end

  # it 'performs' do
  #
  #   ac = JSON.parse(File.read('assay.json'))
  #
  #   ac2 = nil
  #
  #   time_it(:deep_dup) do
  #     ac2 = ac.deep_dup
  #   end
  #
  #   time_it(:ad_hoc) do
  #     ac2 = ac.deep_dup
  #     ac2['compound_methods'].each do |cm|
  #       cal = cm['calibration']
  #       cal['normalizers'].map!{|x| x.to_s.reverse}
  #       cal['responses'].map!{|x| x.to_s.reverse}
  #
  #       rs = cm['rule_settings']
  #       rs.each_pair do |k, v|
  #         rs[k] = v.to_s.reverse
  #       end
  #
  #       cm['chromatogram_methods'].each do |chrom|
  #         ret_time = chrom['peak_integration']['retention_time']
  #
  #         if ret_time['reference_type_source'] == 'chromatogram'
  #           ret_time[:reference] = ret_time[:reference].to_s.reverse
  #         end
  #
  #         rs = chrom['rule_settings']
  #         rs.each_pair do |k, v|
  #           rs[k] = v.to_s.reverse
  #         end
  #       end
  #
  #     end
  #   end
  #
  #   time_it(:transform_tree) do
  #     ac2 = transform_tree(ac) do |path, value|
  #       case path
  #         when 'compound_methods/:_/calibration/normalizers/:_'
  #           value.to_s.reverse
  #         when 'compound_methods/:_/calibration/responses/:_'
  #           value.to_s.reverse
  #         when 'compound_methods/:_/rule_settings/:key'
  #           value.to_s.reverse
  #         when 'compound_methods/:_/chromatogram_methods/:_rule_settings/:key'
  #           value.to_s.reverse
  #         when 'compound_methods/:_/chromatogram_methods/:_/peak_integration/retention_time'
  #           if value['reference_type_source'] == 'chromatogram'
  #             value['reference'] = value['reference'].to_s.reverse
  #             [value, false]
  #           else
  #             [value, false]
  #           end
  #         # when 'qa_rule_schemas'
  #         #   [value, false]
  #         # when 'compound_methods/:_/chromatogram_methods/:_/peak_integration/threshold'
  #         #   [value, false]
  #         # when 'compound_methods/:_/chromatogram_methods/:_/peak_integration/smoothing'
  #         #   [value, false]
  #         else
  #           value
  #       end
  #     end
  #   end
  # end

  def time_it(name)
    start = Time.now
    begin
      yield
    ensure
      stop = Time.now
      puts "#{name} took #{((stop - start) * 1000).round} ms"
    end
  end
end