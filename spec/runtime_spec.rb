RSpec.describe Gloss::Runtime do
  it "successfully parses a hello world" do
    Dir.chdir TESTING_DIR do
      output, err = Gloss::Runtime.process_string("puts  'hello world'")
      expect(err).to be_nil
      expect(output).to eq Gloss::Utils.with_file_header(%{puts("hello world")\n})
    end
  end
end
