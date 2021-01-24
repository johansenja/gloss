require "compiler/crystal/syntax/*"
require "json"
require "./rb_ast"

module Crystal
  abstract class ASTNode
    def to_rb
      Rb::AST::EmptyNode.new(self.class.name)
    end
  end

  class Nop < ASTNode
    def to_rb
      Rb::AST::Nop.new
    end
  end

  class Expressions < ASTNode
    def to_rb
      Rb::AST::CollectionNode.new(@expressions.map(&.to_rb))
    end
  end

  class NilLiteral < ASTNode
    def to_rb
      Rb::AST::LiteralNode.new("nil", Rb::AST::RbLiteral::NilClass)
    end
  end

  class BoolLiteral < ASTNode
    def to_rb
      Rb::AST::LiteralNode.new(
        @value.inspect,
        @value ? Rb::AST::RbLiteral::TrueClass : Rb::AST::RbLiteral::FalseClass
      )
    end
  end

  class NumberLiteral < ASTNode
    def to_rb
      Rb::AST::LiteralNode.new(@value, Rb::AST::RbLiteral::Integer)
    end
  end

  class CharLiteral < ASTNode
    def to_rb
      Rb::AST::LiteralNode.new(@value.inspect, Rb::AST::RbLiteral::String)
    end
  end

  class StringLiteral < ASTNode
    def to_rb
      Rb::AST::LiteralNode.new(@value.inspect, Rb::AST::RbLiteral::String)
    end
  end

  class StringInterpolation < ASTNode
    def to_rb
      Rb::AST::StringInterpolation.new(@expressions.map &.to_rb)
    end
  end

  class SymbolLiteral < ASTNode
    def to_rb
      Rb::AST::LiteralNode.new(%{:"#{@value.to_s}"}, Rb::AST::RbLiteral::Symbol)
    end
  end

  class ArrayLiteral < ASTNode
    def to_rb
      Rb::AST::ArrayLiteral.new(@elements.map(&.to_rb))
    end
  end

  class HashLiteral < ASTNode
    def to_rb
      Rb::AST::HashLiteral.new(@entries.map { |e| {e.key.to_rb, e.value.to_rb} })
    end
  end

  class NamedTupleLiteral < ASTNode
    def to_rb
      Rb::AST::HashLiteral.new(@entries.map { |e| {e.key, e.value.to_rb} }, frozen: true)
    end
  end

  class RangeLiteral < ASTNode
    def to_rb
      Rb::AST::RangeLiteral.new(@from.to_rb, @to.to_rb, @exclusive)
    end
  end

  class RegexLiteral < ASTNode
    def to_rb
      Rb::AST::RegexLiteral.new(@value.to_rb)
    end
  end

  class TupleLiteral < ASTNode
    def to_rb
      Rb::AST::ArrayLiteral.new(@elements.map(&.to_rb), frozen: true)
    end
  end

  class Def < ASTNode
    def to_rb
      required_args = args.dup
      splat = @splat_index ? required_args.delete_at(@splat_index.as(Int32)) : nil
      Rb::AST::DefNode.new(
        @name,
        required_args.map(&.to_rb),
        @body.to_rb,
        receiver.try(&.to_rb),
        return_type.try(&.to_rb),
        splat.try(&.to_rb),
        @double_splat.try(&.to_rb)
      )
    end
  end

  class ClassDef < ASTNode
    def to_rb
      Rb::AST::ClassNode.new(@name.to_rb, @body.to_rb, @superclass.try(&.to_rb), @type_vars, @abstract)
    end
  end

  class ModuleDef < ASTNode
    def to_rb
      Rb::AST::ModuleNode.new(@name.to_rb, @body.to_rb, @type_vars)
    end
  end

  class Var < ASTNode
    def to_rb
      Rb::AST::Var.new(@name)
    end
  end

  class Block < ASTNode
    def to_rb
      Rb::AST::Block.new(@args.map(&.to_rb), @body.to_rb)
    end
  end

  class Call < ASTNode
    def to_rb
      Rb::AST::Call.new(
        @obj.try(&.to_rb),
        @name,
        @args.map(&.to_rb),
        @named_args.try(&.map(&.to_rb.as(Rb::AST::Arg))),
        @block.try(&.to_rb),
        @block_arg.try(&.to_rb),
        @has_parentheses
      )
    end
  end

  class Arg < ASTNode
    property keyword_arg : Bool = false

    def to_rb
      Rb::AST::Arg.new(@name, @external_name, @restriction.try(&.to_rb),
        @default_value.try(&.to_rb), @keyword_arg)
    end
  end

  class NamedArgument < ASTNode
    def to_rb
      Rb::AST::Arg.new(@name, @name, nil, @value.to_rb, true)
    end
  end

  class If < ASTNode
    def to_rb
      Rb::AST::If.new(@cond.to_rb, @then.to_rb, @else.to_rb)
    end
  end

  class Unless < ASTNode
    def to_rb
      Rb::AST::Unless.new(@cond.to_rb, @then.to_rb, @else.to_rb)
    end
  end

  class Assign < ASTNode
    def to_rb
      Rb::AST::Assign.new(@target.to_rb, @value.to_rb)
    end
  end

  class OpAssign < ASTNode
    def to_rb
      Rb::AST::Assign.new(@target.to_rb, @value.to_rb, @op)
    end
  end

  class MultiAssign < ASTNode
    def to_rb
      Rb::AST::EmptyNode.new(self.class.name)
    end
  end

  class InstanceVar < ASTNode
    def to_rb
      Rb::AST::InstanceVar.new(@name)
    end
  end

  class ReadInstanceVar < ASTNode
    def to_rb
      Rb::AST::EmptyNode.new(self.class.name)
    end
  end

  class ClassVar < ASTNode
    def to_rb
      Rb::AST::EmptyNode.new(self.class.name)
    end
  end

  class Global < ASTNode
    def to_rb
      Rb::AST::GlobalVar.new(@name)
    end
  end

  class Annotation < ASTNode
    def to_rb
      Rb::AST::EmptyNode.new(self.class.name)
    end
  end

  class MacroExpression < ASTNode
    def to_rb
      Rb::AST::EmptyNode.new(self.class.name)
    end
  end

  class MacroIf < ASTNode
    def to_rb
      Rb::AST::MacroIf.new(@cond.to_rb, @then.to_rb, @else.to_rb)
    end
  end

  class MacroFor < ASTNode
    def to_rb
      Rb::AST::MacroFor.new(@vars.map(&.to_rb), @exp.to_rb, @body.to_rb)
    end
  end

  class MacroVar < ASTNode
    def to_rb
      Rb::AST::EmptyNode.new(self.class.name)
    end
  end

  class MacroExpression < ASTNode
    def to_rb
      Rb::AST::MacroExpression.new(@exp.to_rb, @output)
    end
  end

  class MacroLiteral < ASTNode
    def to_rb
      Rb::AST::MacroLiteral.new(@value)
    end
  end

  class Annotation < ASTNode
    def to_rb
      Rb::AST::EmptyNode.new(self.class.name)
    end
  end

  class EnumDef < ASTNode
    def to_rb
      Rb::AST::Enum.new(@name, @members.map(&.to_rb))
    end
  end

  class Path < ASTNode
    def to_rb
      Rb::AST::Path.new(full_name)
    end

    def full_name
      @names.join("::")
    end

    delegate :to_json, to: :full_name
  end

  class Require < ASTNode
    def to_rb
      Rb::AST::Require.new(@string)
    end
  end

  class TypeDeclaration < ASTNode
    def to_rb
      Rb::AST::TypeDeclaration.new(@var.to_rb, @declared_type.to_rb, @value.try(&.to_rb))
    end
  end

  class Case < ASTNode
    def to_rb
      Rb::AST::Case.new(
        @cond.try(&.to_rb),
        @whens.map(&.to_rb),
        @else.try(&.to_rb),
        @exhaustive
      )
    end
  end

  class When < ASTNode
    def to_rb
      Rb::AST::When.new(
        @conds.map do |c|
          if c.is_a? Call
            arg_name = "x"
            ProcLiteral.new(
              Def.new(
                "->",
                [Arg.new(arg_name)],
                c.tap { |call| call.obj = Var.new(arg_name) }
              )
            ).to_rb
          else
            c.to_rb
          end
        end,
        @body.to_rb,
        @exhaustive
      )
    end
  end

  {% for class_name in %w[Splat DoubleSplat Not] %}
    class {{class_name.id}} < UnaryExpression
      def to_rb
        {% if class_name == "Splat" %}
          op = "*"
        {% elsif class_name == "DoubleSplat" %}
          op = "**"
        {% else %}
          op = "!"
        {% end %}
        # for some of the other unary expressions, parentheses are normally used by convention eg.
        # pointerof - but they are definitely lower priority
        requires_parentheses = true
        Rb::AST::UnaryExpr.new(
          @exp.to_rb,
          op,
          requires_parentheses
        )
      end
    end
  {% end %}

  {% for class_name in %w[And Or] %}
    class {{class_name.id}} < BinaryOp
      def to_rb
        Rb::AST::BinaryOp.new(
          {% if class_name == "And" %}
            "&&",
          {% else %}
            "||",
          {% end %}
          @left.to_rb,
          @right.to_rb
        )
      end
    end
  {% end %}

  {% for class_name in %w[Return Break Next] %}
    class {{class_name.id}} < ControlExpression
      def to_rb
        Rb::AST::{{class_name.id}}.new(@exp.try(&.to_rb))
      end
    end
  {% end %}

  class ExceptionHandler < ASTNode
    def to_rb
      Rb::AST::ExceptionHandler.new(@body.to_rb, @rescues.try(&.map(&.to_rb)), @else.try(&.to_rb),
        @ensure.try(&.to_rb))
    end
  end

  class Rescue < ASTNode
    def to_rb
      Rb::AST::Rescue.new(@body.to_rb, @types.try(&.map(&.to_rb)), @name)
    end
  end

  class Union < ASTNode
    def to_rb
      Rb::AST::Union.new(@types.map(&.to_rb))
    end
  end

  class Generic < ASTNode
    def to_rb
      Rb::AST::Generic.new(@name.to_rb, @type_vars.map(&.to_rb))
    end
  end

  class ProcLiteral < ASTNode
    def to_rb
      Rb::AST::Proc.new(@def.to_rb)
    end
  end

  class Include < ASTNode
    def to_rb
      Rb::AST::Include.new(@name.to_rb)
    end
  end

  class Extend < ASTNode
    def to_rb
      Rb::AST::Extend.new(@name.to_rb)
    end
  end

  class IsA < ASTNode
    def to_rb
      Rb::AST::Call.new(
        @obj.to_rb,
        "is_a?",
        [@const.to_rb],
        nil,
        nil,
        nil,
        false
      )
    end
  end

  {% for class_name in %w[ProcNotation Macro OffsetOf VisibilityModifier RespondsTo
                         Select ImplicitObj AnnotationDef While Until UninitializedVar
                         ProcPointer Self Yield LibDef FunDef TypeDef CStructOrUnionDef
                         ExternalVar Alias Metaclass Cast NilableCast TypeOf Annotation
                         Underscore MagicConstant Asm AsmOperand] %}
    class {{class_name.id}} < ASTNode
      def to_rb
        Rb::AST::EmptyNode.new(self.class.name)
      end
    end
  {% end %}

  {% for class_name in %w[PointerOf SizeOf InstanceSizeOf Out MacroVerbatim] %}
    class {{class_name.id}} < UnaryExpression
      def to_rb
        Rb::AST::EmptyNode.new(self.class.name)
      end
    end
  {% end %}
end
