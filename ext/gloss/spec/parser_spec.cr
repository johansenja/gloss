require "./spec_helper"

module Gloss
  describe Parser do
    it "allows single quoted strings" do
      Gloss.parse_string("puts 'hello world'").should be_truthy
    end

    it "doesn't require 'of' after empty arrays" do
      Gloss.parse_string("arr = []").should eq(
        %q|{"type":"Assign","op":null,"target":{"type":"Var","name":"arr"},"value":{"type":"ArrayLiteral","elements":[],"frozen":false}}|
      )
    end

    it "doesn't require 'of' after empty hashes" do
      Gloss.parse_string("hsh = {}").should be_truthy
    end

    it "parses all kinds of method args" do
      output = %q|{"type":"DefNode","name":"abc","body":null,"rp_args":[{"type":"Arg","name":"a","external_name":"a","default_value":null,"restriction":{"type":"Path","value":"Float"},"keyword_arg":false},{"type":"Arg","name":"b","external_name":"b","default_value":null,"restriction":null,"keyword_arg":false},{"type":"Arg","name":"c","external_name":"c","default_value":null,"restriction":null,"keyword_arg":false,splat: "true"},{"type":"Arg","name":"d","external_name":"d","default_value":{"type":"LiteralNode","value":"nil","rb_type":"NilClass"},"restriction":{"type":"Union","types":[{"type":"Path","value":"String"},{"type":"Path","value":"Nil"}]},"keyword_arg":false},{"type":"Arg","name":"e","external_name":"e","default_value":null,"restriction":{"type":"Path","value":"Integer"},"keyword_arg":true},{"type":"Arg","name":"f","external_name":"f","default_value":null,"restriction":null,"keyword_arg":true},{"type":"Arg","name":"g","external_name":"g","default_value":{"type":"LiteralNode","value":"nil","rb_type":"NilClass"},"restriction":{"type":"Path","value":"String"},"keyword_arg":true}],"receiver":null,"return_type":null,"rest_kw_args":{"type":"Arg","name":"h","external_name":"h","default_value":null,"restriction":null,"keyword_arg":false}}|
      Gloss.parse_string(<<-GLS).should eq output
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

  it "parses the and operator" do
    Gloss.parse_string("puts 'hello world' if 1 and 2").should be_truthy
  end

  it "parses the or operator" do
    Gloss.parse_string("puts 'hello world' if true or false").should be_truthy
  end

  it "parses the not operator" do
    Gloss.parse_string("puts 'hello world' if true and not false").should be_truthy
  end

  it "parses global variables" do
    Gloss.parse_string("$var : String = 'hello world'").should eq(
      %q|{"type":"TypeDeclaration","var":{"type":"GlobalVar","name":"$var"},"declared_type":{"type":"Path","value":"String"},"value":{"type":"LiteralNode","value":"\"hello world\"","rb_type":"String"},"var_type":"GlobalVar"}|
    )
  end

  it "parses for loops" do
    Gloss.parse_string(<<-GLS).should be_truthy
      for k, v in { hello: world }
        puts key: k, value: v
      end
    GLS
  end
end
