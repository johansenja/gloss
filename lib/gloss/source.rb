  # frozen_string_literal: true

  ##### This file was generated by Gloss; any changes made here will be overwritten.
  ##### See src/ to make changes

module Gloss
  class Source < String
    def initialize(indent_level)
      @indent_level = indent_level
      super()
    end
    def write(*args)
      args.each() { |a|
        self.<<(a)
      }
self
    end
    def write_indnt(*args)
      write(*args.map() { |a|
"#{"  ".*(@indent_level)}#{a}"      })
    end
    def write_ln(*args)
      write_indnt(*args.map() { |a|
        a.strip
.<<("\n")
      })
    end
    def increment_indent()
      @indent_level += 1
    end
    def decrement_indent()
      @indent_level -= 1
    end
  end
end
