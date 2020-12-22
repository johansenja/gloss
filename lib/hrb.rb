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
    write_indnt(*args.map { |a| a.strip << "\n" })
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
                 "(#{node[:args].map { |a| visit_node(a).strip }.reject(&:blank?).join(", ")})"
               else
                 nil
               end
        src.write_ln "#{obj}#{node[:name]}#{args}"
      when "LiteralNode"

        src.write node[:value]

      when "StringInterpolation"

        contents = node[:contents].inject(String.new) do |str, c|
          str << case c[:type]
                 when "LiteralNode"
                   c[:value][1...-1]
                 else
                   "\#{#{visit_node(c).strip}}"
                 end
        end
        src.write '"', contents, '"'

      when "Path"

        src.write node[:value]

      when "Require"

        src.write_ln %(require "#{node[:value]}")

      when "Assign", "OpAssign"

        src.write_ln "#{visit_node(node[:target])} #{node[:op]}= #{visit_node(node[:value]).strip}"

      when "Var", "InstanceVar"

        src.write node[:name]

      when "EmptyNode"
        # pass
        src = ""
      when "Arg"

        src.write node[:name]

      when "UnaryExpr"

        src.write "#{node[:op]}#{visit_node(node[:value]).strip}"

      when "BinaryOp"

        src.write visit_node(node[:left]).strip, " #{node[:op]} ", visit_node(node[:right]).strip

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
        src.write_ln "(if #{visit_node(node[:condition]).strip}"

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
      when "Case"
        src.write "case"
        src.write " #{visit_node(node[:condition]).strip}\n" if node[:condition]
        increment_indent
        node[:whens].each do |w|
          src.write_ln visit_node(w)
        end
        decrement_indent
        src.write_ln "end"
      when "When"
        src.write_ln "when #{node[:conditions].map { |n| visit_node(n) }.join(", ")}"
        src.write_ln visit_node(node[:body])
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
