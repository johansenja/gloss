# Hrb

Hrb is a high-level programming language which compiles to ruby; its aims are on transparency,
efficiency, to enhance ruby's goal of developer happiness and productivity. Some of the features include:

- Type checking, via optional type annotations
- Compile-time macros
- Method overloading
- Enums
- Stripping out unused classes, modules and methods at compile time to lead to slimmer projects
- All pre-ruby 3.0 files are valid hrb files
- Other syntactic sugar

For anyone familiar with Crystal, some of these feature should be fairly faimiliar.

## Example:

```crystal
# src/lib/http_client.hrb

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

(with the assumption that all of the methods will be used within the rest of the app. Another
example:

```crystal
module MyLib
  module Utils
    def abc
      "abc"
    end

    def defg
      "defg"
    end

    def hijk
      "hijkl"
    end
  end

  class Other
    def foo
    end
  end
end

class Bar
  include MyLib::Utils

  def baz
    abc
  end
end

Bar.new.baz
```

will simplify to

```ruby
module MyLib
  module Utils
    def abc
      "abc"
    end
  end
end

class Bar
  include(MyLib::Utils)

  def baz
    abc
  end
end

Bar.new.baz
```

Hrb aims to provide the necessary tooling to avoid dynamically defining or invoking methods, classes
and modules, and to provide as much transparency and efficiency as possible in runtime code.

## Usage:

```ruby
# Gemfile
group :development do
  gem "hrb"
end
```

then

`bundle install`

then

`hrb init # create .hrb.yml config file`

then

`hrb build`
