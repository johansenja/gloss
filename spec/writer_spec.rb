require "gloss"
require 'tempfile'
require "fileutils"

RSpec.describe Gloss::Writer do
  it "overwrites an existing file" do
    file = Tempfile.new
    old_content = "abc"
    file.write old_content
    file.close
    new_content = "hello world\n"
    Gloss::Writer.new(new_content, nil, Pathname(file.path)).run
    file.open
    expect(file.read).to eq new_content
    expect(file.read).not_to eq old_content
  ensure
    file.close true
  end

  it "creates a new file if it doesn't exist" do
    begin
      path = Pathname("lib/bar.gl")
      expect(path.exist?).to be false
      Gloss::Writer.new("new file", nil, path).run
      expect(path.exist?).to be true
      expect(path.read).to eq "new file\n"
    ensure
      FileUtils.rm(path)
    end
  end

  it "creates a new directory if it doesn't exist" do
    begin
      path = Pathname("lib/non_existent_foo/bar.gl")
      expect(path.exist?).to be false
      Gloss::Writer.new("new file", nil, path).run
      expect(path.exist?).to be true
      expect(path.read).to eq "new file\n"
    ensure
      FileUtils.rm_rf(path.parent)
    end
  end
end
