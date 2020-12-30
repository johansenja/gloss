require "gloss"

RSpec.describe Gloss::Builder do
  it "expands macros" do
    output = Gloss::Builder.new(<<-GLOSS).run
class BaseController
  def render(**args) end
end
{% for controller_name in %w[Recipes Ingredients] %}
  class {{controller_name}}Controller < BaseController
    {% for method_name in %w[index create] %}
      def {{method_name}}
        {% if "{{method_name}}" == "create" %}
          status = 201
        {% else %}
          status = 200
        {% end %}
        render json: { msg: "hello from {{method_name}} in {{controller_name}}Controller" },
          status: status
      end
    {% end %}
  end
{% end %}
    GLOSS
    expect(output.lines.map(&:lstrip).join("\n")).to eq <<-RUBY.lines.map(&:lstrip).join("\n")
# frozen_string_literal: true
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
