RSpec.describe Gloss::Runtime do
  before :all do
    Gloss::Config = OpenStruct.new(
      default_config: Gloss::Config.default_config
    )
  end

  it "successfully parses a hello world" do
    Dir.chdir TESTING_DIR do
      output, err = Gloss::Runtime.process_string("puts  'hello world'")
      expect(err).to be_nil
      expect(output).to eq Gloss::Utils.with_file_header(%{puts("hello world")\n})
    end
  end

  it "successfully parses an empty string" do
    Dir.chdir TESTING_DIR do
      output, err = Gloss::Runtime.process_string("")
      expect(err).to be_nil
      expect(output).to eq ""
    end
  end
end
