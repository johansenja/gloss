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

    abstract class NodeWithSingleChild < Node
      @info : NamedTuple(type: String, child: Node)

      def initialize(@child : Node)
        @info = {
          type:  self.class.name.split("::").last,
          child: child,
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
      @info : NamedTuple(type: String, name: String, body: Node, args: Array(Arg), receiver: Node?,
        return_type: Node?)

      def initialize(name : String, args : Array(Arg), body : Node, receiver : Node?, return_type : Node?)
        @info = {
          type:        self.class.name.split("::").last,
          name:        name,
          body:        body,
          args:        args,
          receiver:    receiver,
          return_type: return_type,
        }
      end

      delegate :to_json, to: @info
    end

    class Arg < Node
      @info : NamedTuple(type: String, name: String, external_name: String, default_value: Node?,
        restriction: Node?)

      def initialize(name : String, external_name : String, restriction : Node?, default_value : Node?)
        @info = {
          type:          self.class.name.split("::").last,
          name:          name,
          restriction:   restriction,
          default_value: default_value,
          external_name: external_name,
        }
      end

      delegate :to_json, to: @info
    end

    class LiteralNode < NodeWithValue
      def initialize(@value, @rb_type : RbLiteral)
        @info = {
          type:  self.class.name.split("::").last,
          value: value,
        }
      end

      delegate :to_json, to: @info
    end

    class ArrayLiteral < NodeWithValue
    end

    class HashLiteral < NodeWithValue
    end

    class RangeLiteral < NodeWithValue
    end

    class RegexLiteral < NodeWithValue
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

    class Block < NodeWithSingleChild
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
      @info : NamedTuple(type: String, name: String, args: Array(Node), object: Node?)

      def initialize(object : Node?, name : String, args : Array(Node))
        @info = {
          type:   self.class.name.split("::").last,
          name:   name,
          args:   args,
          object: object,
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
          type: self.class.name.split("::").last,
          contents: contents
        }
      end

      delegate :to_json, to: @info
    end

    class UnaryExpr < Node
      @info : NamedTuple(type: String, op: String, value: Node, with_parens: Bool)

      def initialize(val, op, parens)
        @info = {
          type:  self.class.name.split("::").last,
          value: val,
          op: op,
          with_parens: parens
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
          type:  self.class.name.split("::").last,
          target:  target,
          op:    op,
          value: value,
        }
      end

      delegate :to_json, to: @info
    end

    class TypeDeclaration < Node
      @info : NamedTuple(type: String, var: Node, declared_type: Node, value: Node?)

      def initialize(@var : Node, @declared_type : Node, @value : Node?)
        @info = {
          type:          self.class.name.split("::").last,
          var:           @var,
          declared_type: @declared_type,
          value:         @value,
        }
      end

      delegate :to_json, to: @info
    end
  end
end
