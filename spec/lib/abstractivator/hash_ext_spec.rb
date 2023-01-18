# frozen_string_literal: true

describe "Hash" do
  describe "::with_default" do
    it "makes the default item and keeps it" do
      h = Hash.with_default { Set.new }
      v1 = h[1]
      expect(v1).to be_a(Set)
      expect(h[1]).to be v1
    end

    it "can do multiple levels" do
      h = Hash.with_default(3) { [] }

      h[1][2][3] << "a"
      h[1][2][3] << "b"
      expect(h[1][2][3]).to eql %w[a b]
    end

    it "gives you the key if you want it" do
      h = Hash.with_default { |k| [k] }
      expect(h[5].include?(5)).to be true
    end
  end

  describe "#get_or_add" do
    it "returns the value or calls the block to create and add it" do
      h = {a: 1}
      expect(h.get_or_add(:a) { 9 }).to eql 1
      expect(h.get_or_add(:b) { 2 }).to eql 2
      expect(h).to eql({a: 1, b: 2})
      expect(h.get_or_add(:b) { 9 }).to eql 2
      expect(h).to eql({a: 1, b: 2})
    end
    it "returns the value or adds the default value" do
      h = {a: 1}
      expect(h.get_or_add(:a, 9)).to eql 1
      expect(h.get_or_add(:b, 2)).to eql 2
      expect(h).to eql({a: 1, b: 2})
      expect(h.get_or_add(:b, 9)).to eql 2
      expect(h).to eql({a: 1, b: 2})
    end
    it "block and value arg combinations" do
      # neither
      h = {}
      expect(h.get_or_add(:a)).to be_nil
      expect(h).to eql({a: nil})
      # value
      h = {}
      expect(h.get_or_add(:a, 1)).to eql 1
      expect(h).to eql({a: 1})
      # block
      h = {}
      expect(h.get_or_add(:a) { 1 }).to eql 1
      expect(h).to eql({a: 1})
      # both
      h = {}
      expect(h.get_or_add(:a, 9) { 1 }).to eql 1
      expect(h).to eql({a: 1})
    end
  end

  describe "#deep_flatten" do
    it "flattens hash keys" do
      h = {
          "a" => 1,
          "b" => 2,
          "c" => {
              "d" => 3,
              "e" => {
                  "f" => 4,
                  "g" => 5
              }
          },
          "h" => [
              6,
              [7, 8],
              {
                  "i" => 9
              }
          ]
      }
      expect(h.deep_flatten).to eql({
          "a" => 1,
          "b" => 2,
          "c.d" => 3,
          "c.e.f" => 4,
          "c.e.g" => 5,
          "h.0" => 6,
          "h.1.0" => 7,
          "h.1.1" => 8,
          "h.2.i" => 9
      })
    end
    it "converts symbol keys to string keys" do
      h = {
          a: 1,
          b: [2, {c: 3}]
      }
      expect(h.deep_flatten).to eql({
          "a" => 1,
          "b.0" => 2,
          "b.1.c" => 3
      })
    end
  end
end
