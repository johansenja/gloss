# frozen_string_literal: true

module Gloss
  class TypeChecker
    attr_reader :steep_target, :top_level_decls

    def initialize
      @steep_target = Steep::Project::Target.new(
        name: "gloss",
        options: Steep::Project::Options.new,
        source_patterns: ["gloss"],
        ignore_patterns: [],
        signature_patterns: []
      )
      @top_level_decls = {}
      Dir.glob("sig/**/*.rbs").each do |fp|
        next if !@steep_target.possible_signature_file?(fp) || @steep_target.signature_file?(fp)

        Steep.logger.info { "Adding signature file: #{fp}" }
        @steep_target.add_signature path, (Pathname(".") + fp).cleanpath.read
      end
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
      env = env.resolve_type_names

      @steep_target.instance_variable_set("@environment", env)
      @steep_target.add_source("gloss", rb_str)

      definition_builder = RBS::DefinitionBuilder.new(env: env)
      factory = Steep::AST::Types::Factory.new(builder: definition_builder)
      check = Steep::Subtyping::Check.new(factory: factory)
      validator = Steep::Signature::Validator.new(checker: check)
      validator.validate

      raise Errors::TypeValidationError, validator.each_error.to_a.join("\n") unless validator.no_error?

      @steep_target.run_type_check(env, check, Time.now)

      @steep_target.status.is_a?(Steep::Project::Target::TypeCheckStatus) &&
        @steep_target.no_error? &&
        @steep_target.errors.empty?
    end
  end
end
