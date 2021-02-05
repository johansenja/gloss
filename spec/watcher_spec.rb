RSpec.describe Gloss::Watcher do
  before :all do
    Dir.chdir(TESTING_DIR) do
      File.open(Gloss::CONFIG_PATH, "wb") do |f|
        f.puts <<~YML
          src_dir: src
          frozen_string_literals: true
        YML
      end
    end
  end

  it "creates the rb file when the gl file created" do
    expect((Pathname(TESTING_DIR) / "src" / "new_file.gl").exist?).to be false
    Dir.chdir TESTING_DIR do
      w = Thread.new { Gloss::Watcher.new([]).watch }
      sleep 0.5
      File.open(File.join("src", "new_file.gl"), "wb") do |f|
        f.puts "puts 'hello world'"
      end
      sleep 3
      w.kill
    end
    expect((Pathname(TESTING_DIR) / "src" / "new_file.gl").exist?).to be true
    expect((Pathname(TESTING_DIR) / "new_file.rb").read).to eq Gloss::Utils.with_file_header("puts(\"hello world\")\n")
  end

  it "updates the rb file when the gl file updated" do
    Dir.chdir TESTING_DIR do
      Dir.chdir "src" do
        File.open("new_file.gl", "wb") do |f|
          f.puts "puts 'hello world'"
        end
      end
      expect(File.open(File.join("src", "new_file.gl")).read).to eq "puts 'hello world'\n"

      w = Thread.new { Gloss::Watcher.new([]).watch }
      sleep 0.5
      File.open(File.join("src", "new_file.gl"), "wb") do |f|
        f.puts "puts 'hello'"
      end
      sleep 3
      w.kill
    end

    expect((Pathname(TESTING_DIR) / "new_file.rb").read).to eq Gloss::Utils.with_file_header("puts(\"hello\")\n")
  end

  it "deletes the rb file when the gl file deleted" do
    Dir.chdir TESTING_DIR do
      Dir.chdir "src" do
        File.open("new_file.gl", "wb") do |f|
          f.puts "puts 'hello world'"
        end
      end
      File.open("new_file.rb", "wb") { |f| f.puts 'puts "hello world"'}

      expect(File.open(File.join("src", "new_file.gl")).read).to eq "puts 'hello world'\n"
      w = Thread.new { Gloss::Watcher.new([]).watch }
      sleep 0.5
      File.delete(File.join("src", "new_file.gl"))
      sleep 3
      w.kill
      expect(Pathname("new_file.rb").exist?).to be false
    end
  end
end
