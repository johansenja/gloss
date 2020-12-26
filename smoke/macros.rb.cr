class BaseController
  def render(**args); end
end

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
