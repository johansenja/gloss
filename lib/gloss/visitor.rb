  # frozen_string_literal: true

  ##### This file was generated by Gloss; any changes made here will be overwritten.
  ##### See src/ to make changes

module Gloss
  class Visitor
    FILE_HEADER = "  #{(if Config.frozen_string_literals
      "# frozen_string_literal: true\n"
    end)}\n  ##### This file was generated by Gloss; any changes made here will be overwritten.\n  ##### See #{Config.src_dir}/ to make changes"
    attr_reader(:"tree")
    def initialize(tree_hash, type_checker = nil, on_new_file_referenced = nil)
      @on_new_file_referenced = on_new_file_referenced
      @indent_level = 0
      @inside_macro = false
      @eval_vars = false
      @current_scope = nil
      @tree = tree_hash
      @type_checker = type_checker
      @after_module_function = false
    end
    def run()
      rb_output = visit_node(@tree)
      Utils.with_file_header(rb_output)
    end
    def visit_node(node, scope = Scope.new)
      src = Source.new(@indent_level)
case node.[](:"type")
        when "ClassNode"
          class_name = visit_node(node.[](:"name"))
          current_namespace = (if @current_scope
            @current_scope.name
.to_namespace
          else
            RBS::Namespace.root
          end)
          superclass_type = nil
          superclass_output = ""
          (if node.[](:"superclass")
            @eval_vars = true
            superclass_output = visit_node(node.[](:"superclass"))
            @eval_vars = false
            args = Array.new
            (if node.dig(:"superclass", :"type")
.==("Generic")
              superclass_output = superclass_output.[](/^[^\[]+/) || superclass_output
              args = node.dig(:"superclass", :"args")
.map() { |n|
                RBS::Parser.parse_type(visit_node(n))
              }
            end)
            class_name_index = superclass_output.index(/[^(?:::)]+\z/) || 0
            namespace = superclass_output.[](0, class_name_index)
            superclass_name = superclass_output.[](/[^(?:::)]+\z/) || superclass_output
            superclass_type = RBS::AST::Declarations::Class::Super.new(name:             RBS::TypeName.new(namespace:             method(:"Namespace")
.call(namespace), name:             superclass_name.to_sym), args: args, location:             build_location(node))
          end)
          src.write_ln("class #{class_name}#{unless           superclass_output.blank?
            " < #{superclass_output}"
          end}")
          class_type = RBS::AST::Declarations::Class.new(name:           RBS::TypeName.new(namespace: current_namespace, name:           class_name.to_sym), type_params:           RBS::AST::Declarations::ModuleTypeParams.new, super_class: superclass_type, members:           Array.new, annotations:           Array.new, location:           build_location(node), comment:           node.[](:"comment"))
          old_parent_scope = @current_scope
          @current_scope = class_type
          indented(src) { ||
            (if node.[](:"body")
              src.write_ln(visit_node(node.[](:"body")))
            end)
          }
          src.write_ln("end")
          @current_scope = old_parent_scope
          (if @current_scope
            @current_scope.members
.<<(class_type)
          end)
          (if @type_checker && !@current_scope
            @type_checker.top_level_decls
.add(class_type)
          end)
        when "ModuleNode"
          existing_module_function_state = @after_module_function.dup
          @after_module_function = false
          module_name = visit_node(node.[](:"name"))
          src.write_ln("module #{module_name}")
          current_namespace = (if @current_scope
            @current_scope.name
.to_namespace
          else
            RBS::Namespace.root
          end)
          module_type = RBS::AST::Declarations::Module.new(name:           RBS::TypeName.new(namespace: current_namespace, name:           module_name.to_sym), type_params:           RBS::AST::Declarations::ModuleTypeParams.new, self_types:           Array.new, members:           Array.new, annotations:           Array.new, location:           build_location(node), comment:           node.[](:"comment"))
          old_parent_scope = @current_scope
          @current_scope = module_type
          indented(src) { ||
            (if node.[](:"body")
              src.write_ln(visit_node(node.[](:"body")))
            end)
          }
          @current_scope = old_parent_scope
          (if @current_scope
            @current_scope.members
.<<(module_type)
          end)
          (if @type_checker && !@current_scope
            @type_checker.top_level_decls
.add(module_type)
          end)
          src.write_ln("end")
          @after_module_function = existing_module_function_state
        when "DefNode"
          args = render_args(node)
          receiver = (if node.[](:"receiver")
            visit_node(node.[](:"receiver"))
          else
            nil
          end)
          src.write_ln("def #{(if receiver
            "#{receiver}."
          end)}#{node.[](:"name")}#{args.[](:"representation")}")
          return_type = (if node.[](:"return_type")
            RBS::Types::ClassInstance.new(name:             RBS::TypeName.new(name:             eval(visit_node(node.[](:"return_type")))
.to_s
.to_sym, namespace:             RBS::Namespace.root), args: EMPTY_ARRAY, location:             build_location(node))
          else
            RBS::Types::Bases::Any.new(location:             build_location(node))
          end)
          method_types = [RBS::MethodType.new(type_params: EMPTY_ARRAY, type:           RBS::Types::Function.new(required_positionals:           args.dig(:"types", :"required_positionals"), optional_positionals:           args.dig(:"types", :"optional_positionals"), rest_positionals:           args.dig(:"types", :"rest_positionals"), trailing_positionals:           args.dig(:"types", :"trailing_positionals"), required_keywords:           args.dig(:"types", :"required_keywords"), optional_keywords:           args.dig(:"types", :"optional_keywords"), rest_keywords:           args.dig(:"types", :"rest_keywords"), return_type: return_type), block:           (if node.[](:"yield_arg_count")
            RBS::Types::Block.new(type:             RBS::Types::Function.new(required_positionals:             Array.new, optional_positionals:             Array.new, rest_positionals: nil, trailing_positionals:             Array.new, required_keywords:             Hash.new, optional_keywords:             Hash.new, rest_keywords: nil, return_type:             RBS::Types::Bases::Any.new(location:             build_location(node))), required: !!node.[](:"block_arg") || node.[](:"yield_arg_count"))
          else
            nil
          end), location:           build_location(node))]
          method_definition = RBS::AST::Members::MethodDefinition.new(name:           node.[](:"name")
.to_sym, kind:           (if @after_module_function
            :"singleton_instance"
          else
            (if receiver
              :"singleton"
            else
              :"instance"
            end)
          end), types: method_types, annotations: EMPTY_ARRAY, location:           build_location(node), comment:           node.[](:"comment"), overload: false)
          (if @current_scope
            @current_scope.members
.<<(method_definition)
          else
            (if @type_checker
              @type_checker.type_env
.<<(method_definition)
            end)
          end)
          indented(src) { ||
            (if node.[](:"body")
              src.write_ln(visit_node(node.[](:"body")))
            end)
          }
          src.write_ln("end")
        when "VisibilityModifier"
          src.write_ln("#{node.[](:"visibility")} #{visit_node(node.[](:"exp"))}")
        when "CollectionNode"
          node.[](:"children")
.each() { |a|
            src.write(visit_node(a, scope))
          }
        when "Call"
          obj = (if node.[](:"object")
            "#{visit_node(node.[](:"object"), scope)}."
          else
            ""
          end)
          arg_arr = node.fetch(:"args") { ||
EMPTY_ARRAY          }
          (if node.[](:"named_args")
            arg_arr += node.[](:"named_args")
          end)
          args = (if !arg_arr.empty? || node.[](:"block_arg")
            "#{arg_arr.map() { |a|
              visit_node(a, scope)
.strip
            }
.reject(&:"blank?")
.join(", ")}#{(if node.[](:"block_arg")
              "&#{visit_node(node.[](:"block_arg"))
.strip}"
            end)}"
          else
            nil
          end)
          name = node.[](:"name")
case name
            when "require_relative"
            paths = arg_arr.map do |a|
              unless a[:type] == "LiteralNode"
                throw :error, "Dynamic file paths are not allowed in require_relative"
              end
              eval(visit_node(a, scope).strip)
            end
            @on_new_file_referenced.call(paths, true)
            when "module_function"
              @after_module_function = true
          end
          block = (if node.[](:"block")
            " #{visit_node(node.[](:"block"))}"
          else
            nil
          end)
          has_parens = !!node.[](:"has_parentheses") || args || block
          opening_delimiter = (if has_parens
            "("
          else
            nil
          end)
          call = "#{obj}#{name}#{opening_delimiter}#{args}#{(if has_parens
            ")"
          end)}#{block}"
          src.write_ln(call)
        when "Block"
          args = render_args(node)
          src.write("{ #{args.[](:"representation")
.gsub(/(\A\(|\)\z)/, "|")}\n")
          indented(src) { ||
            src.write(visit_node(node.[](:"body")))
          }
          src.write_ln("}")
        when "RangeLiteral"
          dots = (if node.[](:"exclusive")
            "..."
          else
            ".."
          end)
          src.write("(", "(", visit_node(node.[](:"from")), ")", dots, "(", visit_node(node.[](:"to")), ")", ")")
        when "LiteralNode"
          src.write(node.[](:"value"))
        when "ArrayLiteral"
          src.write("[", node.[](:"elements")
.map() { |e|
            visit_node(e)
.strip
          }
.join(", "), "]")
          (if node.[](:"frozen")
            src.write(".freeze")
          end)
        when "StringInterpolation"
          contents = node.[](:"contents")
.inject(String.new) { |str, c|
            str.<<(case c.[](:"type")
              when "LiteralNode"
                c.[](:"value")
.[](((1)...(-1)))
              else
                ["\#{", visit_node(c)
.strip, "}"].join
            end)
          }
          src.write("\"", contents, "\"")
        when "Path"
          src.write(node.[](:"value"))
        when "Require"
          path = node.[](:"value")
          src.write_ln("require \"#{path}\"")
          (if @on_new_file_referenced
            @on_new_file_referenced.call([path], false)
          end)
        when "Assign", "OpAssign"
          src.write_ln("#{visit_node(node.[](:"target"))} #{node.[](:"op")}= #{visit_node(node.[](:"value"))
.strip}")
        when "MultiAssign"
          src.write_ln("#{node.[](:"targets")
.map() { |t|
            visit_node(t)
.strip
          }
.join(", ")} = #{node.[](:"values")
.map() { |v|
            visit_node(v)
.strip
          }
.join(", ")}")
        when "Var"
          (if @eval_vars
            src.write(scope.[](node.[](:"name")))
          else
            src.write(node.[](:"name"))
          end)
        when "InstanceVar"
          src.write(node.[](:"name"))
        when "GlobalVar"
          src.write(node.[](:"name"))
        when "Arg"
          val = node.[](:"external_name")
          (if node.[](:"keyword_arg")
            val += ":"
            (if node.[](:"value")
              val += " #{visit_node(node.[](:"value"))}"
            end)
          else
            (if node.[](:"value")
              val += " = #{visit_node(node.[](:"value"))}"
            end)
          end)
          src.write(val)
        when "UnaryExpr"
          src.write("#{node.[](:"op")}#{visit_node(node.[](:"value"))
.strip}")
        when "BinaryOp"
          src.write(visit_node(node.[](:"left"))
.strip, " #{node.[](:"op")} ", visit_node(node.[](:"right"))
.strip)
        when "HashLiteral"
          contents = node.[](:"elements")
.map() { |k, v|
            key = case k
              when String
                k.to_sym
.inspect
              else
                visit_node(k)
            end
            value = visit_node(v)
"#{key} => #{value}"          }
          src.write("{#{contents.join(",\n")}}")
          (if node.[](:"frozen")
            src.write(".freeze")
          end)
        when "Enum"
          src.write_ln("module #{node.[](:"name")}")
          node.[](:"members")
.each_with_index() { |m, i|
            indented(src) { ||
              src.write_ln(visit_node(m)
.+((if !m.[](:"value")
                " = #{i}"
              else
                ""
              end)))
            }
          }
          src.write_ln("end")
        when "If"
          src.write_ln("(if #{visit_node(node.[](:"condition"))
.strip}")
          indented(src) { ||
            src.write_ln(visit_node(node.[](:"then")))
          }
          (if node.[](:"else")
            src.write_ln("else")
            indented(src) { ||
              src.write_ln(visit_node(node.[](:"else")))
            }
          end)
          src.write_ln("end)")
        when "Unless"
          src.write_ln("unless #{visit_node(node.[](:"condition"))}")
          indented(src) { ||
            src.write_ln(visit_node(node.[](:"then")))
          }
          (if node.[](:"else")
            src.write_ln("else")
            indented(src) { ||
              src.write_ln(visit_node(node.[](:"else")))
            }
          end)
          src.write_ln("end")
        when "Case"
          src.write("case")
          (if node.[](:"condition")
            src.write(" #{visit_node(node.[](:"condition"))
.strip}\n")
          end)
          indented(src) { ||
            node.[](:"whens")
.each() { |w|
              src.write_ln(visit_node(w))
            }
            (if node.[](:"else")
              src.write_ln("else")
              indented(src) { ||
                src.write_ln(visit_node(node.[](:"else")))
              }
            end)
          }
          src.write_ln("end")
        when "When"
          src.write_ln("when #{node.[](:"conditions")
.map() { |n|
            visit_node(n)
          }
.join(", ")}")
          indented(src) { ||
            src.write_ln((if node.[](:"body")
              visit_node(node.[](:"body"))
            else
              "# no op"
            end))
          }
        when "MacroFor"
          vars, expr, body = node.[](:"vars"), node.[](:"expr"), node.[](:"body")
          var_names = vars.map() { |v|
            visit_node(v)
          }
          @inside_macro = true
          indent_level = @indent_level
          unless           indent_level.zero?
            @indent_level -= 1
          end
          # @type var expanded: Array[String]
          expanded =           eval(visit_node(expr))
.map() { |*a|
            locals = [var_names.join("\", \"")].zip(a)
.to_h
            (if @inside_macro
              locals.merge!(scope)
            end)
            visit_node(body, locals)
          }
.flatten
          unless           indent_level.zero?
            @indent_level += 1
          end
          expanded.each() { |e|
            src.write(e)
          }
          @inside_macro = false
        when "MacroLiteral"
          src.write(node.[](:"value"))
        when "MacroExpression"
          (if node.[](:"output")
            expr = visit_node(node.[](:"expr"), scope)
            val = scope.[](expr)
            src.write(val)
          end)
        when "MacroIf"
          (if evaluate_macro_condition(node.[](:"condition"), scope)
            (if node.[](:"then")
              src.write_ln(visit_node(node.[](:"then"), scope))
            end)
          else
            (if node.[](:"else")
              src.write_ln(visit_node(node.[](:"else"), scope))
            end)
          end)
        when "Return"
          val = (if node.[](:"value")
            " #{visit_node(node.[](:"value"))
.strip}"
          else
            nil
          end)
          src.write("return#{val}")
        when "TypeDeclaration"
          src.write_ln("# @type var #{visit_node(node.[](:"var"))}: #{visit_node(node.[](:"declared_type"))}")
          value = (if node.[](:"value")
            " = #{visit_node(node.[](:"value"))}"
          else
            nil
          end)
          src.write_ln("#{visit_node(node.[](:"var"))}#{value}")
        when "ExceptionHandler"
          src.write_ln("begin")
          indented(src) { ||
            src.write_ln(visit_node(node.[](:"body")))
          }
          (if node.[](:"rescues")
            node.[](:"rescues")
.each() { |r|
              src.write_ln("rescue #{(if r.[](:"types")
                r.[](:"types")
.map() { |n|
                  visit_node(n)
                }
.join(", ")
              end)}#{(if r.[](:"name")
                " => #{r.[](:"name")}"
              end)}")
              (if r.[](:"body")
                indented(src) { ||
                  src.write_ln(visit_node(r.[](:"body")))
                }
              end)
            }
          end)
          (if node.[](:"else")
            src.write_ln("else")
            indented(src) { ||
              src.write_ln(visit_node(node.[](:"else")))
            }
          end)
          (if node.[](:"ensure")
            src.write_ln("ensure")
            indented(src) { ||
              src.write_ln(visit_node(node.[](:"ensure")))
            }
          end)
          src.write_ln("end")
        when "Generic"
          src.write("#{visit_node(node.[](:"name"))}[#{node.[](:"args")
.map() { |a|
            visit_node(a)
          }
.join(", ")}]")
        when "Proc"
          fn = node.[](:"function")
          src.write("->#{render_args(fn)} { #{visit_node(fn.[](:"body"))} }")
        when "Include"
          current_namespace = (if @current_scope
            @current_scope.name
.to_namespace
          else
            RBS::Namespace.root
          end)
          name = visit_node(node.[](:"name"))
          src.write_ln("include #{name}")
          type = RBS::AST::Members::Include.new(name:           method(:"TypeName")
.call(name), args:           Array.new, annotations:           Array.new, location:           build_location(node), comment:           node.[](:"comment"))
          (if @current_scope
            @current_scope.members
.<<(type)
          else
            @type_checker.type_env
.<<(type)
          end)
        when "Extend"
          current_namespace = (if @current_scope
            @current_scope.name
.to_namespace
          else
            RBS::Namespace.root
          end)
          name = visit_node(node.[](:"name"))
          src.write_ln("extend #{name}")
          type = RBS::AST::Members::Extend.new(name:           method(:"TypeName")
.call(name), args:           Array.new, annotations:           Array.new, location:           build_location(node), comment:           node.[](:"comment"))
          (if @current_scope
            @current_scope.members
.<<(type)
          else
            @type_checker.type_env
.<<(type)
          end)
        when "RegexLiteral"
          contents = visit_node(node.[](:"value"))
          src.write(Regexp.new(contents.undump)
.inspect)
        when "Union"
          types = node.[](:"types")
          output = (if types.length
.==(2) && types.[](1)
.[](:"type")
.==("Path") && types.[](1)
.[]("value")
.==(nil)
            "#{visit_node(types.[](0))}?"
          else
            types.map() { |t|
              visit_node(t)
            }
.join(" | ")
          end)
          src.write(output)
        when "Next"
          (if node.[](:"value")
            val = " #{node.[](:"value")}"
          end)
          src.write("next#{val}")
        when "EmptyNode"
          # no op
        else
          raise("Not implemented: #{node.[](:"type")}")
      end
src
    end
    private     def evaluate_macro_condition(condition_node, scope)
      @eval_vars = true
      eval(visit_node(condition_node, scope))
      @eval_vars = false
    end
    private     def indented(src)
      increment_indent(src)
      yield
      decrement_indent(src)
    end
    private     def increment_indent(src)
      @indent_level += 1
      src.increment_indent
    end
    private     def decrement_indent(src)
      @indent_level -= 1
      src.decrement_indent
    end
    private     def render_args(node)
      # @type var rp: Array[Hash[Symbol, Any]]
      rp =       node.fetch(:"positional_args") { ||
EMPTY_ARRAY      }
.filter() { |a|
!a.[](:"value")      }
      # @type var op: Array[Hash[Symbol, Any]]
      op =       node.fetch(:"positional_args") { ||
EMPTY_ARRAY      }
.filter() { |a|
        a.[](:"value")
      }
      # @type var rkw: Hash[Symbol, Any]
      rkw =       node.fetch(:"req_kw_args") { ||
EMPTY_HASH      }
      # @type var okw: Hash[Symbol, Any]
      okw =       node.fetch(:"opt_kw_args") { ||
EMPTY_HASH      }
      # @type var rest_p: String?
      rest_p =       (if node.[](:"rest_p_args")
        visit_node(node.[](:"rest_p_args"))
      else
        nil
      end)
      # @type var rest_kw: Hash[Symbol, Any]?
      rest_kw =       node.[](:"rest_kw_args")
      (if [rp, op, rkw, okw, rest_p, rest_kw].all?() { |a|
a && a.empty?      }
        return nil
      end)
      contents = [rp.map() { |a|
        visit_node(a)
      }, op.map() { |a|
"#{a.[](:"name")} = #{visit_node(a.[](:"value"))
.strip}"      }, rkw.map() { |name, _|
"#{name}:"      }, okw.map() { |name, value|
"#{name}: #{value}"      }, (if rest_p
        "*#{rest_p}"
      else
        ""
      end), (if rest_kw
        "**#{visit_node(rest_kw)}"
      else
        ""
      end)].reject(&:"empty?")
.flatten
.join(", ")
      representation = "(#{contents})"
      rp_args = rp.map() { |a|
        RBS::Types::Function::Param.new(name:         visit_node(a)
.to_sym, type:         RBS::Types::Bases::Any.new(location:         build_location(a)))
      }
      op_args = op.map() { |a|
        RBS::Types::Function::Param.new(name:         visit_node(a)
.to_sym, type:         RBS::Types::Bases::Any.new(location:         build_location(a)))
      }
      rpa = (if rest_p
        RBS::Types::Function::Param.new(name:         rest_p.to_sym, type:         RBS::Types::Bases::Any.new(location:         build_location(node)))
      else
        nil
      end)
{:representation => representation,
:types => {:required_positionals => rp_args,
:optional_positionals => op_args,
:rest_positionals => rpa,
:trailing_positionals => EMPTY_ARRAY,
:required_keywords => node.[](:"req_kw_args") || EMPTY_HASH,
:optional_keywords => node.[](:"opt_kw_args") || EMPTY_HASH,
:rest_keywords =>       (if node.[](:"rest_kw_args")
        RBS::Types::Function::Param.new(name:         visit_node(node.[](:"rest_kw_args"))
.to_sym, type:         RBS::Types::Bases::Any.new(location:         build_location(node)))
      else
        nil
      end)
}.freeze}.freeze
    end
    def build_location(node)
      unless       node.[](:"location")
        return nil
      end
    end
  end
end
