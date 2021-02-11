RSpec.describe Gloss::Visitor do
  it "expands macros" do
    output = Gloss::Visitor.new(
      {:type=>"CollectionNode", :children=>[{:type=>"ClassNode", :name=>{:type=>"Path", :value=>"BaseController"}, :body=>{:type=>"DefNode", :name=>"render", :body=>nil, :rp_args=>[], :receiver=>nil, :return_type=>nil, :rest_kw_args=>{:type=>"Arg", :name=>"args", :external_name=>"args", :default_value=>nil, :restriction=>nil}}, :superclass=>nil, :type_vars=>nil, :abstract=>false}, {:type=>"MacroFor", :vars=>[{:type=>"Var", :name=>"controller_name"}], :expr=>{:type=>"ArrayLiteral", :elements=>[{:type=>"LiteralNode", :value=>"\"Recipes\"", :rb_type=>"String"}, {:type=>"LiteralNode", :value=>"\"Ingredients\"", :rb_type=>"String"}], :frozen=>false}, :body=>{:type=>"CollectionNode", :children=>[{:type=>"MacroLiteral", :value=>"\n  class "}, {:type=>"MacroExpression", :expr=>{:type=>"Var", :name=>"controller_name"}, :output=>true}, {:type=>"MacroLiteral", :value=>"Controller < BaseController\n    "}, {:type=>"MacroFor", :vars=>[{:type=>"Var", :name=>"method_name"}], :expr=>{:type=>"ArrayLiteral", :elements=>[{:type=>"LiteralNode", :value=>"\"index\"", :rb_type=>"String"}, {:type=>"LiteralNode", :value=>"\"create\"", :rb_type=>"String"}], :frozen=>false}, :body=>{:type=>"CollectionNode", :children=>[{:type=>"MacroLiteral", :value=>"\n      def "}, {:type=>"MacroExpression", :expr=>{:type=>"Var", :name=>"method_name"}, :output=>true}, {:type=>"MacroLiteral", :value=>"\n        "}, {:type=>"MacroIf", :condition=>{:type=>"Call", :name=>"==", :args=>[{:type=>"LiteralNode", :value=>"\"create\"", :rb_type=>"String"}], :object=>{:type=>"LiteralNode", :value=>"\"{{method_name}}\"", :rb_type=>"String"}, :block=>nil, :block_arg=>nil}, :then=>{:type=>"MacroLiteral", :value=>"\n          status = 201\n        "}, :else=>{:type=>"MacroLiteral", :value=>"\n          status = 200\n        "}}, {:type=>"MacroLiteral", :value=>"\n        render json: "}, {:type=>"MacroLiteral", :value=>"{ msg: \"hello from "}, {:type=>"MacroExpression", :expr=>{:type=>"Var", :name=>"method_name"}, :output=>true}, {:type=>"MacroLiteral", :value=>" in "}, {:type=>"MacroExpression", :expr=>{:type=>"Var", :name=>"controller_name"}, :output=>true}, {:type=>"MacroLiteral", :value=>"Controller\" },\n          status: status\n      "}, {:type=>"MacroLiteral", :value=>"end\n    "}]}}, {:type=>"MacroLiteral", :value=>"\n  "}, {:type=>"MacroLiteral", :value=>"end\n"}]}}]}
    ).run
    expect(output.lines.map(&:lstrip).join("\n")).to eq Gloss::Utils.with_file_header(<<-RUBY).lines.map(&:lstrip).join("\n")
class BaseController
  def render(**args)
  end
end

  class RecipesController < BaseController

      def index
        status = 200

        render json: { msg: "hello from index in RecipesController" },
          status: status
      end

      def create
        status = 200

        render json: { msg: "hello from create in RecipesController" },
          status: status
      end

  end

  class IngredientsController < BaseController

      def index
        status = 200

        render json: { msg: "hello from index in IngredientsController" },
          status: status
      end

      def create
        status = 200

        render json: { msg: "hello from create in IngredientsController" },
          status: status
      end

  end
    RUBY
  end
end
