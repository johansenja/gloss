require 'gloss'

RSpec.describe Gloss::Builder do
  it "allows single quoted strings" do
    expect(Gloss::Builder.new("str = 'abc'").run)
  end

  it "doesn't require 'of' after empty arrays" do
    expect(Gloss::Builder.new("arr = []").run)
  end

  it "doesn't require 'of' after empty hashes" do
    expect(Gloss::Builder.new("hsh = {}").run)
  end

  it "captures all kinds of method args" do
    output = Gloss::Builder.new(<<~GLOSS).run
      def abc(a : Float, b, *c, d : String? = nil, e: : Integer, f:, g: : String = nil, **h)
      end
    GLOSS
    expect(output.to eq <<~RUBY)
      def abc(a, b, *c, d = nil, e:, f:, g: nil, **h)
      end
    RUBY
  end

  it "parses rescue with ruby syntax" do
    expect(Gloss::Builder.new(<<~GLOSS).run)
      begin
        raise "Abc"
      rescue RuntimeError => e
        p e.message
      rescue NoMethodError
      rescue => e
      end
    GLOSS
  end

  it "parses shorthand blocks with ruby syntax" do
    expect(Gloss::Builder.new("[1].map(&:to_s)").run).to eq "# frozen_string_literal: true\n[1].map(&:to_s)\n"
  end

  it "parses tuples as frozen arrays" do
    expect(Gloss::Builder.new("{ 'hello', 'world' }").run).to eq %{# frozen_string_literal: true\n["hello", "world"].freeze}
  end

  it "parses named tuples as frozen hashes" do
    expect(Gloss::Builder.new("{ hello: 'world' }").run).to eq %{# frozen_string_literal: true\n{:hello => "world"}.freeze}
  end
end
