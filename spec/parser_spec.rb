require 'hrb'

RSpec.describe Hrb::Program do
  it "allows single quoted strings" do
    expect(Hrb::Program.new("str = 'abc'").output)
  end

  it "doesn't require 'of' after empty arrays" do
    expect(Hrb::Program.new("arr = []").output)
  end

  it "doesn't require 'of' after empty hashes" do
    expect(Hrb::Program.new("hsh = {}").output)
  end
end
