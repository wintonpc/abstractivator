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

    ac = JSON.parse(File.read('assay.json'))

    # ac2 = nil
    #
    # time_it(:deep_dup) do
    #   ac2 = ac.deep_dup
    # end
    #
    # time_it(:ad_hoc) do
    #   ac2 = ac.deep_dup
    #   ac2['compound_methods'].each do |cm|
    #     cal = cm['calibration']
    #     cal['normalizers'].map!{|x| x.to_s.reverse}
    #     cal['responses'].map!{|x| x.to_s.reverse}
    #
    #     rs = cm['rule_settings']
    #     rs.each_pair do |k, v|
    #       rs[k] = v.to_s.reverse
    #     end
    #
    #     cm['chromatogram_methods'].each do |chrom|
    #       ret_time = chrom['peak_integration']['retention_time']
    #
    #       if ret_time['reference_type_source'] == 'chromatogram'
    #         ret_time[:reference] = ret_time[:reference].to_s.reverse
    #       end
    #
    #       rs = chrom['rule_settings']
    #       rs.each_pair do |k, v|
    #         rs[k] = v.to_s.reverse
    #       end
    #     end
    #
    #   end
    # end

    ac_tt = nil
    # time_it(:transform_tree) do
    #   ac_tt = transform_tree(ac) do |path, value|
    #     case path
    #       when 'compound_methods/:_/calibration/normalizers/:_'
    #         value.to_s.reverse
    #       when 'compound_methods/:_/calibration/responses/:_'
    #         value.to_s.reverse
    #       when 'compound_methods/:_/rule_settings/:key'
    #         value.to_s.reverse
    #       when 'compound_methods/:_/chromatogram_methods/:_/rule_settings/:key'
    #         value.to_s.reverse
    #       when 'compound_methods/:_/chromatogram_methods/:_/peak_integration/retention_time'
    #         if value['reference_type_source'] == 'chromatogram'
    #           value['reference'] = value['reference'].to_s.reverse
    #           [value, false]
    #         else
    #           [value, false]
    #         end
    #       else
    #         value
    #     end
    #   end
    # end

    ac_tt2 = nil
    time_it(:transform_tree2) do
      ac_tt2 = transform_tree2(ac) do |t|
        # t.when('compound_methods/calibration/normalizers[]') {|v| v.to_s.reverse}
        # t.when('compound_methods/calibration/responses[]') {|v| v.to_s.reverse}
        # t.when('compound_methods/rule_settings{}') {|v| v.to_s.reverse}
        # t.when('compound_methods/chromatogram_methods/rule_settings{}') {|v| v.to_s.reverse}
        t.when('compound_methods/chromatogram_methods/peak_integration/retention_time') do |ret_time|
          if ret_time['reference_type_source'] == 'chromatogram'
            ret_time['reference'] = ret_time['reference'].to_s.reverse
          end
          ret_time
        end
      end
    end

    File.write('a.json', JSON.dump(ac_tt))
    File.write('b.json', JSON.dump(ac_tt2))

    expect(ac_tt2).to eql ac_tt

  end

  # def do_obj(obj, path_tree)
  #   obj.is_a?(Array) ?
  #     do_array(obj, path_tree) :
  #     do_hash(obj, path_tree)
  # end
  #
  # def do_hash(h, path_tree)
  #   h = h.dup
  #   path_tree.each_pair do |name, path_tree|
  #     if path_tree.respond_to?(:call)
  #       if (hash_name = try_get_hash_name(name))
  #         h[hash_name] = h[hash_name].each_with_object(h[hash_name].dup) do |(key, value), fh|
  #           fh[key] = path_tree.call(value.deep_dup)
  #         end
  #       elsif (array_name = try_get_array_name(name))
  #         h[array_name] = h[array_name].map(&:deep_dup).map(&path_tree)
  #       else
  #         h[name] = path_tree.call(h[name].deep_dup)
  #       end
  #     else
  #       do_obj(h[name], path_tree)
  #     end
  #   end
  #   h
  # end
  #
  # def safe_dup(x)
  #   x.nil? ? nil : x
  # end
  #
  # def do_array(a, path_tree)
  #   a.map{|x| do_obj(x, path_tree)}
  # end
  #
  # def try_get_hash_name(p)
  #   p =~ /(.+)\{\}$/ ? $1 : nil
  # end
  #
  # def try_get_array_name(p)
  #   p =~ /(.+)\[\]$/ ? $1 : nil
  # end
  #
  # def transform_tree2(h)
  #   config = BlockCollector.new
  #   yield(config)
  #   do_obj(h, get_path_tree(config))
  # end
  #
  # def get_path_tree(config)
  #   path_tree = {}
  #   config.each_pair do |path, block|
  #     set_hash_path(path_tree, path.split('/'), block)
  #   end
  #   path_tree
  # end
  #
  # def set_hash_path(h, names, block)
  #   orig = h
  #   while names.size > 1
  #     h = (h[names.shift] ||= {})
  #   end
  #   h[names.shift] = block
  #   orig
  # end
  #
  # class BlockCollector < Hash
  #   def when(path, &block)
  #     self[path] = block
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