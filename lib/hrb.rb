# frozen_string_literal: true

require "hrb/version"
require "hrb.bundle"
require "json"
require "fast_blank"
require "rbs"
require "steep"
require "pry-byebug"

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
      env_loader = RBS::EnvironmentLoader.new
      @type_env = RBS::Environment.from_loader(env_loader).resolve_type_names
      @current_scope = nil
      @steep_target = Steep::Project::Target.new(name: "hrb", options: Steep::Project::Options.new, source_patterns: ["hrb"], ignore_patterns: [], signature_patterns: [])
    end

    def output
      rb_output = visit_node(@tree)

      unless check_types(rb_output)
        raise "Type error: #{@steep_target.errors}"
      end

      rb_output
    end

    def check_types(rb_str)
      @type_env = @type_env.resolve_type_names
      @steep_target.instance_variable_set("@environment", @type_envs)
      @steep_target.add_source("hrb", rb_str)
      definition_builder = RBS::DefinitionBuilder.new(env: @type_env)
      factory = Steep::AST::Types::Factory.new(builder: definition_builder)
      check = Steep::Subtyping::Check.new(factory: factory)
      @steep_target.run_type_check(@type_env, check, Time.now)

      @steep_target.status.is_a?(Steep::Project::Target::TypeCheckStatus) &&
        @steep_target.no_error? &&
        @steep_target.errors.empty?
    end

    def visit_node(node, scope = Scope.new)
      src = Source.new(@indent_level)
      case node[:type]
      when "ClassNode"
        class_name = visit_node(node[:name])
        superclass = if node[:superclass]
                       @eval_vars = true
                       visit_node(node[:superclass])
                       @eval_vars = false
                     else
                       nil
                     end

        src.write_ln "class #{class_name}#{" < #{superclass}" if superclass}"

        current_namespace = RBS::Namespace.root # RBS::Namespace.new(path: [], absolute: false)
        class_type = RBS::AST::Declarations::Class.new(
          name: RBS::TypeName.new(
            namespace: current_namespace,
            name: class_name.to_sym
          ),
          type_params: RBS::AST::Declarations::ModuleTypeParams.new, # responds to #add to add params
          super_class: superclass ? RBS::AST::Declarations::Class::Super.new(name: RBS::Typename.new(name: super_class.to_sym, namespace: RBS::Namespace.root), args: [], location: nil) : nil,
          members: [],
          annotations: [],
          location: node[:location],
          comment: node[:comment]
        )
        parent_scope = @current_scope
        @current_scope = class_type

        indented(src) { src.write_ln visit_node(node[:body]) if node[:body] }

        src.write_ln "end"

        @current_scope = parent_scope
        @type_env.insert_decl class_type, outer: [], namespace: current_namespace
      when "ModuleNode"
        module_name = visit_node node[:name]
        src.write_ln "module #{module_name}"

        current_namespace = RBS::Namespace.root # RBS::Namespace.new(path: [module_name.to_sym], absolute: false)

        module_type = RBS::AST::Declarations::Module.new(
          name: RBS::TypeName.new(
            namespace: current_namespace,
            name: module_name.to_sym
          ),
          type_params: RBS::AST::Declarations::ModuleTypeParams.new, # responds to #add to add params
          self_types: [],
          members: [],
          annotations: [],
          location: node[:location],
          comment: node[:comment]
        )
        parent_scope = @current_scope
        @current_scope = module_type

        indented(src) { src.write_ln visit_node(node[:body]) if node[:body] }

        @current_scope = parent_scope
        @type_env.insert_decl module_type, namespace: current_namespace, outer: []
        src.write_ln "end"
      when "DefNode"
        args = node[:args].empty? ? nil : "(#{node[:args].map { |a| visit_node(a) }.join(", ")})"
        src.write_ln "def #{node[:name]}#{args}"

        return_type = RBS::Types::ClassSingleton.new(
          name: RBS::TypeName.new(
            name: eval(visit_node(node[:return_type])).to_s.to_sym,
            namespace: RBS::Namespace.root
          ),
          location: nil
        )

        method_types = [
          RBS::MethodType.new(
            type_params: [],
            type: RBS::Types::Function.new(
              required_positionals: [],
              optional_positionals: [],
              rest_positionals: nil,
              trailing_positionals: [],
              required_keywords: {},
              optional_keywords: {},
              rest_keywords: nil,
              return_type: return_type
            ),
            block: nil,
            location: nil
          )
        ]
        method_definition = RBS::AST::Members::MethodDefinition.new(
          name: node[:name].to_sym,
          kind: :instance,
          types: method_types,
          annotations: [],
          location: node[:location],
          comment: node[:comment],
          overload: false
        )

        if @current_scope
          @current_scope.members << method_definition
        else
          @type_env << method_definition # should be new class declaration for Object with method_definition as private method
        end

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
