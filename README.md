# Gloss

[Gloss](https://en.wikipedia.org/wiki/Gloss_(annotation)) is a high-level programming language based on [Ruby](https://github.com/ruby/ruby) and [Crystal](https://github.com/crystal-lang/crystal), which compiles to ruby; its aims are on transparency,
efficiency, and to enhance ruby's goal of developer happiness and productivity. Some of the features include:

- Type checking, via optional type annotations
- Compile-time macros
- Enums
- Tuples and Named Tuples
- All ruby files are valid gloss files (a small exceptions for now; workarounds are mostly available)
- Other syntactic sugar

Coming soon:
- abstract classes

Maybe on the roadmap:
- Method overloading

## Examples:

#### Type checking:

```crystal
class HelloWorld
  def perform : String
    str = "Hello world"
    puts str
    str
  end
end

result : String = HelloWorld.perform # Error => No singleton method `perform` for HelloWorld
result : Integer = HelloWorld.new.perform # Incompatible assignment => can't assign string to integer
result : String = HelloWorld.new.perform # OK
result.length # OK => 11
```

#### Macros:

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

#### Enums:

```crystal
class Language
  enum Lang
    R = "Ruby"
    C = "Crystal"
    TS = "TypeScript"
    P = "Python"
  end
  
  def favourite_language(language : Lang)
    puts "my favourite language is #{language}"
  end
end
```

#### Tuples + Named Tuples:

Currently, named tuples can only have symbols as keys, and are distinguished from hashes by the use of the post ruby-1.9 syntax `key: value` (for named tuple) vs `:key => value` (for hash) - see example below. **This is liable to change to ensure maximum compatibility with existing ruby code**.

```crystal
tuple = {"hello", "world"}
array = ["hello", "world"]
named_tuple = { hello: "world" }
hash = { :hello => "world" }

array << "!" # OK
tuple << "!" # Error
hash["key"] = "value" # OK
named_tuple["key"] = "value" # Error
```

#### Other syntactic suger:

```crystal
class MyClass
  def initialize(@var1, @@var2)
  end
end
```

compiles to

```ruby
class MyClass
  def initialize(var1, var2)
    @var1 = var1
    @var2 = var2
  end
end
```

```crystal
str = "abc"
case str
when "a"
  "only a"
when .start_with?("a")
  "starts with a"
when String
  "definitely a string"
end
```

compiles to

```ruby
str = "abc"
case str
when "a"
  "only a"
when ->(x) { x.start_with?("a") }
  "starts with a"
when String
  "any other string"
end
```

#### Abstract classes (roadmap)

```crystal
abstract class BaseClass
  attr_reader :var
  
  def initialize(@var); end
end

class Child < BaseClass
  def what_is_var
    "var is #{var}"
  end
end

BaseClass.new(123) # Error - can't instantiate abstract class
Child.new(123).what_is_var # Ok - "var is 123"
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
