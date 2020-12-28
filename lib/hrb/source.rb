# frozen_string_literal: true

module Hrb
  class Source < String
    def initialize(indent_level)
      super()
      @indent_level = indent_level
    end

    def write(*args)
      args.each do |a|
        self << a
      end
    end

    def write_indnt(*args)
      write(*args.map { |a| "#{("  " * @indent_level)}#{a}" })
    end

    def write_ln(*args)
      write_indnt(*args.map { |a| a.strip << "\n" })
    end

    def increment_indent
      @indent_level += 1
    end

    def decrement_indent
      @indent_level -= 1
    end
  end
end
