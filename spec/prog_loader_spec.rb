RSpec.describe Gloss::ProgLoader do
  it "ensures paths required in other files are known" do
    file_a = <<-GLS
require_relative "b"

JSON.parse("{}")
    GLS
    file_b = <<~GLS
      require 'json'
    GLS
    Dir.chdir TESTING_DIR do
      gloss_yml src_dir: ".",
        app_entrypoint: "a.gl"
      gloss_file "./a.gl", file_a
      gloss_file "./b.gl", file_b
      tc = Gloss::TypeChecker.new
      rb = Gloss::Visitor.new(Gloss::Parser.new(file_a).run, tc).run
      expect(tc.run("a.gl", rb)).to be_truthy
    end
  end

  it "ensures constants from other files are known" do
    file_a = <<-GLS
require_relative "b"

B.new
    GLS
    file_b = <<~GLS
      class B
end
    GLS
    Dir.chdir TESTING_DIR do
      gloss_yml src_dir: ".",
        app_entrypoint: "a.gl"
      gloss_file "./a.gl", file_a
      gloss_file "./b.gl", file_b
      tc = Gloss::TypeChecker.new
      rb = Gloss::Visitor.new(Gloss::Parser.new(file_a).run, tc).run
      expect(tc.run("a.gl", rb)).to be_truthy
    end
  end

  it "ensures constants from other files are added to" do
    file_a = <<-GLS
class A
end

require_relative "b"

A::B.new
    GLS
    file_b = <<~GLS
      class A
  class B
  end
end
    GLS
    Dir.chdir TESTING_DIR do
      gloss_yml src_dir: ".",
        app_entrypoint: "a.gl"
      gloss_file "./a.gl", file_a
      gloss_file "./b.gl", file_b
      tc = Gloss::TypeChecker.new
      rb = Gloss::Visitor.new(Gloss::Parser.new(file_a).run, tc).run
      expect(tc.run("a.gl", rb)).to be_truthy
    end
  end

  context "if you don't include other files" do
    it "errors if you forget require" do
      file_a = <<-GLS
  # require "./b"

  JSON.parse("{}")
      GLS
      file_b = <<~GLS
        require 'json'
      GLS
      Dir.chdir TESTING_DIR do
        gloss_yml src_dir: ".",
          app_entrypoint: "a.gl"
        gloss_file "./a.gl", file_a
        gloss_file "./b.gl", file_b
        tc = Gloss::TypeChecker.new
        rb = Gloss::Visitor.new(Gloss::Parser.new(file_a).run, tc).run
        err_msg = catch :error do
          tc.run "a.gl", rb
        end
        expect(err_msg).to eq 'foo'
      end
    end

    it "errors if you forget require_relative" do
      file_a = <<-GLS
  B.new
      GLS
      file_b = <<-GLS
  class B
  end
      GLS
      Dir.chdir TESTING_DIR do
        gloss_yml src_dir: ".",
          app_entrypoint: "a.gl"
        gloss_file "./a.gl", file_a
        gloss_file "./b.gl", file_b
        tc = Gloss::TypeChecker.new
        rb = Gloss::Visitor.new(Gloss::Parser.new(file_a).run, tc).run
        err_msg = catch :error do
          tc.run "a.gl", rb
        end
        expect(err_msg).to eq 'foo'
      end
    end
  end
end
