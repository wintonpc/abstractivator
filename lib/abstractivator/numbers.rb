require 'abstractivator/enumerator_ext'

module Numbers
  def from(n, increment=1)
    Enumerator.unfold(n) { |nxt| [nxt, nxt + increment] }
  end

  extend self
end
