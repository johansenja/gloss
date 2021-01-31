require "fileutils"
require "pathname"
require "gloss"

RSpec.describe Gloss::Watcher do
  DIR = "./tmp"

  before :all do
    Dir.mkdir(DIR) unless Pathname(DIR).exist?
    Dir.chdir(DIR) do
      File.open(".gloss.yml", "wb") do |f|
        f.puts <<~YML
          src_dir: src
          frozen_string_literals: true
        YML
      end
      Dir.mkdir "src"
    end
  end

  after :all do
    FileUtils.rm_r DIR
  end

  it "creates the rb file when the gl file created" do
    expect((Pathname(DIR) / "src" / "new_file.gl").exist?).to be false
    Dir.chdir DIR do
      w = Thread.new { Gloss::Watcher.new([]).watch }
      sleep 0.5
      File.open(File.join("src", "new_file.gl"), "wb") do |f|
        f.puts "puts 'hello world'"
      end
      sleep 3
      w.kill
    end
    expect((Pathname(DIR) / "src" / "new_file.gl").exist?).to be true
    expect((Pathname(DIR) / "new_file.rb").read).to eq Gloss::Utils.with_file_header("puts(\"hello world\")\n")
  end

  it "updates the rb file when the gl file updated" do
    Dir.chdir DIR do
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

    expect((Pathname(DIR) / "new_file.rb").read).to eq Gloss::Utils.with_file_header("puts(\"hello\")\n")
  end

  it "deletes the rb file when the gl file deleted" do
    Dir.chdir DIR do
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
