require 'hrb'

RSpec.describe Hrb::Program do
  it "reports type errors in type notations" do
    expect { Hrb::Program.new(<<~HRB).output }.to raise_error(Hrb::Errors::TypeError)
      class MyClass
        def int : Integer
          return "abc"
        end
      end
    HRB
  end

  it "reports type errors for human error" do
    expect { Hrb::Program.new(<<~HRB).output }.to raise_error(Hrb::Errors::TypeError)
      class MyClass
        def int : Integer
          return 100
        end
      end

      MyClass.new.int.length
    HRB
  end

  it "reports no errors for valid code" do
    expect(Hrb::Program.new(<<~HRB).output)
      class MyClass
        def int : Integer
          return 100
        end
      end

      MyClass.new.int.positive?
    HRB
  end
end
