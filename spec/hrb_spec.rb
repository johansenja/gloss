require "hrb"

RSpec.describe Hrb do
  it "expands macros" do
    output = Hrb::Program.new(<<-HRB).output
{% for controller_name in %w[Recipes Ingredients] %}
  class {{controller_name}}Controller < BaseController
    {% for method_name in %w[index new create update destroy] %}
      def {{method_name}}
        {% if "{{method_name}}" == "create" %}
          status = 201
        {% elsif "{{method_name}}" == "destroy" %}
          status = 204
        {% else %}
          status = 200
        {% end %}
        render json: { msg: "hello from {{method_name}} in {{controller_name}}Controller" },
          status: status
      end
    {% end %}
  end
{% end %}
    HRB
    expect(output).to eq <<-RUBY

  class RecipesController < BaseController

      def index
        status = 200

        render json: { msg: "hello from index in RecipesController" },
          status: status
      end

      def new
        status = 200

        render json: { msg: "hello from new in RecipesController" },
          status: status
      end

      def create
        status = 200

        render json: { msg: "hello from create in RecipesController" },
          status: status
      end

      def update
        status = 200

        render json: { msg: "hello from update in RecipesController" },
          status: status
      end

      def destroy
        status = 200

        render json: { msg: "hello from destroy in RecipesController" },
          status: status
      end

      def index
        status = 200

        render json: { msg: "hello from index in RecipesController" },
          status: status
      end

      def new
        status = 200

        render json: { msg: "hello from new in RecipesController" },
          status: status
      end

      def create
        status = 200

        render json: { msg: "hello from create in RecipesController" },
          status: status
      end

      def update
        status = 200

        render json: { msg: "hello from update in RecipesController" },
          status: status
      end

      def destroy
        status = 200

        render json: { msg: "hello from destroy in RecipesController" },
          status: status
      end

  end

  class IngredientsController < BaseController

      def index
        status = 200

        render json: { msg: "hello from index in IngredientsController" },
          status: status
      end

      def new
        status = 200

        render json: { msg: "hello from new in IngredientsController" },
          status: status
      end

      def create
        status = 200

        render json: { msg: "hello from create in IngredientsController" },
          status: status
      end

      def update
        status = 200

        render json: { msg: "hello from update in IngredientsController" },
          status: status
      end

      def destroy
        status = 200

        render json: { msg: "hello from destroy in IngredientsController" },
          status: status
      end

      def index
        status = 200

        render json: { msg: "hello from index in IngredientsController" },
          status: status
      end

      def new
        status = 200

        render json: { msg: "hello from new in IngredientsController" },
          status: status
      end

      def create
        status = 200

        render json: { msg: "hello from create in IngredientsController" },
          status: status
      end

      def update
        status = 200

        render json: { msg: "hello from update in IngredientsController" },
          status: status
      end

      def destroy
        status = 200

        render json: { msg: "hello from destroy in IngredientsController" },
          status: status
      end

  end

  class RecipesController < BaseController

      def index
        status = 200

        render json: { msg: "hello from index in RecipesController" },
          status: status
      end

      def new
        status = 200

        render json: { msg: "hello from new in RecipesController" },
          status: status
      end

      def create
        status = 200

        render json: { msg: "hello from create in RecipesController" },
          status: status
      end

      def update
        status = 200

        render json: { msg: "hello from update in RecipesController" },
          status: status
      end

      def destroy
        status = 200

        render json: { msg: "hello from destroy in RecipesController" },
          status: status
      end

      def index
        status = 200

        render json: { msg: "hello from index in RecipesController" },
          status: status
      end

      def new
        status = 200

        render json: { msg: "hello from new in RecipesController" },
          status: status
      end

      def create
        status = 200

        render json: { msg: "hello from create in RecipesController" },
          status: status
      end

      def update
        status = 200

        render json: { msg: "hello from update in RecipesController" },
          status: status
      end

      def destroy
        status = 200

        render json: { msg: "hello from destroy in RecipesController" },
          status: status
      end

  end

  class IngredientsController < BaseController

      def index
        status = 200

        render json: { msg: "hello from index in IngredientsController" },
          status: status
      end

      def new
        status = 200

        render json: { msg: "hello from new in IngredientsController" },
          status: status
      end

      def create
        status = 200

        render json: { msg: "hello from create in IngredientsController" },
          status: status
      end

      def update
        status = 200

        render json: { msg: "hello from update in IngredientsController" },
          status: status
      end

      def destroy
        status = 200

        render json: { msg: "hello from destroy in IngredientsController" },
          status: status
      end

      def index
        status = 200

        render json: { msg: "hello from index in IngredientsController" },
          status: status
      end

      def new
        status = 200

        render json: { msg: "hello from new in IngredientsController" },
          status: status
      end

      def create
        status = 200

        render json: { msg: "hello from create in IngredientsController" },
          status: status
      end

      def update
        status = 200

        render json: { msg: "hello from update in IngredientsController" },
          status: status
      end

      def destroy
        status = 200

        render json: { msg: "hello from destroy in IngredientsController" },
          status: status
      end

  end
    RUBY
  end
end
