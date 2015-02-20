module Enumerable
  def stable_sort(&compare)
    compare = compare || ->(a, b){a <=> b}
    xis = self.each_with_index.map{|x, i| [x, i]}
    sorted = xis.sort do |(a, ai), (b, bi)|
      primary = compare.call(a, b)
      primary != 0 ? primary : (ai <=> bi)
    end
    sorted.map(&:first)
  end
end
