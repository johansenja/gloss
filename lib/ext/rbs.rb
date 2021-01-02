# frozen_string_literal: true

module RBS
  module AST
    module Declarations
      class AbstractableClass < Class
        attr_reader :abstract

        def initialize(abstract:, **others)
          super(**others)
          @abstract = abstract
        end

        def ==(other)
          super && other.abstract == abstract
        end

        def hash
          super ^ abstract.hash
        end

        def to_json(*args)
          {
            declaration: :class,
            name: name,
            type_params: type_params,
            members: members,
            super_class: super_class,
            annotations: annotations,
            location: location,
            comment: comment,
            abstract: abstract
          }.to_json(*args)
        end
      end
    end
  end
end
