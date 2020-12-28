require 'hrb'

RSpec.describe Hrb::Builder do
  it "allows single quoted strings" do
    expect(Hrb::Builder.new("str = 'abc'").run)
  end

  it "doesn't require 'of' after empty arrays" do
    expect(Hrb::Builder.new("arr = []").run)
  end

  it "doesn't require 'of' after empty hashes" do
    expect(Hrb::Builder.new("hsh = {}").run)
  end
end
