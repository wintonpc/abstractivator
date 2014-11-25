require 'rspec'
require 'abstractivator/tree_visitor'
require 'json'
require 'rails'

describe Abstractivator::TreeVisitor do

  include Abstractivator::TreeVisitor

  describe '#visit' do

    context 'when no block is provided' do
      it 'raises an exception' do
        expect{ transform_tree(hash) }.to raise_error ArgumentError, 'Must provide a transformer block'
      end
    end

    it 'handles both string and symbol keys' do
      h = {:a => 1, 'b' => 2}
      result = transform_tree(h) do |t|
        t.when('a') {|v| v + 10}
        t.when('b') {|v| v + 10}
      end
      expect(result).to eql({:a => 11, 'b' => 12})
    end

    it 'replaces primitive-type hash fields' do
      h = {'a' => 1}
      result = transform_one_path(h, 'a') { 2 }
      expect(result).to eql({'a' => 2})
    end

    it 'replaces hash-type hash fields' do
      h = {'a' => {'b' => 1}}
      result = transform_one_path(h, 'a') { {'z' => 99} }
      expect(result).to eql({'a' => {'z' => 99}})
    end

    it 'replaces array-type hash fields' do
      h = {'a' => [1,2,3]}
      result = transform_one_path(h, 'a') {|v| v.reverse}
      expect(result).to eql({'a' => [3,2,1]})
    end

    it 'replaces primitive-type hash members' do
      h = {'a' => {'b' => 'foo', 'c' => 'bar'}}
      result = transform_one_path(h, 'a{}') {|v| v.reverse}
      expect(result).to eql({'a' => {'b' => 'oof', 'c' => 'rab'}})
    end

    it 'replaces hash-type hash members' do
      h = {'a' => {'b' => {'x' => 88}, 'c' => {'x' => 88}}}
      result = transform_one_path(h, 'a{}') {|v| {'y' => 99}}
      expect(result).to eql({'a' => {'b' => {'y' => 99}, 'c' => {'y' => 99}}})
    end

    it 'replaces array-type hash members' do
      h = {'a' => {'b' => [1,2,3], 'c' => [4,5,6]}}
      result = transform_one_path(h, 'a{}') {|v| v.reverse}
      expect(result).to eql({'a' => {'b' => [3,2,1], 'c' => [6,5,4]}})
    end

    it 'replaces primitive-type array members' do
      h = {'a' => [1, 2]}
      result = transform_one_path(h, 'a[]') {|v| v + 10}
      expect(result).to eql({'a' => [11, 12]})
    end

    it 'replaces hash-type array members' do
      h = {'a' => [{'b' => 1}, {'c' => 2}]}
      result = transform_one_path(h, 'a[]') { {'z' => 99} }
      expect(result).to eql({'a' => [{'z' => 99}, {'z' => 99}]})
    end

    it 'replaces array-type array members' do
      h = {'a' => [[1,2,3], [4,5,6]]}
      result = transform_one_path(h, 'a[]') {|v| v.reverse}
      expect(result).to eql({'a' => [[3,2,1], [6,5,4]]})
    end

    context 'mutation' do
      before(:each) do
        @old = {'a' => {'x' => 1, 'y' => 2}, 'b' => {'x' => 17, 'y' => 23}}
        @new = transform_one_path(@old,'a') {|v|
          v['z'] = v['x'] + v['y']
          v
        }
      end
      it 'does not mutate the input' do
        expect(@old).to eql({'a' => {'x' => 1, 'y' => 2}, 'b' => {'x' => 17, 'y' => 23}})
        expect(@new).to eql({'a' => {'x' => 1, 'y' => 2, 'z' => 3}, 'b' => {'x' => 17, 'y' => 23}})
      end
      it 'preserves unmodified substructure' do
        expect(@old['a'].equal?(@new['a'])).to be_falsey
        expect(@old['b'].equal?(@new['b'])).to be_truthy
      end
    end

    def transform_one_path(h, path, &block)
      transform_tree(h) do |t|
        t.when(path, &block)
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
      ###############################################
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
        ###############################################

      end
    end

    ac_in3 = ac_in.deep_dup
    ac_out3 = nil
    time_it(:transform_tree) do
      ###############################################
      ac_out3 = transform_tree(ac_in3) do |t|
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
      ###############################################
    end

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