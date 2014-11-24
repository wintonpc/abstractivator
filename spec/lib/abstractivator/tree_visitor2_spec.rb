require 'rspec'
require 'abstractivator/tree_visitor'
require 'abstractivator/tree_visitor2'
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
        expect{ transform_tree2(hash) }.to raise_error ArgumentError, 'Must provide a transformer block'
      end
    end

    it 'replaces hash members'
    it 'replaces array members'
    it 'replaces hashes'
    it 'replaces arrays'
    it 'replaces primitive values'

    context 'when a block is provided' do
      it 'replaces the value with the return value of the block' do
        result = transform_tree2(hash) do |t|
          t.when('a/b1/c') {|v| v.reverse }
          t.when('a/b2/c') {|v| v.reverse }
        end
        expect(result[:a][:b1][:c]).to eql 'c.1b.a'
        expect(result[:a][:b2][:c]).to eql 'c.2b.a'
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

  it 'performs' do

    ac_in = JSON.parse(File.read('assay.json'))

    ac_in1 = ac_in.deep_dup
    ac_out1 = nil
    time_it(:deep_dup) do
      ac_out1 = ac_in1.deep_dup
    end

    ac_in2 = ac_in.deep_dup
    ac_out2 = nil
    time_it(:ad_hoc) do
      ac_out2 = ac_in2.deep_dup
      ac_out2['compound_methods'].each do |cm|
        cal = cm['calibration']
        cal['normalizers'].map!{|x| x.to_s.reverse}
        cal['responses'].map!{|x| x.to_s.reverse}

        rs = cm['rule_settings']
        rs.each_pair do |k, v|
          rs[k] = v.to_s.reverse
        end

        cm['chromatogram_methods'].each do |chrom|
          ret_time = chrom['peak_integration']['retention_time']

          if ret_time['reference_type_source'] == 'chromatogram'
            ret_time[:reference] = ret_time[:reference].to_s.reverse
          end

          rs = chrom['rule_settings']
          rs.each_pair do |k, v|
            rs[k] = v.to_s.reverse
          end
        end

      end
    end

    ac_in3 = ac_in.deep_dup
    ac_out3 = nil
    time_it(:transform_tree2) do
      ac_out3 = transform_tree2(ac_in3) do |t|
        t.when('compound_methods/calibration/normalizers[]') {|v| v.to_s.reverse}
        t.when('compound_methods/calibration/responses[]') {|v| v.to_s.reverse}
        t.when('compound_methods/rule_settings{}') {|v| v.to_s.reverse}
        t.when('compound_methods/chromatogram_methods/rule_settings{}') {|v| v.to_s.reverse}
        t.when('compound_methods/chromatogram_methods/peak_integration/retention_time') do |ret_time|
          if ret_time['reference_type_source'] == 'chromatogram'
            ret_time['reference'] = ret_time['reference'].to_s.reverse
          end
          ret_time
        end
      end
    end

    # File.write('a.json', JSON.dump(ac_tt))
    # File.write('b.json', JSON.dump(ac_tt2))
    #
    # expect(ac_tt2).to eql ac_tt

  end

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