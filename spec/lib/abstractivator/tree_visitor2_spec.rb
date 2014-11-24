require 'rspec'
require 'abstractivator/tree_visitor'
require 'json'
require 'rails'

describe Abstractivator::TreeVisitor do

  include Abstractivator::TreeVisitor

  it 'performs' do

    ac = JSON.parse(File.read('assay.json'))

    ac2 = nil

    time_it(:deep_dup) do
      ac2 = ac.deep_dup
    end

    time_it(:ad_hoc) do
      ac2 = ac.deep_dup
      ac2['compound_methods'].each do |cm|
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

    time_it(:transform_tree) do
      ac2 = transform_tree(ac) do |path, value|
        case path
          when 'compound_methods/:_/calibration/normalizers/:_'
            value.to_s.reverse
          when 'compound_methods/:_/calibration/responses/:_'
            value.to_s.reverse
          when 'compound_methods/:_/rule_settings/:key'
            value.to_s.reverse
          when 'compound_methods/:_/chromatogram_methods/:_rule_settings/:key'
            value.to_s.reverse
          when 'compound_methods/:_/chromatogram_methods/:_/peak_integration/retention_time'
            if value['reference_type_source'] == 'chromatogram'
              value['reference'] = value['reference'].to_s.reverse
              [value, false]
            else
              [value, false]
            end
          else
            value
        end
      end
    end

    time_it(:transform_tree2) do
      transform_tree2(ac) do |t|
        t.when('compound_methods/calibration/normalizers[]') {|v| v.to_s.reverse}
        t.when('compound_methods/calibration/responses[]') {|v| v.to_s.reverse}
        t.when('compound_methods/rule_settings{}') {|v| v.to_s.reverse}
        t.when('compound_methods/chromatogram_methods/rule_settings{}') {|v| v.to_s.reverse}
        t.when('compound_methods/chromatogram_methods/peak_integration/retention_time') do |ret_time|
          if ret_time['reference_type_source'] == 'chromatogram'
            ret_time['reference'] = ret_time['reference'].to_s.reverse
          end
        end
      end
    end

  end

  def foo(obj)

    path_tree = {
      'compound_methods' => {
        'calibration' => {
          'normalizers[]' => proc {|v| v.to_s.reverse},
          'responses[]' => proc {|v| v.to_s.reverse},
        },
        'rule_settings{}' => proc {|v| v.to_s.reverse},
        'chromatogram_methods' => {
          'rule_settings{}' => proc {|v| v.to_s.reverse},
          'peak_integration' => {
            'retention_time' => proc {|ret_time|
              if ret_time['reference_type_source'] == 'chromatogram'
                ret_time['reference'] = ret_time['reference'].to_s.reverse
              end
            }
          }
        }
      }
    }

    do_obj(obj, path_tree)

    h['compound_methods'].dup.each do |cm|

      cm = cm.dup
      t1 = cm['calibration'].dup

      t2 = t1['normalizers'].dup
      t2.map!(&block[0])

      t3 = t1['responses'].dup
      t3.map!(&block[1])

      each_with_object(cm['rule_settings'].dup) do |(k, v), h|
        h[k] = block[2].call(v)
      end

      t5 = cm['chromatogram_methods'].dup
      t5.each do |chm|

        each_with_object(cm['rule_settings'].dup) do |(k, v), h|
          h[k] = block[3].call(v)
        end

        t7 = chm['peak_integration'].dup
        t8 = t7['retention_time'].dup
        t7['retention_time'] = block[4].call(t8)
      end
    end
  end

  def do_obj(obj, path_tree)
    obj.is_a?(Array) ? do_array(obj, path_tree) : do_hash(obj, path_tree)
  end

  def do_hash(h, path_tree)
    h = h.dup
    path_tree.each_pair do |name, path_tree|
      if path_tree.respond_to?(:call)
        if (hash_name = try_get_hash_name(name))
          h[hash_name] = each_with_object(h[hash_name].dup) do |(key, value), fh|
            fh[key] = path_tree.call(value.dup)
          end
        elsif (array_name = try_get_array_name(name))
          h[array_name] = h[array_name].map(&:dup).map(&path_tree)
        else
          h[name] = h[name].dup
        end
      else

      end
    end
    h
  end

  def do_array(a, path_tree)

  end

  def try_get_hash_name(p)
    p =~ /(.+)\{\}$/ ? $1 : nil
  end

  def try_get_array_name(p)
    p =~ /(.+)\[\]$/ ? $1 : nil
  end

  def transform_tree2(h)
    config = BlockCollector.new
    yield(config)
    do_obj(h, get_path_tree(config))
  end

  def get_path_tree(config)
    path_tree = {}
    config.each_pair do |path, block|
      set_hash_path(path_tree, path.split('/'), block)
    end
    path_tree
  end

  def set_hash_path(h, names, block)
    orig = h
    while names.size > 1
      h = (h[names.shift] ||= {})
    end
    h[names.shift] = block
    orig
  end

  class BlockCollector < Hash
    def when(path, &block)
      self[path] = block
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