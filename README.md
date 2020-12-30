# Gloss

Gloss is a high-level programming language which compiles to ruby; its aims are on transparency,
efficiency, to enhance ruby's goal of developer happiness and productivity. It is hihgly inspired by
Crystal; some of the features include:

- Type checking, via optional type annotations
- Compile-time macros
- Enums
- Tuples and NamedTuples (think immutable arrays and hashes)
- All pre-ruby 3.0 files are valid gloss files
- Other syntactic sugar

Coming soon:
- Method overloading
- abstract classes

## Example:

```crystal
# src/lib/http_client.gloss

class HttpClient

  @base_url : String

  def initialize(@base_url); end

  {% for verb in %w[get post put patch delete] %}
    def {{verb}}(path : String, headers : Hash[untyped, untyped]?, body : Hash[untyped, untyped]?)
      {% if verb == "get" %}
        warn "ignoring body #{body} for get request" unless body.nil?
        # business logic
      {% elsif %w[post patch put].include? verb %}
        body : String = body.to_json
        # business logic
      {% else %}
        # delete request business logic
      {% end %}
    end
  {% end %}
end
```

compiles to:

```ruby
# lib/http_client.rb
# frozen_string_literal: true

class HttpClient
  # @type ivar base_url: String

  def initialize(base_url)
    @base_url = base_url
  end

  def get(path, headers, body)
    warn "ignoring body #{body} for get request" unless body.nil?
    # business logic
  end

  def post(path, headers, body)
    # @type var body: String
    body = body.to_json
    # business logic
  end

  def put(path, headers, body)
    # @type var body: String
    body = body.to_json
    # business logic
  end

  def patch(path, headers, body)
    # @type var body: String
    body = body.to_json
    # business logic
  end

  def delete(path, headers, body)
    # delete request business logic
  end
end
```

## Usage:

```ruby
# Gemfile
group :development do
  gem "gloss"
end
```

then

`bundle install`

then

`gloss init # create .gloss.yml config file`

then

`gloss build`
