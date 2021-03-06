# Gloss
[![Gem Version](https://badge.fury.io/rb/gloss.svg)](https://rubygems.org/gems/gloss)
[![Ruby Specs](https://github.com/johansenja/gloss/workflows/Ruby%20Specs/badge.svg)](https://github.com/johansenja/gloss/actions?query=workflow%3A%22Ruby+Specs%22)
[![Crystal Specs](https://github.com/johansenja/gloss/workflows/Crystal%20Specs/badge.svg)](https://github.com/johansenja/gloss/actions?query=workflow%3A%22Crystal+Specs%22)
[![Total Downloads](http://ruby-gem-downloads-badge.herokuapp.com/gloss?type=total&color=green&metric=true&label=downloads%20(total)&total_label=)](https://rubygems.org/gems/gloss)
[![Current Version](http://ruby-gem-downloads-badge.herokuapp.com/gloss?color=green&label=downloads%20(current%20version)&metric=true)](https://rubygems.org/gems/gloss)

[Gloss](https://en.wikipedia.org/wiki/Gloss_(annotation)) is a high-level programming language based on [Ruby](https://github.com/ruby/ruby) and [Crystal](https://github.com/crystal-lang/crystal), which compiles to ruby; its aims are on transparency,
efficiency, and to enhance ruby's goal of developer happiness and productivity.

### Current features

- Type checking, via optional type annotations
- Compile-time macros
- Enums
- Tuples and Named Tuples
- All ruby files are valid gloss files (a small exceptions for now; workarounds are mostly available)
- Other syntactic sugar

### Current Status

This project is at a stage where the core non-crystal parts are written in Gloss and compile to ruby (essentially self-hosting), albeit with the type checking being fairly loose. However the project is still in the very early stages; with (as of yet) no Linux support nor error handling (see roadmap below). Use at your own discretion!

### Approx. roadmap:

- Improve error handling and logging (currently almost non-existant)
- Address Linux compatibility (currently more or less non-existant)
- Implement different strictnesses of type checking
- Metaprogramming helpers/safety:*
  - Abstract classes and methods
  - Method lookup/existence checking at compile time
  - Method overloading

#### Related items:

- Rails helpers; probably some time away*
- Editor plugins/syntax highlighting/langserver; probably some time away*

*__Dependent on popularity__

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
# src/lib/http_client.gl

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

Language.new.favourite_language(Language::Lang::R)
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

`mkdir src && echo "puts 'hello world'" > src/hello_world.gl`

then

`gloss build`

then

`ruby ./hello_world.rb`
