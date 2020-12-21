require "compiler/crystal/syntax/*"
require "json"

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
      Rb::AST::LiteralNode.new(@value.inspect, Rb::AST::RbLiteral::Integer)
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
      Rb::AST::LiteralNode.new("", Rb::AST::RbLiteral::String)
    end
  end

  class SymbolLiteral < ASTNode
    def to_rb
      Rb::AST::LiteralNode.new(":#{@value.inspect}", Rb::AST::RbLiteral::Symbol)
    end
  end

  class ArrayLiteral < ASTNode
    def to_rb
      Rb::AST::ArrayLiteral.new("[]")
    end
  end

  class HashLiteral < ASTNode
    def to_rb
      Rb::AST::HashLiteral.new("{}")
    end
  end

  class NamedTupleLiteral < ASTNode
    def to_rb
      Rb::AST::HashLiteral.new("{}")
    end
  end

  class RangeLiteral < ASTNode
    def to_rb
      Rb::AST::RangeLiteral.new("0..0")
    end
  end

  class RegexLiteral < ASTNode
    def to_rb
      Rb::AST::RangeLiteral.new("//")
    end
  end

  class TupleLiteral < ASTNode
    def to_rb
      Rb::AST::ArrayLiteral.new("[]")
    end
  end

  class Def < ASTNode
    def to_rb
      Rb::AST::DefNode.new(@name, @args.map(&.to_rb), @body.to_rb, receiver.try(&.to_rb),
        return_type.try(&.to_rb))
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
      Rb::AST::Block.new(@body.to_rb)
    end
  end

  class Call < ASTNode
    def to_rb
      Rb::AST::Call.new(@obj.try(&.to_rb), @name, @args.map(&.to_rb))
    end
  end

  class NamedArgument < ASTNode
    def to_rb
      Rb::AST::EmptyNode.new(self.class.name)
    end
  end

  class Arg < ASTNode
    def to_rb
      Rb::AST::Arg.new(@name, @external_name, @restriction.try(&.to_rb), @default_value.try(&.to_rb))
    end
  end

  class If < ASTNode
    def to_rb
      Rb::AST::If.new(@cond.to_rb, @then.to_rb, @else.to_rb)
    end
  end

  class Assign < ASTNode
    def to_rb
      Rb::AST::Assign.new(@target.to_rb, @value.to_rb)
    end
  end

  class OpAssign < ASTNode
    def to_rb
      Rb::AST::EmptyNode.new(self.class.name)
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
      Rb::AST::EmptyNode.new(self.class.name)
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
      Rb::AST::EmptyNode.new(self.class.name)
    end
  end

  class MacroFor < ASTNode
    def to_rb
      Rb::AST::EmptyNode.new(self.class.name)
    end
  end

  class MacroVar < ASTNode
    def to_rb
      Rb::AST::EmptyNode.new(self.class.name)
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

  {% for class_name in %w[And Or] %}
    class {{class_name.id}} < BinaryOp
      def to_rb
        Rb::AST::EmptyNode.new(self.class.name)
      end
    end
  {% end %}

  {% for class_name in %w[Return Break Next] %}
    class {{class_name.id}} < ControlExpression
      def to_rb
        Rb::AST::EmptyNode.new(self.class.name)
      end
    end
  {% end %}

  {% for class_name in %w[ProcNotation Macro OffsetOf VisibilityModifier IsA RespondsTo When Case
                         Select ImplicitObj AnnotationDef While Until Generic UninitializedVar
                         Rescue ExceptionHandler ProcLiteral ProcPointer Union Self Yield Include
                         Extend LibDef FunDef TypeDef CStructOrUnionDef ExternalVar Alias
                         Metaclass Cast NilableCast TypeOf Annotation MacroExpression MacroLiteral
                         Underscore MagicConstant Asm AsmOperand] %}
    class {{class_name.id}} < ASTNode
      def to_rb
        Rb::AST::EmptyNode.new(self.class.name)
      end
    end
  {% end %}

  {% for class_name in %w[Not PointerOf SizeOf InstanceSizeOf Out MacroVerbatim Splat DoubleSplat] %}
    class {{class_name.id}} < UnaryExpression
      def to_rb
        Rb::AST::EmptyNode.new(self.class.name)
      end
    end
  {% end %}
end
