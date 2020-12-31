require "./spec_helper"

module Gloss
  describe Parser do
    it "allows single quoted strings" do
      Gloss.parse_string("puts 'hello world'").should be_truthy
    end

    it "doesn't require 'of' after empty arrays" do
      Gloss.parse_string("arr = []").should be_truthy
    end

    it "doesn't require 'of' after empty hashes" do
      Gloss.parse_string("hsh = {}").should be_truthy
    end

    it "parses all kinds of method args" do
      Gloss.parse_string(<<-GLS).should eq("TBD")
        def abc(a : Float, b, *c, d : String? = nil, e: : Integer, f:, g: : String = nil, **h)
        end
      GLS
    end

    it "parses rescue with ruby syntax" do
      Gloss.parse_string(<<-GLOSS).should be_truthy
        begin
          raise "Abc"
        rescue RuntimeError => e
          p e.message
        rescue NoMethodError
        rescue => e
        end
      GLOSS
    end
  end

  it "parses shorthand blocks with ruby syntax" do
    Gloss.parse_string("[1].map(&:to_s)").should eq(
      %q<{"type":"Call","name":"map","args":[],"object":{"type":"ArrayLiteral","elements":[{"type":"LiteralNode","value":"1","rb_type":"Integer"}],"frozen":false},"block":null,"block_arg":{"type":"LiteralNode","value":":to_s","rb_type":"Symbol"}}>
    )
  end

  it "parses tuples as frozen arrays" do
    Gloss.parse_string("{ 'hello', 'world' }").should eq(
      %q<{"type":"ArrayLiteral","elements":[{"type":"LiteralNode","value":"\"hello\"","rb_type":"String"},{"type":"LiteralNode","value":"\"world\"","rb_type":"String"}],"frozen":true}>
    )
  end

  it "parses named tuples as frozen hashes" do
    Gloss.parse_string("{ hello: 'world' }").should eq(
      %q<{"type":"HashLiteral","elements":[["hello",{"type":"LiteralNode","value":"\"world\"","rb_type":"String"}]],"frozen":true}>
    )
  end
end
