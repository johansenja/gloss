require 'pry-byebug'
RSpec.describe Hrb do
  describe ".parse_buffer" do
    it "outputs a string" do
      binding.pry
      out = Hrb.parse_buffer('puts "hello world"')
      expect(out.class).to eq String
      expect(out.length).to be_positive
    end

    it "outputs valid JSON" do
      require "json"
      out = Hrb.parse_buffer('puts "hello world"')
      expect(JSON.parse(out))
    end
  end
end
