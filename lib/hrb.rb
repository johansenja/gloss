# frozen_string_literal: true

require "hrb/version"
require "hrb.bundle"
require "json"
require "fast_blank"
require "typeprof"

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

class Scope < Hash
  def [](k)
    fetch(k) { raise "Undefined expression for current scope: #{k}" }
  end
end

module Hrb
  class Program
    attr_reader :tree

    def initialize(str)
      @indent_level = 0
      @inside_macro = false
      @eval_vars = false
      tree_json = Hrb.parse_buffer str
      if tree_json
        @tree = JSON.parse tree_json, symbolize_names: true
      else
        abort
      end
      @type_defs = {
        classes: {
          ["Logger"] => {
            type_params: nil,
            superclass: [],
            members: {
              modules: {include: [], extend: [], prepend: []},
              methods: {},
              attr_methods: {},
              ivars: {},
              cvars: {},
              rbs_sources: {},
            }
          }
        },
        constants: {},
        globals: {},
      }
    end

    def output
      rb_output = visit_node(@tree)
      profile_types rb_output
      rb_output
    end

    def profile_types(rb_output)
      # TypeProf does something similar - a little weird
      TypeProf.const_set("Config", TypeProf::ConfigData.new(rb_files: [[rb_output, "hrb"]], verbose: 1))
      scratch = TypeProf::Scratch.new
      TypeProf::Builtin.setup_initial_global_env(scratch)
      TypeProf::Import.new(scratch, @type_defs).import(true)

      prologue_ctx = TypeProf::Context.new(nil, nil, nil)
      prologue_ep = TypeProf::ExecutionPoint.new(prologue_ctx, -1, nil)
      prologue_env = TypeProf::Env.new(
        TypeProf::StaticEnv.new(TypeProf::Type.bot, TypeProf::Type.nil, false, true),
        [],
        [],
        TypeProf::Utils::HashWrapper.new({})
      )
      TypeProf::Config.rb_files.each do |rb|
        iseq = TypeProf::ISeq.compile_str(*rb)
        ep, env = TypeProf.starting_state(iseq)
        scratch.merge_env(ep, env)
        scratch.add_callsite!(ep.ctx, prologue_ep, prologue_env) { |_ty, _ep| }
      end

      begin
        result = scratch.type_profile
        scratch.report(result, STDOUT)
      rescue TypeProf::TypeProfError => e
        e.report($stdout)
      end
    end

    def visit_node(node, scope = Scope.new)
      src = Source.new(@indent_level)
      case node[:type]
      when "ClassNode"
        class_name = visit_node(node[:name])
        superclass = node[:superclass] ? visit_node(node[:superclass]) : nil

        src.write_ln "class #{class_name}#{" < #{superclass}" if superclass}"

        indented(src) { src.write_ln visit_node(node[:body]) if node[:body] }

        src.write_ln "end"
        @type_defs[:classes][class_name.split("::")] = {
          type_params: nil, # for now
          superclass: [superclass, []], # [] = type args
          members: {
            modules: { include: [], extend: [], prepend: [] },
            methods: {},
            attr_methods: {},
            ivars: {},
            cvars: {},
            rbs_sources: {}, # a formality
          },
        }
      when "ModuleNode"
        module_name = visit_node node[:name]
        src.write_ln "module #{module_name}"

        indented(src) { src.write_ln visit_node(node[:body]) if node[:body] }

        src.write_ln "end"
      when "DefNode"
        args = node[:args].empty? ? nil : "(#{node[:args].map { |a| visit_node(a) }.join(", ")})"
        src.write_ln "def #{node[:name]}#{args}"

        indented(src) { src.write_ln visit_node(node[:body]) if node[:body] }

        src.write_ln "end"
      when "CollectionNode"
        src.write(*node[:children].map { |a| visit_node(a, scope) })
      when "Call"
        obj = node[:object] ? "#{visit_node(node[:object], scope)}." : ""
        args = node[:args]
        args = if args && !args.empty?
                 "(#{node[:args].map { |a| visit_node(a, scope).strip }.reject(&:blank?).join(", ")})"
               else
                 nil
               end
        block = node[:block] ? " #{visit_node(node[:block])}" : nil
        src.write_ln "#{obj}#{node[:name]}#{args}#{block}"

      when "Block"

        src.write "{ |#{node[:args].map { |a| visit_node a }.join(", ")}|\n"

        indented(src) { src.write visit_node(node[:body]) }

        src.write_ln "}"

      when "RangeLiteral"
        dots = node[:exclusive] ? "..." : ".."

        # parentheses help the compatibility with precendence of operators in some situations
        # eg. (1..3).cover? 2 vs. 1..3.cover? 2
        src.write "(", visit_node(node[:from]), dots, visit_node(node[:to]), ")"

      when "LiteralNode"

        src.write node[:value]

      when "ArrayLiteral"

        src.write("[", *node[:elements].map { |e| visit_node e }.join(", "), "]")

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

      when "Var"

        if @eval_vars
          src.write scope[node[:name]]
        else
          src.write node[:name]
        end

      when "InstanceVar"

        src.write node[:name]

      when "Arg"

        src.write node[:external_name]

      when "UnaryExpr"

        src.write "#{node[:op]}#{visit_node(node[:value]).strip}"

      when "BinaryOp"

        src.write visit_node(node[:left]).strip, " #{node[:op]} ", visit_node(node[:right]).strip

      when "HashLiteral"

        src.write "{}"

      when "Enum"
        src.write_ln "module #{node[:name]}"
        node[:members].each_with_index do |m, i|
          indented(src) { src.write_ln(visit_node(m) + (!m[:value] ? " = #{i}" : "")) }
        end
        src.write_ln "end"
      when "If"
        src.write_ln "(if #{visit_node(node[:condition]).strip}"

        indented(src) { src.write_ln visit_node(node[:then]) }

        if node[:else]
          src.write_ln "else"
          indented(src) { src.write_ln visit_node(node[:else]) }
        end

        src.write_ln "end)"
      when "Case"
        src.write "case"
        src.write " #{visit_node(node[:condition]).strip}\n" if node[:condition]
        indented(src) do
          node[:whens].each do |w|
            src.write_ln visit_node(w)
          end
        end
        src.write_ln "end"
      when "When"
        src.write_ln "when #{node[:conditions].map { |n| visit_node(n) }.join(", ")}"

        indented(src) { src.write_ln visit_node(node[:body]) }
      when "MacroFor"
        vars, expr, body = node[:vars], node[:expr], node[:body]
        var_names = vars.map { |v| visit_node v }
        @inside_macro = true
        expanded = eval(<<~HRB).flatten
          #{visit_node(expr)}.map do |*args|
            locals = Hash[["#{var_names.join(%{", "})}"].zip(args)]
            locals.merge!(scope) if @inside_macro
            evaluate_macro_body(src, body, locals)
          end
        HRB
        src.write(*expanded)
        @inside_macro = false
      when "MacroLiteral"
        src.write node[:value]
      when "MacroExpression"
        if node[:output]
          expr = visit_node node[:expr], scope
          val = scope[expr]
          src.write val
        end
      when "MacroIf"
        if evaluate_macro_condition(node[:condition], scope)
          src.write_ln visit_node(node[:then], scope) if node[:then]
        else
          src.write_ln visit_node(node[:else], scope) if node[:else]
        end
      when "EmptyNode"
        # pass
      when "TypeDeclaration"
        # pass for now
      else
        raise "Not implemented: #{node[:type]}"
      end

      src
    end

    private

    def evaluate_macro_condition(condition_node, scope)
      @eval_vars = true
      eval(visit_node(condition_node, scope))
      @eval_vars = false
    end

    def evaluate_macro_body(src, body, locals)
      src.write visit_node(body, locals)
    end

    def indented(src)
      increment_indent(src)
      yield
      decrement_indent(src)
    end

    def increment_indent(src)
      @indent_level += 1
      src.increment_indent
    end

    def decrement_indent(src)
      @indent_level -= 1
      src.decrement_indent
    end
  end
end
