require 'rspec'
require 'abstractivator/trees/tree_map'
require 'json'
require 'rails'
require 'pp'

describe Abstractivator::Trees do

  include Abstractivator::Trees

  describe '#tree_map' do

    context 'when no block is provided' do
      it 'raises an exception' do
        expect{ tree_map(hash) }.to raise_error ArgumentError, 'Must provide a transformer block'
      end
    end

    it 'handles both string and symbol keys' do
      h = {:a => 1, 'b' => 2}
      result = tree_map(h) do |t|
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

    it 'replaces nil hash fields' do
      h = {'a' => nil}
      result = transform_one_path(h, 'a') {|v| v.to_s}
      expect(result).to eql({'a' => ''})
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

    it 'deletes values' do
      h = {
          a: 1,
          b: [4, 5, 6],
          c: { d: 9, e: 10 },
          f: { g: 101, h: 102, i: 103 }
      }
      result = tree_map(h) do |t|
        t.when('a') { t.delete }
        t.when('c/d') { t.delete }
        t.when('b[]') { |x| x.even? ? t.delete : x }
        t.when('f{}') { |x| x.even? ? t.delete : x }
      end
      expect(result).to eql({b: [5], c: {e: 10}, f: {g: 101, i: 103}})
    end

    context 'when replacing array members' do
      it 'allows the array to be nil' do
        h = {'a' => nil}
        result = transform_one_path(h, 'a[]') {|v| v + 1}
        expect(result).to eql({'a' => nil})
      end
      it 'passes the index as the second argument' do
        h = {a: %w(one two)}
        call_count = 0
        transform_one_path(h, 'a[]') do |v, i|
          expect(i).to eql 0 if v == 'one'
          expect(i).to eql 1 if v == 'two'
          call_count += 1
        end
        expect(call_count).to eql 2
      end
      it 'raises an error is the value is not an array' do
        expect{transform_one_path({a: 1}, 'a[]') { |x| x }}.to raise_error 'Expected an array but got Fixnum: 1'
        expect{transform_one_path({a: {b: 1}}, 'a[]') { |x| x }}.to raise_error 'Expected an array but got Hash: {:b=>1}'
      end
    end

    context 'when replacing hash members' do
      it 'allows the hash to be nil' do
        h = {'a' => nil}
        result = transform_one_path(h, 'a{}') {|v| v + 1}
        expect(result).to eql({'a' => nil})
      end
      it 'passes the key as the second argument' do
        h = {a: {b: 1, c: 2}}
        call_count = 0
        transform_one_path(h, 'a{}') do |v, k|
          expect(k).to eql :b if v == 1
          expect(k).to eql :c if v == 2
          call_count += 1
        end
        expect(call_count).to eql 2
      end
      it 'raises an error is the value is not a hash' do
        expect{transform_one_path({a: 1}, 'a{}') { |x| x }}.to raise_error 'Expected a hash but got Fixnum: 1'
        expect{transform_one_path({a: [1, 2]}, 'a{}') { |x| x }}.to raise_error 'Expected a hash but got Array: [1, 2]'
      end
    end

    it 'it does not add missing keys' do # regression test
      result = tree_map({}) do |t|
        t.when('foo') { |x| x }
        t.when('bars[]') { |x| x }
        t.when('others/baz') { |x| x }
      end
      expect(result).to eql({})
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

      #TODO: create a generic json file to use for this test
      # it 'really does not mutate the input' do
      #   old = JSON.parse(File.read('assay.json'))
      #   old2 = old.deep_dup
      #   tree_map(old) do |t|
      #     t.when('compound_methods/calibration/normalizers[]') {|v| v.to_s.reverse}
      #     t.when('compound_methods/calibration/responses[]') {|v| v.to_s.reverse}
      #     t.when('compound_methods/rule_settings{}') {|v| v.to_s.reverse}
      #     t.when('compound_methods/chromatogram_methods/rule_settings{}') {|v| v.to_s.reverse}
      #     t.when('compound_methods/chromatogram_methods/peak_integration/retention_time') do |ret_time|
      #       if ret_time['reference_type_source'] == 'chromatogram'
      #         ret_time['reference'] = ret_time['reference'].to_s.reverse
      #       end
      #       ret_time
      #     end
      #   end
      #   expect(old).to eql old2
      # end
    end

    def transform_one_path(h, path, &block)
      tree_map(h) do |t|
        t.when(path, &block)
      end
    end
  end

end
