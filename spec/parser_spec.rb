RSpec.describe Gloss::Parser do
  context "on syntax error" do
    it "throws :error" do
      expect { Gloss::Parser.new("puts 'hello world").run }.to throw_symbol :error
    end

    it "gives the context from the program" do
      program = <<-GLOSS
class MyClass
  attr_reader :abc
  def my_method
    a = 1 + 2 {(]
    b = a + 3
  end
end
      GLOSS

      err_msg = catch :error do
        Gloss::Parser.new(program).run
      end

      expect(err_msg).to eq <<-MSG
3|    def my_method
4|      a = 1 + 2 {(]
5|      b = a + 3

syntax error in :4
Error: unexpected token: {
      MSG
    end
  end
end
