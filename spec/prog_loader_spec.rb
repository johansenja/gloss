RSpec.describe Gloss::ProgLoader do
  after do
    Dir.glob("#{TESTING_DIR}/**/*.*").each { |f| File.delete f }
    Gloss::OUTPUT_BY_PATH.clear
  end

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
        entrypoint: "a.gl",
        strict_require: true
      gloss_file "./a.gl", file_a
      gloss_file "./b.gl", file_b
      Gloss.load_config
      tc = Gloss::TypeChecker.new(Gloss::Config.src_dir)
      pl = Gloss::ProgLoader.new(tc)
      expect(pl.run).to be_truthy
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
        entrypoint: "a.gl"
      gloss_file "./a.gl", file_a
      gloss_file "./b.gl", file_b
      Gloss.load_config
      tc = Gloss::TypeChecker.new(Gloss::Config.src_dir)
      pl = Gloss::ProgLoader.new(tc)
      expect(pl.run).to be_truthy
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
        entrypoint: "a.gl"
      gloss_file "./a.gl", file_a
      gloss_file "./b.gl", file_b
      Gloss.load_config
      tc = Gloss::TypeChecker.new(Gloss::Config.src_dir)
      pl = Gloss::ProgLoader.new(tc)
      expect(pl.run).to be_truthy
    end
  end

  context "with strict_require on" do
    context "passing a valid file path" do
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
            entrypoint: "a.gl",
            strict_require: true
          gloss_file "./a.gl", file_a
          gloss_file "./b.gl", file_b
          Gloss.load_config
          tc = Gloss::TypeChecker.new(Gloss::Config.src_dir)
          pl = Gloss::ProgLoader.new(tc)
          expect(pl.run).to be_truthy
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
            entrypoint: "a.gl",
            strict_require: true
          gloss_file "./a.gl", file_a
          gloss_file "./b.gl", file_b
          Gloss.load_config
          tc = Gloss::TypeChecker.new(Gloss::Config.src_dir)
          pl = Gloss::ProgLoader.new(tc)
          expect(pl.run).to be_truthy
        end
      end
    end

    context "passing an invalid file path" do
      it "fails for require" do
        file_a = <<-GLS
    class A
    end

    require "c"

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
            entrypoint: "a.gl",
            strict_require: true
          gloss_file "./a.gl", file_a
          gloss_file "./b.gl", file_b
          Gloss.load_config
          tc = Gloss::TypeChecker.new(Gloss::Config.src_dir)
          pl = Gloss::ProgLoader.new(tc)
          err_msg = catch :error do
            pl.run
          end
          expect(err_msg).to eq "Cannot resolve require path for c"
        end
      end

      it "fails for require_relative" do
        file_a = <<-GLS
    class A
    end

    require_relative "c"

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
            entrypoint: "a.gl",
            strict_require: true
          gloss_file "./a.gl", file_a
          gloss_file "./b.gl", file_b
          Gloss.load_config
          tc = Gloss::TypeChecker.new(Gloss::Config.src_dir)
          pl = Gloss::ProgLoader.new(tc)
          err_msg = catch :error do
            pl.run
          end
          expect(err_msg).to eq "Cannot resolve relative path for c"
        end
      end
    end

    context "for strict type checking" do
      context "if you don't include other files" do
        it "errors if you forget require" do
          file_a = <<-GLS
      B.new
          GLS
          file_b = <<~GLS
      class B
      end
          GLS
          Dir.chdir TESTING_DIR do
            gloss_yml src_dir: ".",
              entrypoint: "a.gl",
              type_checking_strictness: Gloss::TypeChecker::Strictness::Strict,
              strict_require: true
            gloss_file "./a.gl", file_a
            gloss_file "./b.gl", file_b
            Gloss.load_config
            tc = Gloss::TypeChecker.new(Gloss::Config.src_dir)
            pl = Gloss::ProgLoader.new(tc)
            # shouldn't error at this point, as it is not ProgLoader's job to complain about
            # undefined constants
            expect(pl.run).to be_truthy
            rb = Gloss::OUTPUT_BY_PATH[File.absolute_path("a.gl")]
            err_msg = catch :error do
              pl.type_checker.run "a.gl", rb
            end
            expect(err_msg.lstrip).to start_with "Cannot detect the type of the expression"
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
              entrypoint: "a.gl",
              type_checking_strictness: Gloss::TypeChecker::Strictness::Strict,
              strict_require: true
            gloss_file "./a.gl", file_a
            gloss_file "./b.gl", file_b
            Gloss.load_config
            tc = Gloss::TypeChecker.new(Gloss::Config.src_dir)
            pl = Gloss::ProgLoader.new(tc)
            # shouldn't error at this point, as it is not ProgLoader's job to complain about
            # undefined constants
            expect(pl.run).to be_truthy
            rb = Gloss::OUTPUT_BY_PATH[File.absolute_path("a.gl")]
            err_msg = catch :error do
              pl.type_checker.run "a.gl", rb
            end
            expect(err_msg.lstrip).to start_with "Cannot detect the type of the expression"
          end
        end
      end
    end
  end
end
