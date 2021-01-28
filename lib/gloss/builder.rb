# frozen_string_literal: true

module Gloss
  class Builder
    attr_reader :tree

    def initialize(tree_hash, type_checker = nil)
      @indent_level = 0
      @inside_macro = false
      @eval_vars = false
      @current_scope = nil
      @tree = tree_hash
      @type_checker = type_checker
    end

    def run
      rb_output = visit_node(@tree)
      <<~RUBY
        #{"# frozen_string_literal: true\n" if Config.frozen_string_literals}
        ##### This file was generated by Gloss; any changes made here will be overwritten.
        ##### See #{Config.src_dir}/ to make changes

        #{rb_output}
      RUBY
    end

    def visit_node(node, scope = Scope.new)
      src = Source.new(@indent_level)
      case node[:type]
      when "ClassNode"
        class_name = visit_node(node[:name])
        current_namespace = @current_scope ? @current_scope.name.to_namespace : RBS::Namespace.root
        superclass_type = nil
        superclass_output = nil
        if node[:superclass]
          @eval_vars = true
          superclass_output = visit_node(node[:superclass])
          @eval_vars = false
          superclass_type = RBS::Parser.parse_type superclass_output
          if node.dig(:superclass, :type) == "Generic"
            superclass_output = superclass_output[/^[^\[]+/]
          end
        end

        src.write_ln "class #{class_name}#{" < #{superclass_output}" if superclass_output}"

        class_type = RBS::AST::Declarations::Class.new(
          name: RBS::TypeName.new(
            namespace: current_namespace,
            name: class_name.to_sym
          ),
          type_params: RBS::AST::Declarations::ModuleTypeParams.new, # responds to #add to add params
          super_class: superclass_type,
          members: Array.new,
          annotations: Array.new,
          location: node[:location],
          comment: node[:comment]
        )
        old_parent_scope = @current_scope
        @current_scope = class_type

        indented(src) { src.write_ln visit_node(node[:body]) if node[:body] }

        src.write_ln "end"

        @current_scope = old_parent_scope

        @current_scope.members << class_type if @current_scope

        if @type_checker
          @type_checker.top_level_decls[class_type.name.name] = class_type unless @current_scope
        end
      when "ModuleNode"
        module_name = visit_node node[:name]
        src.write_ln "module #{module_name}"

        current_namespace = @current_scope ? @current_scope.name.to_namespace : RBS::Namespace.root

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

        @current_scope.members << module_type if @current_scope

        if @type_checker
          @type_checker.top_level_decls[module_type.name.name] = module_type unless @current_scope
        end
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
                          location: node[:location]
                        )
                      else
                        RBS::Types::Bases::Any.new(location:node[:location])
                      end
        rp = (node[:positional_args] || EMPTY_ARRAY).filter { |a| !a[:value] }
        op = (node[:positional_args] || EMPTY_ARRAY).filter { |a| a[:value] }

        method_types = [
          RBS::MethodType.new(
            type_params: [],
            type: RBS::Types::Function.new(
              required_positionals: rp.map do |a|
                RBS::Types::Function::Param.new(
                  name: visit_node(a).to_sym,
                  type: RBS::Types::Bases::Any.new(location: a[:location])
                )
              end,
              optional_positionals: op.map do |a|
                RBS::Types::Function::Param.new(
                  name: visit_node(a).to_sym,
                  type: RBS::Types::Bases::Any.new(location: a[:location])
                )
              end,
              rest_positionals: (rpa = node[:rest_p_args]) ? RBS::Types::Function::Param.new(name: visit_node(rpa).to_sym, type: RBS::Types::Bases::Any.new(location: node[:location])) : nil,
              trailing_positionals: [],
              required_keywords: node[:req_kw_args] || EMPTY_HASH,
              optional_keywords: node[:opt_kw_args] || EMPTY_HASH,
              rest_keywords: node[:rest_kw_args] ?
                RBS::Types::Function::Param.new(
                  name: visit_node(node[:rest_kw_args]).to_sym,
                  type: RBS::Types::Bases::Any.new(location: node[:location])
                ) : nil,
              return_type: return_type
            ),
            block: node[:yield_arg_count] ?
              RBS::Types::Block.new(
                type: RBS::Types::Function.new(
                  required_positionals: [],
                  optional_positionals: [],
                  rest_positionals: nil,
                  trailing_positionals: [],
                  required_keywords: {},
                  optional_keywords: Hash.new,
                  rest_keywords: nil,
                  return_type: RBS::Types::Bases::Any.new(location: node[:location])
                ),
                required: !!(node[:block_arg] || node[:yield_arg_count])
              ) : nil,
            location: node[:location]
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
          @type_checker.type_env << method_definition if @type_checker # should be new class declaration for Object with method_definition as private method
        end

        indented(src) { src.write_ln visit_node(node[:body]) if node[:body] }

        src.write_ln "end"

      when "VisibilityModifier"

        src.write_ln "#{node[:visibility]} #{visit_node(node[:exp])}"

      when "CollectionNode"
        src.write(*node[:children].map { |a| visit_node(a, scope) })
      when "Call"
        obj = node[:object] ? "#{visit_node(node[:object], scope)}." : ""
        args = node[:args] || EMPTY_ARRAY
        args += node[:named_args] if node[:named_args]
        args = if !args.empty? || node[:block_arg]
                 "#{args.map { |a| visit_node(a, scope).strip }.reject(&:blank?).join(", ")}#{"&#{visit_node(node[:block_arg]).strip}" if node[:block_arg]}"
               else
                 nil
               end
        block = node[:block] ? " #{visit_node(node[:block])}" : nil
        has_parens = !!(node[:has_parentheses] || args || block)
        opening_delimiter = if has_parens
                              "("
                            else
                              nil
                            end
        call = "#{obj}#{node[:name]}#{opening_delimiter}#{args}#{")" if has_parens}#{block}"
        node.dig(:object, :type) == "Call" ? src.write(call) : src.write_ln(call)

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

        src.write("[", *node[:elements].map { |e| visit_node(e).strip }.join(", "), "]")
        src.write ".freeze" if node[:frozen]

      when "StringInterpolation"

        contents = node[:contents].inject(String.new) do |str, c|
          str << case c[:type]
                 when "LiteralNode"
                   c[:value][1...-1]
                 else
                   [%q|#{|, visit_node(c).strip, "}"].join
                 end
        end
        src.write '"', contents, '"'

      when "Path"

        src.write node[:value]

      when "Require"

        src.write_ln %(require "#{node[:value]}")

      when "Assign", "OpAssign"

        src.write_ln "#{visit_node(node[:target])} #{node[:op]}= #{visit_node(node[:value]).strip}"

      when "MultiAssign"

        src.write_ln "#{node[:targets].map{ |t| visit_node(t).strip }.join(", ")} = #{node[:values].map { |v| visit_node(v).strip }.join(", ")}"

      when "Var"

        if @eval_vars
          src.write scope[node[:name]]
        else
          src.write node[:name]
        end

      when "InstanceVar"

        src.write node[:name]

      when "GlobalVar"

        src.write node[:name]

      when "Arg"
        val = node[:external_name]
        if node[:keyword_arg]
          val += ":"
          val += " #{visit_node(node[:value])}" if node[:value]
        elsif node[:value]
          val += " = #{visit_node(node[:value])}"
        end

        src.write val

      when "UnaryExpr"

        src.write "#{node[:op]}#{visit_node(node[:value]).strip}"

      when "BinaryOp"

        src.write visit_node(node[:left]).strip, " #{node[:op]} ", visit_node(node[:right]).strip

      when "HashLiteral"

        contents = node[:elements].map do |k, v|
          key = case k
                when String
                  k.to_sym
                else
                  visit_node k
                end
          value = visit_node v
          "#{key.inspect} => #{value}"
        end

        src.write "{#{contents.join(",\n")}}"
        src.write ".freeze" if node[:frozen]

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
      when "Unless"
        src.write_ln "unless #{visit_node node[:condition]}"
        indented(src) { src.write_ln visit_node(node[:then]) }

        if node[:else]
          src.write_ln "else"
          indented(src) { src.write_ln visit_node(node[:else]) }
        end

        src.write_ln "end"
      when "Case"
        src.write "case"
        src.write " #{visit_node(node[:condition]).strip}\n" if node[:condition]
        indented(src) do
          node[:whens].each do |w|
            src.write_ln visit_node(w)
          end
          if node[:else]
            src.write_ln "else"
            indented(src) do
              src.write_ln visit_node(node[:else])
            end
          end
        end
        src.write_ln "end"
      when "When"
        src.write_ln "when #{node[:conditions].map { |n| visit_node(n) }.join(", ")}"

        indented(src) { src.write_ln(node[:body] ? visit_node(node[:body]) : "# no op") }
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
      when "TypeDeclaration"
        src.write_ln "# @type var #{visit_node(node[:var])}: #{visit_node(node[:declared_type])}"
        src.write_ln "#{visit_node(node[:var])} = #{visit_node(node[:value])}"
      when "ExceptionHandler"
        src.write_ln "begin"
        indented src do
          src.write_ln visit_node(node[:body])
        end
          node[:rescues]&.each do |r|
            src.write_ln "rescue #{r[:types].map { |n| visit_node n }.join(", ") if r[:types]}#{" => #{r[:name]}" if r[:name]}"
            indented(src) { src.write_ln visit_node(r[:body]) } if r[:body]
          end
          if node[:else]
            src.write_ln "else"
            indented(src) { src.write_ln visit_node(node[:else]) }
          end
          if node[:ensure]
            src.write_ln "ensure"
            indented(src) { src.write_ln visit_node(node[:ensure]) }
          end
        src.write_ln "end"
      when "Generic"
        src.write "#{visit_node(node[:name])}[#{node[:args].map { |a| visit_node a }.join(", ")}]"
      when "Proc"
        fn = node[:function]
        src.write "->#{render_args(fn)} { #{visit_node fn[:body]} }"
      when "Include"
        src.write_ln "include #{visit_node node[:name]}"
      when "Extend"
        src.write_ln "extend #{visit_node node[:name]}"
      when "RegexLiteral"
        contents = visit_node node[:value]
        src.write Regexp.new(contents.undump).inspect
      when "Union"
        types = node[:types]
        output = if types.length == 2 && types[1][:type] == "Path" && types[1]["value"] == nil
                  "#{visit_node(types[0])}?"
                 else
                   types.map { |t| visit_node(t) }.join(" | ")
                 end
        src.write output
      when "EmptyNode"
        # pass
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
      rp = node.fetch(:positional_args) { EMPTY_ARRAY }.filter { |a| !a[:value] }
      op = node.fetch(:positional_args) { EMPTY_ARRAY }.filter { |a| a[:value] }
      rkw = node.fetch(:req_kw_args) { EMPTY_HASH }
      okw = node.fetch(:opt_kw_args) { EMPTY_HASH }
      rest_p = node[:rest_p_args] ? visit_node(node[:rest_p_args]) : nil
      rest_kw = node[:rest_kw_args]
      return nil unless [rp, op, rkw, okw, rest_p, rest_kw].any? { |a| !a.nil? || !a.empty? }

      contents = [
        rp.map { |a| visit_node(a) },
        op.map { |a| "#{a[:name]} = #{visit_node(a[:value]).strip}" },
        rkw.map { |name, _| "#{name}:" },
        okw.map { |name, value| "#{name}: #{value}" },
        rest_p ? "*#{rest_p}" : "",
        rest_kw ? "**#{visit_node(rest_kw)}" : ""
      ].reject(&:empty?).flatten.join(", ")
      "(#{contents})"
    end
  end
end
