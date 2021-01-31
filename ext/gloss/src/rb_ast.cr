require "compiler/crystal/syntax/*"
require "json"

module Rb
  class AST
    enum RbLiteral
      String
      Integer
      TrueClass
      FalseClass
      NilClass
      Float
      Symbol
    end

    abstract class Node
    end

    abstract class NodeWithChildren < Node
      @info : NamedTuple(type: String, children: Array(Node))

      def initialize(@children : Array(Node))
        @info = {
          type:     self.class.name.split("::").last,
          children: @children,
        }
      end

      delegate :to_json, to: @info
    end

    abstract class NodeWithValue < Node
      @info : NamedTuple(type: String, value: String)

      def initialize(@value : String)
        @info = {
          type:  self.class.name.split("::").last,
          value: @value,
        }
      end

      delegate :to_json, to: @info
    end

    class Block < Node
      @info : NamedTuple(type: String, positional_args: Array(Var), body: Node, rest_p_args: Node?)

      def initialize(args, splat, body)
        @info = {
          type: self.class.name.split("::").last,
          body: body,
          positional_args: args,
          rest_p_args: splat
        }
      end

      delegate :to_json, to: @info
    end

    class CollectionNode < NodeWithChildren
    end

    class ClassNode < Node
      @info : NamedTuple(type: String, name: Path, body: Node, superclass: Node?, type_vars: Array(String)?, abstract: Bool)

      def initialize(name : Path, body : Node, superclass : Node?, type_vars : Array(String)?, abstr : Bool)
        @info = {
          type:       self.class.name.split("::").last,
          name:       name,
          body:       body,
          superclass: superclass,
          type_vars:  type_vars,
          abstract:   abstr,
          # visibility: vis,
        }
      end

      delegate :to_json, to: @info
    end

    class ModuleNode < Node
      @info : NamedTuple(type: String, name: Path, body: Node, type_vars: Array(String)?)

      def initialize(name : Path, body : Node, type_vars : Array(String)?)
        @info = {
          type:      self.class.name.split("::").last,
          name:      name,
          body:      body,
          type_vars: type_vars,
          # visiblity:   vis,
        }
      end

      delegate :to_json, to: @info
    end

    class DefNode < Node
      @info : NamedTuple(type: String, name: String, body: Node, positional_args: Array(Arg), receiver: Node?,
        return_type: Node?, rest_kw_args: Arg?, rest_p_args: Arg?, block_arg: Node?, yield_arg_count: Int32?)

      def initialize(
        receiver : Node?,
        name : String,
        positional_args : Array(Arg),
        splat,
        rest_kw_args,
        body : Node,
        return_type : Node?,
        yields : Int32?,
        block_arg : Node?
      )
        @info = {
          type:            self.class.name.split("::").last,
          name:            name,
          body:            body,
          positional_args: positional_args,
          rest_kw_args:    rest_kw_args,
          receiver:        receiver,
          return_type:     return_type,
          rest_p_args:     splat,
          yield_arg_count: yields,
          block_arg: block_arg
        }
      end

      delegate :to_json, to: @info
    end

    class Arg < Node
      @info : NamedTuple(type: String, name: String, external_name: String, value: Node?,
        restriction: Node?, keyword_arg: Bool)

      def initialize(name : String, external_name : String, restriction : Node?, value : Node?, keyword_arg)
        @info = {
          type:          self.class.name.split("::").last,
          name:          name,
          restriction:   restriction,
          value:         value,
          external_name: external_name,
          keyword_arg:   keyword_arg,
        }
      end

      delegate :to_json, to: @info
    end

    class LiteralNode < Node
      @info : NamedTuple(type: String, value: String | Int32 | Bool | Nil, rb_type: String)

      def initialize(value, rb_type : RbLiteral)
        val = case rb_type
              when Rb::AST::RbLiteral::TrueClass
                true
              when Rb::AST::RbLiteral::FalseClass
                false
              when Rb::AST::RbLiteral::NilClass
                nil
              when Rb::AST::RbLiteral::Symbol
                ":#{value}"
              else
                value
              end
        @info = {
          type:    self.class.name.split("::").last,
          value:   value,
          rb_type: rb_type.inspect,
        }
      end

      delegate :to_json, to: @info
    end

    class ArrayLiteral < Node
      @info : NamedTuple(type: String, elements: Array(Node), frozen: Bool)

      def initialize(elems, frozen = false)
        @info = {
          type:     self.class.name.split("::").last,
          elements: elems,
          frozen:   frozen,
        }
      end

      delegate :to_json, to: @info
    end

    class HashLiteral < Node
      @info : NamedTuple(type: String, elements: Array(Tuple(Node, Node)) | Array(Tuple(String, Node)), frozen: Bool)

      def initialize(elems, frozen = false)
        @info = {
          type:     self.class.name.split("::").last,
          elements: elems,
          frozen:   frozen,
        }
      end

      delegate :to_json, to: @info
    end

    class RangeLiteral < Node
      @info : NamedTuple(type: String, from: Node, to: Node, exclusive: Bool)

      def initialize(from, to, exclusive)
        @info = {
          type:      self.class.name.split("::").last,
          from:      from,
          to:        to,
          exclusive: exclusive,
        }
      end

      delegate :to_json, to: @info
    end

    class RegexLiteral < Node
      @info : NamedTuple(type: String, value: Node)

      def initialize(value)
        @info = {
          type:  self.class.name.split("::").last,
          value: value,
        }
      end

      delegate :to_json, to: @info
    end

    class Nop < Node
      @info : NamedTuple(type: String)?

      def initialize
        @info = nil
      end

      delegate :to_json, to: @info
    end

    class EmptyNode < Nop
      def initialize(class_name : String)
        STDERR.puts "Encountered a ruby EmptyNode class name: #{class_name}"
        @info = {
          type: self.class.name.split("::").last,
        }
      end
    end

    class Var < Node
      @info : NamedTuple(type: String, name: String)

      def initialize(@name : String)
        @info = {
          type: self.class.name.split("::").last,
          name: @name,
        }
      end

      delegate :to_json, to: @info
    end

    class InstanceVar < Var
    end

    class GlobalVar < Var
    end

    abstract class Conditional < Node
      @info : NamedTuple(type: String, condition: Node, then: Node, else: Node)

      def initialize(@condition : Node, @thn : Node, @els : Node)
        @info = {
          type:      self.class.name.split("::").last,
          condition: @condition,
          then:      @thn,
          else:      @els,
        }
      end

      delegate :to_json, to: @info
    end

    class If < Conditional
    end

    class Unless < Conditional
    end

    class Case < Node
      @info : NamedTuple(type: String, condition: Node?, whens: Array(When), else: Node?, exhaustive: Bool)

      def initialize(cond : Node?, whens : Array(When), els : Node?, exhaustive : Bool)
        @info = {
          type:       self.class.name.split("::").last,
          condition:  cond,
          whens:      whens,
          else:       els,
          exhaustive: exhaustive,
        }
      end

      delegate :to_json, to: @info
    end

    class When < Node
      @info : NamedTuple(type: String, conditions: Array(Node), body: Node, exhaustive: Bool)

      def initialize(conds : Array(Node), body : Node, exhaustive : Bool)
        @info = {
          type:       self.class.name.split("::").last,
          conditions: conds,
          body:       body,
          exhaustive: exhaustive,
        }
      end

      delegate :to_json, to: @info
    end

    class Enum < Node
      @info : NamedTuple(type: String, name: Crystal::Path, members: Array(Node))

      def initialize(@name : Crystal::Path, @members : Array(Node))
        @info = {
          type:    self.class.name.split("::").last,
          name:    @name,
          members: @members,
        }
      end

      delegate :to_json, to: @info
    end

    class Call < Node
      @info : NamedTuple(type: String, name: String, args: Array(Node), object: Node?, block: Block?, block_arg: Node?, named_args: Array(Arg)?, has_parentheses: Bool)

      def initialize(object : Node?, name : String, args : Array(Node), named_args, block,
                     block_arg, has_parentheses)
        @info = {
          type:            self.class.name.split("::").last,
          name:            name,
          args:            args,
          object:          object,
          block:           block,
          block_arg:       block_arg,
          named_args:      named_args,
          has_parentheses: has_parentheses || false,
        }
      end

      delegate :to_json, to: @info
    end

    class Path < NodeWithValue
    end

    class Require < NodeWithValue
    end

    class StringInterpolation < Node
      @info : NamedTuple(type: String, contents: Array(Node))

      def initialize(contents)
        @info = {
          type:     self.class.name.split("::").last,
          contents: contents,
        }
      end

      delegate :to_json, to: @info
    end

    class UnaryExpr < Node
      @info : NamedTuple(type: String, op: String, value: Node, with_parens: Bool)

      def initialize(val, op, parens)
        @info = {
          type:        self.class.name.split("::").last,
          value:       val,
          op:          op,
          with_parens: parens,
        }
      end

      delegate :to_json, to: @info
    end

    class BinaryOp < Node
      @info : NamedTuple(type: String, op: String, left: Node, right: Node)

      def initialize(op, left, right)
        @info = {
          type:  self.class.name.split("::").last,
          left:  left,
          op:    op,
          right: right,
        }
      end

      delegate :to_json, to: @info
    end

    class Assign < Node
      @info : NamedTuple(type: String, op: String?, target: Node, value: Node)

      def initialize(target, value, op = nil)
        @info = {
          type:   self.class.name.split("::").last,
          target: target,
          op:     op,
          value:  value,
        }
      end

      delegate :to_json, to: @info
    end

    class MultiAssign < Node
      @info : NamedTuple(type: String, targets: Array(Node), values: Array(Node))

      def initialize(targets, values)
        @info = {
          type:    self.class.name.split("::").last,
          targets: targets,
          values:  values,
        }
      end

      delegate :to_json, to: @info
    end

    class TypeDeclaration < Node
      @info : NamedTuple(type: String, var: Node, declared_type: Node, value: Node?, var_type: String)

      def initialize(@var : Node, @declared_type : Node, @value : Node?)
        @info = {
          type:          self.class.name.split("::").last,
          var:           @var,
          var_type:      @var.class.name.split("::").last,
          declared_type: @declared_type,
          value:         @value,
        }
      end

      delegate :to_json, to: @info
    end

    class MacroFor < Node
      @info : NamedTuple(type: String, vars: Array(Var), expr: Node, body: Node)

      def initialize(vars, expr, body)
        @info = {
          type: self.class.name.split("::").last,
          vars: vars,
          expr: expr,
          body: body,
        }
      end

      delegate :to_json, to: @info
    end

    class MacroIf < Conditional
    end

    class MacroLiteral < NodeWithValue
    end

    class MacroExpression < Node
      @info : NamedTuple(type: String, expr: Node, output: Bool)

      def initialize(expr, output)
        @info = {
          type:   self.class.name.split("::").last,
          expr:   expr,
          output: output,
        }
      end

      delegate :to_json, to: @info
    end

    class ControlExpression < Node
      @info : NamedTuple(type: String, value: Node?)

      def initialize(value)
        @info = {
          type:  self.class.name.split("::").last,
          value: value,
        }
      end

      delegate :to_json, to: @info
    end

    class Return < ControlExpression
    end

    class Break < ControlExpression
    end

    class Next < ControlExpression
    end

    class ExceptionHandler < Node
      @info : NamedTuple(type: String, body: Node, rescues: Array(Rescue)?, else: Node?,
        ensure: Node?)

      def initialize(body, rescues, else_node, ensure_node)
        @info = {
          type:    self.class.name.split("::").last,
          body:    body,
          rescues: rescues,
          else:    else_node,
          ensure:  ensure_node,
        }
      end

      delegate :to_json, to: @info
    end

    class Rescue < Node
      @info : NamedTuple(type: String, body: Node, types: Array(Node)?, name: String?)

      def initialize(body, types, name)
        @info = {
          type:  self.class.name.split("::").last,
          body:  body,
          types: types,
          name:  name,
        }
      end

      delegate :to_json, to: @info
    end

    class Union < Node
      @info : NamedTuple(type: String, types: Array(Node))

      def initialize(types)
        @info = {
          type:  self.class.name.split("::").last,
          types: types,
        }
      end

      delegate :to_json, to: @info
    end

    class Generic < Node
      @info : NamedTuple(type: String, name: Node, args: Array(Node))

      def initialize(name, args)
        @info = {
          type: self.class.name.split("::").last,
          name: name,
          args: args,
        }
      end

      delegate :to_json, to: @info
    end

    class Proc < Node
      @info : NamedTuple(type: String, function: DefNode)

      def initialize(function)
        @info = {
          type:     self.class.name.split("::").last,
          function: function,
        }
      end

      delegate :to_json, to: @info
    end

    class NodeWithNameNode < Node
      @info : NamedTuple(type: String, name: Node)

      def initialize(name)
        @info = {
          type: self.class.name.split("::").last,
          name: name,
        }
      end

      delegate :to_json, to: @info
    end

    class Extend < NodeWithNameNode
    end

    class Include < NodeWithNameNode
    end

    class VisibilityModifier < Node
      @info : NamedTuple(type: String, visibility: String, exp: Node)

      def initialize(visibility : Crystal::Visibility, exp : Node)
        vis = case visibility
              when Crystal::Visibility::Public
                "public"
              when Crystal::Visibility::Protected
                "protected"
              when Crystal::Visibility::Private
                "private"
              end
        @info = {
          type:       self.class.name.split("::").last,
          visibility: vis.as(String),
          exp:        exp,
        }
      end

      delegate :to_json, to: @info
    end
  end
end
