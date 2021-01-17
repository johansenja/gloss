# frozen_string_literal: true

module Gloss
  class TypeChecker
    Project = Struct.new :targets

    attr_reader :steep_target, :top_level_decls

    def initialize
      @steep_target = Steep::Project::Target.new(
        name: "gloss",
        options: Steep::Project::Options.new,
        source_patterns: ["gloss.rb"],
        ignore_patterns: [],
        signature_patterns: ["sig"]
      )
      @top_level_decls = {}
    end

    def run(rb_str)
      unless check_types(rb_str)
        raise Errors::TypeError,
              @steep_target.errors.map { |e|
                case e
                when Steep::Errors::NoMethod
                  "Unknown method :#{e.method}, location: #{e.type.location.inspect}"
                when Steep::Errors::MethodBodyTypeMismatch
                  "Invalid method body type - expected: #{e.expected}, actual: #{e.actual}"
                when Steep::Errors::IncompatibleArguments
                  "Invalid argmuents - method type: #{e.method_type}, receiver type: #{e.receiver_type}"
                when Steep::Errors::ReturnTypeMismatch
                  "Invalid return type - expected: #{e.expected}, actual: #{e.actual}"
                when Steep::Errors::IncompatibleAssignment
                  "Invalid assignment - cannot assign #{e.rhs_type} to type #{e.lhs_type}"
                else
                  e.inspect
                end
              }.join("\n")
      end

      true
    end

    def check_types(rb_str)
      env_loader = RBS::EnvironmentLoader.new
      env = RBS::Environment.from_loader(env_loader)

      @top_level_decls.each do |_, decl|
        env << decl
      end

      @steep_target.instance_variable_set("@environment", env)
      project = Steep::Project.new(steepfile_path: Pathname(Config.src_dir).realpath)
      project.targets << @steep_target
      loader = Steep::Project::FileLoader.new(project: project)
      loader.load_signatures

      @steep_target.add_source("gloss.rb", p(rb_str))
      @steep_target.type_check

      @steep_target.status.is_a?(Steep::Project::Target::TypeCheckStatus) &&
        @steep_target.no_error? &&
        @steep_target.errors.empty?
    end
  end
end
