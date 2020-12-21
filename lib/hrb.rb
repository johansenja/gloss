# frozen_string_literal: true

require "hrb/version"
require "hrb.bundle"
require "json"
require "fast_blank"

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
    write_indnt(*args)
    write "\n"
  end
end

module Hrb
  class Program
    attr_reader :tree

    def initialize(str)
      @indent_level = 0
      tree_json = Hrb.parse_buffer str
      if tree_json
        @tree = JSON.parse tree_json, symbolize_names: true
      else
        abort
      end
    end

    def output
      puts visit_node(@tree)
    end

    def visit_node(node)
      src = Source.new(@indent_level)
      case node[:type]
      when "ClassNode"
        class_name = visit_node(node[:name])
        superclass = node[:superclass] ? visit_node(node[:superclass]) : nil

        src.write_ln "class #{class_name}#{" < #{superclass}" if superclass}"

        increment_indent

        src.write_ln visit_node(node[:body]) if node[:body]

        decrement_indent

        src.write_ln "end"
      when "ModuleNode"
        module_name = visit_node node[:name]
        src.write_ln "module #{module_name}"

        increment_indent

        src.write_ln visit_node(node[:body]) if node[:body]

        decrement_indent

        src.write_ln "end"
      when "DefNode"
        args = node[:args].empty? ? nil : "(#{node[:args].map { |a| visit_node(a) }.join(", ")})"
        src.write_ln "def #{node[:name]}#{args}"

        increment_indent

        src.write_ln visit_node(node[:body]) if node[:body]

        decrement_indent

        src.write_ln "end"
      when "CollectionNode"
        src.write_ln(*node[:children].map { |a| visit_node(a) })
      when "Call"
        obj = node[:object] ? "#{visit_node(node[:object])}." : ""
        args = node[:args]
        args = if args && !args.empty?
                 "(#{node[:args].map { |a| visit_node(a) }.reject(&:blank?).join(", ")})"
               else
                 nil
               end
        src.write_indnt "#{obj}#{node[:name]}#{args}"
      when "LiteralNode"

        src.write node[:value]

      when "Path"

        src.write node[:value]

      when "Require"

        src.write_ln %(require "#{node[:value]}")

      when "Assign"

        src.write_ln "#{visit_node(node[:target])} = #{visit_node(node[:value])}"

      when "Var", "InstanceVar"

        src.write node[:name]

      when "EmptyNode"
        # pass
        src = ""
      when "Arg"

        src.write node[:name]

      when "HashLiteral"

        src.write "{}"

      when "Enum"
        src.write_ln "module #{node[:name]}"
        node[:members].each_with_index do |m, i|
          increment_indent

          src.write_ln(visit_node(m) + (!m[:value] ? " = #{i}" : ""))

          decrement_indent
        end
        src.write_ln "end"
      when "If"
        src.write_ln "(if #{visit_node(node[:condition])}"

        increment_indent

        src.write_ln visit_node(node[:then])

        decrement_indent

        if node[:else]
          src.write_ln "else"

          increment_indent

          src.write_ln visit_node(node[:else])

          decrement_indent
        end

        src.write_ln "end)"
      when "TypeDeclaration"
        # pass for now
        src = ""
      else
        raise "Not implemented: #{node[:type]}"
      end

      src
    end

    def increment_indent
      @indent_level += 1
    end

    def decrement_indent
      @indent_level -= 1
    end
  end
end
