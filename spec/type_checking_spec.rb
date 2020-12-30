require 'gloss'

RSpec.describe Gloss::Builder do
  it "reports type errors in type notations" do
    expect { Gloss::Builder.new(<<~GLOSS).run }.to raise_error(Gloss::Errors::TypeError)
      class MyClass
        def int : Integer
          return "abc"
        end
      end
    GLOSS
  end

  it "reports type errors for human error" do
    expect { Gloss::Builder.new(<<~GLOSS).run }.to raise_error(Gloss::Errors::TypeError)
      class MyClass
        def int : Integer
          return 100
        end
      end

      MyClass.new.int.length
    GLOSS
  end

  it "reports no errors for valid code" do
    expect(Gloss::Builder.new(<<~GLOSS).run)
      class MyClass
        def int : Integer
          return 100
        end
      end

      MyClass.new.int.positive?
    GLOSS
  end

  it "reports errors for invalid variables" do
    expect { Gloss::Builder.new(<<~GLOSS).run }.to raise_error(Gloss::Errors::TypeError)
      str : Symbol = "abc"
    GLOSS
  end

  it "does not report errors for valid variables" do
    expect(Gloss::Builder.new(<<~GLOSS).run)
      str : String = "abc"
    GLOSS
  end

  it "reports errors when changing a variable's type" do
    expect { Gloss::Builder.new(<<~GLOSS).run }.to raise_error(Gloss::Errors::TypeError)
      str : String = "abc"
      str = :abc
    GLOSS
  end
end
