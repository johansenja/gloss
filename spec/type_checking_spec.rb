require "gloss/type_checker"
require "gloss/builder"

RSpec.describe Gloss::TypeChecker do
  let!(:type_checker) { Gloss::TypeChecker.new }

  it "reports type errors in type notations" do
    output = Gloss::Builder.new(
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
    expect { type_checker.run(output) }.to raise_error(Gloss::Errors::TypeError)
  end

  it "reports type errors for human error" do
    output = Gloss::Builder.new(
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
    expect { type_checker.run(output) }.to raise_error(Gloss::Errors::TypeError)
  end

  it "reports no errors for valid code" do
    output = Gloss::Builder.new(
      {
        type:"CollectionNode",
        children:[{
          type:"ClassNode",
          name:{
            type:"Path",
            value:"MyClass"
          },
          body:{
            type:"DefNode",
            name:"int",
            body:{
              type:"Return",
              value:{
                type:"LiteralNode",
                value:"100",
                rb_type:"Integer"
              }
            },
            rp_args:[],
            receiver:nil,
            return_type:{
              type:"Path",
              value:"Integer"
            },
            rest_kw_args:nil
          },
          superclass:nil,
          type_vars:nil,
          abstract:false
        },
        {
          type:"Call",
          name:"positive?",
          args:[],
          object:{
            type:"Call",
            name:"int",
            args:[],
            object:{
              type:"Call",
              name:"new",
              args:[],
              object:{
                type:"Path",
                value:"MyClass"
              },
              block:nil,
              block_arg:nil
            },
            block:nil,
            block_arg:nil
          },
          block:nil,
          block_arg:nil
        }]
      },
      type_checker
    ).run
    expect(type_checker.run(output))
  end

  it "reports errors for invalid variables" do
    output = Gloss::Builder.new(
      {
        type:"TypeDeclaration",
        var:{
          type:"Var",
          name:"str"
        },
        declared_type:{
          type:"Path",
          value:"Symbol"
        },
        value:{
          type:"LiteralNode",
          value:"\"abc\"",
          rb_type:"String"
        },
        var_type:"Var"
      },
      type_checker
    ).run
    expect { type_checker.run(output) }.to raise_error(Gloss::Errors::TypeError)
  end

  it "does not report errors for valid variables" do
    output = Gloss::Builder.new(
      {
        type:"TypeDeclaration",
        var:{
          type:"Var",
          name:"str"
        },
        declared_type:{
          type:"Path",
          value:"String"
        },
        value:{
          type:"LiteralNode",
          value:"\"abc\"",
          rb_type:"String"
        },
        var_type:"Var"
      },
      type_checker
    ).run
    expect(type_checker.run(output))
  end

  it "reports errors when changing a variable's type" do
    output = Gloss::Builder.new(
      {
        type:"CollectionNode",
        children:[{
          type:"TypeDeclaration",
          var:{
            type:"Var",
            name:"str"
          },
          declared_type:{
            type:"Path",
            value:"String"
          },
          value:{
            type:"LiteralNode",
            value:"\"abc\"",
            rb_type:"String"
          },
          var_type:"Var"
        },
        {
          type:"Assign",
          op:nil,
          target:{
            type:"Var",
            name:"str"
          },
          value:{
            type:"LiteralNode",
            value:":abc",
            rb_type:"Symbol"
          }
        }]
      },
      type_checker
    ).run
    expect { type_checker.run(output) }.to raise_error(Gloss::Errors::TypeError)
  end
end
