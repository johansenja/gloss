# frozen_string_literal: true

module Hrb
  class Builder
    attr_reader :tree

    def initialize(str)
      @indent_level = 0
      @inside_macro = false
      @eval_vars = false
      tree_json = Hrb.parse_buffer str
      begin
        @tree = JSON.parse tree_json, symbolize_names: true
      rescue JSON::ParserError
        raise Errors::ParserError, tree_json
      end
      @current_scope = nil
      @steep_target = Steep::Project::Target.new(
        name: "hrb",
        options: Steep::Project::Options.new,
        source_patterns: ["hrb"],
        ignore_patterns: [],
        signature_patterns: []
      )
      @top_level_decls = {}
    end

    def run
      rb_output = visit_node(@tree)

      unless check_types(rb_output)
        raise Errors::TypeError,
              @steep_target.errors.map { |e|
                case e
                when Steep::Errors::NoMethod
                  "Unknown method :#{e.method}, location: #{e.type.location.inspect}"
                when Steep::Errors::MethodBodyTypeMismatch
                  "Invalid method body type - expected: #{e.expected}, actual: #{e.actual}"
                when Steep::Errors::IncompatibleArguments
                  "Invalid argmuents - method type: #{e.method_type}, receiver type: #{e.receiver_type}"
                when Steep::Errors::ReturnTypeMismatch
                  "Invalid return type - expected: #{e.expected}, actual: #{e.actual}"
                when Steep::Errors::IncompatibleAssignment
                  "Invalid assignment - cannot assign #{e.rhs_type} to type #{e.lhs_type}"
                else
                  e.inspect
                end
              }.join("\n")
      end

      rb_output
    end

    def check_types(rb_str)
      env_loader = RBS::EnvironmentLoader.new
      env = RBS::Environment.from_loader(env_loader)

      @top_level_decls.each do |_, decl|
        env << decl
      end
      env = env.resolve_type_names

      @steep_target.instance_variable_set("@environment", env)
      @steep_target.add_source("hrb", rb_str)

      definition_builder = RBS::DefinitionBuilder.new(env: env)
      factory = Steep::AST::Types::Factory.new(builder: definition_builder)
      check = Steep::Subtyping::Check.new(factory: factory)
      validator = Steep::Signature::Validator.new(checker: check)
      validator.validate

      raise Errors::TypeValidationError, validator.each_error.to_a.join("\n") unless validator.no_error?

      @steep_target.run_type_check(env, check, Time.now)

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

        current_namespace = @current_scope ? @current_scope.name.to_namespace : RBS::Namespace.root
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
        old_parent_scope = @current_scope
        @current_scope = class_type

        indented(src) { src.write_ln visit_node(node[:body]) if node[:body] }

        src.write_ln "end"

        @current_scope = old_parent_scope
        @top_level_decls[class_type.name.name] = class_type unless @current_scope
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
        old_parent_scope = @current_scope
        @current_scope = module_type

        indented(src) { src.write_ln visit_node(node[:body]) if node[:body] }

        @current_scope = old_parent_scope
        @top_level_decls[module_type.name.name] = module_type unless @current_scope
        src.write_ln "end"
      when "DefNode"
        args = render_args(node)
        src.write_ln "def #{node[:name]}#{args}"

        return_type = if node[:return_type]
                        RBS::Types::ClassInstance.new(
                          name: RBS::TypeName.new(
                            name: eval(visit_node(node[:return_type])).to_s.to_sym,
                            namespace: RBS::Namespace.root
                          ),
                          args: [],
                          location: nil
                        )
                      else
                        RBS::Types::Bases::Any.new(location: nil)
                      end

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
              rest_keywords: node[:rest_kw_args] ?
                RBS::Types::Function::Param.new(
                  name: visit_node(node[:rest_kw_args]).to_sym,
                  type: RBS::Types::Bases::Any.new(location: nil)
                ) : nil,
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

        src.write "{ |#{node[:rp_args].map { |a| visit_node a }.join(", ")}|\n"

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
        indent_level = @indent_level
        @indent_level -= 1 unless indent_level.zero?
        expanded = eval(visit_node(expr)).map do |*a|
          locals = Hash[[var_names.join(%(", "))].zip(a)]
          locals.merge!(scope) if @inside_macro
          visit_node(body, locals)
        end.flatten
        @indent_level += 1 unless indent_level.zero?
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
      when "Return"
        val = node[:value] ? " #{visit_node(node[:value]).strip}" : nil
        src.write "return#{val}"
      when "EmptyNode"
        # pass
      when "TypeDeclaration"
        src.write_ln "# @type var #{visit_node(node[:var])}: #{visit_node(node[:declared_type])}"
        src.write_ln "#{visit_node(node[:var])} = #{visit_node(node[:value])}"
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

    def render_args(node)
      rp = node[:rp_args] || EMPTY_ARRAY
      op = node[:op_args] || EMPTY_ARRAY
      rkw = node[:req_kw_args] || EMPTY_HASH
      okw = node[:opt_kw_args] || EMPTY_HASH
      rest_p = node[:rest_p_args]
      rest_kw = node[:rest_kw_args]
      return nil unless [rp, op, rkw, okw, rest_p, rest_kw].any? { |a| !a.nil? || !a.empty? }

      contents = [
        rp.map { |a| visit_node(a) },
        op.map { |pos| "#{pos.name} = #{value}" },
        rkw.map { |name, _| "#{name}:" },
        okw.map { |name, _| "#{name}: #{value}" },
        rest_p ? "*#{rest_p}" : "",
        rest_kw ? "**#{visit_node(rest_kw)}" : ""
      ].reject(&:empty?).flatten.join(", ")
      "(#{contents})"
    end
  end
end
