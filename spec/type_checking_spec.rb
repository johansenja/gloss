RSpec.describe Gloss::TypeChecker do
  let!(:type_checker) { Gloss::TypeChecker.new(".") }

  it "reports type errors in type notations" do
    output = Gloss::Visitor.new(
      {
        type: "ClassNode",
        name: {
          type: "Path",
          value: "MyClass",
        },
        body: {
          type: "DefNode",
          name: "int",
          body: {
            type: "Return",
            value: {
              type: "LiteralNode",
              value: "\"abc\"",
              rb_type: "String",
            },
          },
          rp_args: [],
          receiver: nil,
          return_type: {
            type: "Path",
            value: "Integer",
          },
          rest_kw_args: nil,
        },
        superclass: nil,
        type_vars: nil,
        abstract: false,
      },
      type_checker
    ).run
    err = catch :error do
      type_checker.run "(string)", output
    end
    expect(err).to eq "Invalid return type - expected: ::Integer, actual: ::String"
  end

  it "reports type errors for human error" do
    output = Gloss::Visitor.new(
      {
        type: "CollectionNode",
        children: [
          {
            type: "ClassNode",
            name: {
              type: "Path",
              value: "MyClass",
            },
            body: {
              type: "DefNode",
              name: "int",
              body: {
                type: "Return",
                value: {
                  type: "LiteralNode",
                  value: "100",
                  rb_type: "Integer",
                },
              },
              rp_args: [],
              receiver: nil,
              return_type: {
                type: "Path",
                value: "Integer",
              },
              rest_kw_args: nil,
            },
            superclass: nil,
            type_vars: nil,
            abstract: false,
          },
          {
            type: "Call",
            name: "length",
            args: [],
            object: {
              type: "Call",
              name: "int",
              args: [],
              object: {
                type: "Call",
                name: "new",
                args: [],
                object: {
                  type: "Path",
                  value: "MyClass",
                },
                block: nil,
                block_arg: nil,
              },
              block: nil,
              block_arg: nil,
            },
            block: nil,
            block_arg: nil,
          },
        ],
      },
      type_checker
    ).run
    err = catch :error do
      type_checker.run "string", output
    end
    expect(err).to eq "Unknown method :length, location: nil"
  end

  it "reports no errors for valid code" do
    output = Gloss::Visitor.new(
      {
        type: "CollectionNode",
        children: [{
          type: "ClassNode",
          name: {
            type: "Path",
            value: "MyClass",
          },
          body: {
            type: "DefNode",
            name: "int",
            body: {
              type: "Return",
              value: {
                type: "LiteralNode",
                value: "100",
                rb_type: "Integer",
              },
            },
            rp_args: [],
            receiver: nil,
            return_type: {
              type: "Path",
              value: "Integer",
            },
            rest_kw_args: nil,
          },
          superclass: nil,
          type_vars: nil,
          abstract: false,
        },
                   {
          type: "Call",
          name: "positive?",
          args: [],
          object: {
            type: "Call",
            name: "int",
            args: [],
            object: {
              type: "Call",
              name: "new",
              args: [],
              object: {
                type: "Path",
                value: "MyClass",
              },
              block: nil,
              block_arg: nil,
            },
            block: nil,
            block_arg: nil,
          },
          block: nil,
          block_arg: nil,
        }],
      },
      type_checker
    ).run
    expect(type_checker.run("string", output))
  end

  it "reports errors for invalid variables" do
    output = Gloss::Visitor.new(
      {
        type: "TypeDeclaration",
        var: {
          type: "Var",
          name: "str",
        },
        declared_type: {
          type: "Path",
          value: "Symbol",
        },
        value: {
          type: "LiteralNode",
          value: "\"abc\"",
          rb_type: "String",
        },
        var_type: "Var",
      },
      type_checker
    ).run
    err = catch :error do
      type_checker.run "(string)", output
    end
    expect(err).to eq "Invalid assignment - cannot assign ::String to type ::Symbol"
  end

  it "does not report errors for valid variables" do
    output = Gloss::Visitor.new(
      {
        type: "TypeDeclaration",
        var: {
          type: "Var",
          name: "str",
        },
        declared_type: {
          type: "Path",
          value: "String",
        },
        value: {
          type: "LiteralNode",
          value: "\"abc\"",
          rb_type: "String",
        },
        var_type: "Var",
      },
      type_checker
    ).run
    expect(type_checker.run("string", output))
  end

  it "reports errors when changing a variable's type" do
    output = Gloss::Visitor.new(
      {
        type: "CollectionNode",
        children: [{
          type: "TypeDeclaration",
          var: {
            type: "Var",
            name: "str",
          },
          declared_type: {
            type: "Path",
            value: "String",
          },
          value: {
            type: "LiteralNode",
            value: "\"abc\"",
            rb_type: "String",
          },
          var_type: "Var",
        },
                   {
          type: "Assign",
          op: nil,
          target: {
            type: "Var",
            name: "str",
          },
          value: {
            type: "LiteralNode",
            value: ":abc",
            rb_type: "Symbol",
          },
        }],
      },
      type_checker
    ).run
    err = catch :error do
      type_checker.run "(string)", output
    end
    expect(err).to eq "Invalid assignment - cannot assign ::Symbol to type ::String"
  end

  it "throws :error is passed invalid ruby code" do
    ruby_code = "puts 'hello "
    msg = catch :error do
      type_checker.run "(string)", ruby_code
    end

    expect(msg).to eq "Parser::SyntaxError: unterminated string meets end of file"
  end

  context "for module_function" do
    it "does not identify methods above module_function as singleton_instance" do
      gls = <<-GLS
module A
  def not_sing_inst; end

  module_function
end
      GLS
      Gloss::Visitor.new(
        Gloss::Parser.new(gls).run,
        type_checker
      ).run
      type_checker.ready_for_checking!
      a_def = type_checker.env.declarations.find { |d| d.name.name == :A }
      meth = a_def.members.find { |m| m.name == :not_sing_inst }
      expect(meth.kind).to eq :instance
    end

    it "identifies methods below module_function as singleton_instance" do
      gls = <<-GLS
module A
  def not_sing_inst; end

  module_function

  def sing_inst1; end
  def sing_inst2; end
end
      GLS
      Gloss::Visitor.new(
        Gloss::Parser.new(gls).run,
        type_checker
      ).run
      type_checker.ready_for_checking!
      a_def = type_checker.env.declarations.find { |d| d.name.name == :A }
      meth1 = a_def.members.find { |m| m.name == :not_sing_inst }
      meth2 = a_def.members.find { |m| m.name == :sing_inst1 }
      meth3 = a_def.members.find { |m| m.name == :sing_inst2 }
      expect(meth1.kind).to eq :instance
      expect(meth2.kind).to eq :singleton_instance
      expect(meth3.kind).to eq :singleton_instance
    end

    it "does not identify methods in a nested module as singleton_instance" do
      gls = <<-GLS
module A
  module_function

  module B
    def not_sing_inst; end
  end

  def sing_inst; end
end
      GLS
      Gloss::Visitor.new(
        Gloss::Parser.new(gls).run,
        type_checker
      ).run
      type_checker.ready_for_checking!
      a_def = type_checker.env.declarations.find { |d| d.name.name == :A }
      b_def = a_def.members.find { |m| m.name.name == :B }
      meth = b_def.members.find { |m| m.name == :not_sing_inst }
      expect(meth.kind).to eq :instance
      expect(a_def.members.find { |m| m.name == :sing_inst }.kind).to eq :singleton_instance
    end
  end
end
