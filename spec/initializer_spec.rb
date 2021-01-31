RSpec.describe Gloss::Initializer do
  context "without a .gloss.yml" do
    after :each do
      File.delete(File.join(TESTING_DIR, Gloss::CONFIG_PATH))
    end

    it "creates one" do
      Dir.chdir TESTING_DIR do
        expect(File.exist?(Gloss::CONFIG_PATH)).to be false
        Gloss::Initializer.new(false).run
        expect(File.exist?(Gloss::CONFIG_PATH)).to be true
      end
    end
  end

  context "with a .gloss.yml" do
    before :all do
      Dir.chdir TESTING_DIR do
        Gloss::Initializer.new(false).run
      end
    end

    it "doesn't create one" do
      Dir.chdir TESTING_DIR do
        expect(File.exist?(Gloss::CONFIG_PATH)).to be true
        err_msg = catch :error do
          Gloss::Initializer.new(false).run
        end
        expect(err_msg).to eq "#{Gloss::CONFIG_PATH} file already exists - aborting. Use --force to override."
      end
    end

    it "creates one if `force`" do
      Dir.chdir TESTING_DIR do
        expect(File.exist?(Gloss::CONFIG_PATH)).to be true
        File.open(Gloss::CONFIG_PATH, "wb") do |f|
          f.puts({ "src_dir" => ".", "frozen_string_literals": false }.to_yaml)
        end
        Gloss::Initializer.new(true).run
        expect(File.exist?(Gloss::CONFIG_PATH))
        default_config = YAML.safe_load(File.read(Gloss::CONFIG_PATH))
        expect(default_config["src_dir"]).to eq "src"
        expect(default_config["frozen_string_literals"]).to be true
      end
    end
  end
end
