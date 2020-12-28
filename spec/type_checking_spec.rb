require 'hrb'

RSpec.describe Hrb::Builder do
  it "reports type errors in type notations" do
    expect { Hrb::Builder.new(<<~HRB).run }.to raise_error(Hrb::Errors::TypeError)
      class MyClass
        def int : Integer
          return "abc"
        end
      end
    HRB
  end

  it "reports type errors for human error" do
    expect { Hrb::Builder.new(<<~HRB).run }.to raise_error(Hrb::Errors::TypeError)
      class MyClass
        def int : Integer
          return 100
        end
      end

      MyClass.new.int.length
    HRB
  end

  it "reports no errors for valid code" do
    expect(Hrb::Builder.new(<<~HRB).run)
      class MyClass
        def int : Integer
          return 100
        end
      end

      MyClass.new.int.positive?
    HRB
  end

  it "reports errors for invalid variables" do
    expect { Hrb::Builder.new(<<~HRB).run }.to raise_error(Hrb::Errors::TypeError)
      str : Symbol = "abc"
    HRB
  end

  it "does not report errors for valid variables" do
    expect(Hrb::Builder.new(<<~HRB).run)
      str : String = "abc"
    HRB
  end

  it "reports errors when changing a variable's type" do
    expect { Hrb::Builder.new(<<~HRB).run }.to raise_error(Hrb::Errors::TypeError)
      str : String = "abc"
      str = :abc
    HRB
  end
end
