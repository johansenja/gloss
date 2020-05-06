# Crystal Gem Template

A working* demo Ruby gem, written in Crystal.

## Usage:

```ruby
# Gemfile
gem "crystal_gem_template", git: "https://github.com/johansenja/crystal_gem_template.git"
```

then

`bundle install`

then

```ruby
# app.rb
require 'crystal_gem_template'

include CrystalGemTemplate

hello('world') # => "hello world"
```

then

`bundle exec ruby app.rb # => hello world`

Not a lot going on here, clearly, but this opens the door for performant code written in Crystal, then used in Ruby apps, going via Ruby's C API.

## Example as a functional gem:

[levenshtein_str](https://github.com/johansenja/levenshtein_str)

<hr>

\*note: tested and used on MacOS, so probably doesn't work on Linux! (yet)
