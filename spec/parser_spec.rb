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

  it "captures all kinds of method args" do
    output = Hrb::Builder.new(<<~HRB).run
      def abc(a : Float, b, *c, d : String? = nil, e: : Integer, f:, g: : String = nil, **h)
      end
    HRB
    expect(output.to eq <<~RUBY)
      def abc(a, b, *c, d = nil, e:, f:, g: nil, **h)
      end
    RUBY
  end

  it "parses rescue with ruby syntax" do
    expect(Hrb::Builder.new(<<~HRB).run)
      begin
        raise "Abc"
      rescue RuntimeError => e
        p e.message
      rescue NoMethodError
      rescue => e
      end
    HRB
  end
end
