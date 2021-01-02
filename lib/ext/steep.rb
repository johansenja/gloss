# frozen_string_literal: true

require "steep"

module Steep
  class TypeConstruction
    def type_send(node, send_node:, block_params:, block_body:, unwrap: false)
      receiver, method_name, *arguments = send_node.children
      recv_type, constr = receiver ? synthesize(receiver) : [AST::Types::Self.new, self]

      if unwrap
        recv_type = unwrap(recv_type)
      end

      receiver_type = checker.factory.deep_expand_alias(recv_type)

      type, constr = case receiver_type
                     when nil
                       raise

                     when AST::Types::Any
                       constr = constr.synthesize_children(node, skips: [receiver])
                       constr.add_call(
                         TypeInference::MethodCall::Untyped.new(
                           node: node,
                           context: context.method_context,
                           method_name: method_name
                         )
                       )

                     when AST::Types::Void, AST::Types::Bot, AST::Types::Top, AST::Types::Var
                       constr = constr.synthesize_children(node, skips: [receiver])
                       constr.add_call(
                         TypeInference::MethodCall::NoMethodError.new(
                           node: node,
                           context: context.method_context,
                           method_name: method_name,
                           receiver_type: receiver_type,
                           error: Diagnostic::Ruby::NoMethod.new(node: node, method: method_name, type: receiver_type)
                         )
                       )

                     when AST::Types::Self
                       expanded_self = expand_self(receiver_type)

                       if expanded_self.is_a?(AST::Types::Self)
                         Steep.logger.debug { "`self` type cannot be resolved to concrete type" }

                         constr = constr.synthesize_children(node, skips: [receiver])
                         constr.add_call(
                           TypeInference::MethodCall::NoMethodError.new(
                             node: node,
                             context: context.method_context,
                             method_name: method_name,
                             receiver_type: receiver_type,
                             error: Diagnostic::Ruby::NoMethod.new(node: node, method: method_name, type: receiver_type)
                           )
                         )
                       else
                         interface = checker.factory.interface(expanded_self,
                                                               private: !receiver,
                                                               self_type: AST::Types::Self.new)

                         constr.type_send_interface(node,
                                                    interface: interface,
                                                    receiver: receiver,
                                                    receiver_type: expanded_self,
                                                    method_name: method_name,
                                                    arguments: arguments,
                                                    block_params: block_params,
                                                    block_body: block_body)
                       end
                     else
                       ce = TypeInference::ConstantEnv.new(context: context, factory: checker.factory)
                       rbs_constant = ce.lookup(recv_type.name)

                       if rbs_constant.abstract
                         add_call(
                           TypeInference::MethodCall::Error.new(
                             node: node,
                             context: context.method_context,
                             method_name: method_name,
                             receiver_type: receiver_type,
                             errors: [
                               Diagnostic::Ruby::CallingAbstractClass.new(
                                 node: node,
                                 class_name: recv_type.name,
                                 method_name: method_name
                               )
                             ]
                           )
                         )
                       end

                       interface = checker.factory.interface(receiver_type,
                                                             private: !receiver,
                                                             self_type: receiver_type)

                       constr.type_send_interface(node,
                                                  interface: interface,
                                                  receiver: receiver,
                                                  receiver_type: receiver_type,
                                                  method_name: method_name,
                                                  arguments: arguments,
                                                  block_params: block_params,
                                                  block_body: block_body)
                     end

      Pair.new(type: type, constr: constr)
    rescue => exn
      case exn
      when RBS::NoTypeFoundError, RBS::NoMixinFoundError, RBS::NoSuperclassFoundError, RBS::InvalidTypeApplicationError
        # ignore known RBS errors.
      else
        Steep.log_error(exn, message: "Unexpected error in #type_send: #{exn.message} (#{exn.class})")
      end

      error = Diagnostic::Ruby::UnexpectedError.new(node: node, error: exn)

      type_any_rec(node)

      add_call(
        TypeInference::MethodCall::Error.new(
          node: node,
          context: context.method_context,
          method_name: method_name,
          receiver_type: receiver_type,
          errors: [error]
        )
      )
    end
  end

  module Diagnostic
    module Ruby
      class CallingAbstractClass < Base
        def initialize(node:, class_name:, method_name:)
          super(node: node)
          @class_name, @method_name = class_name, method_name
        end

        def to_s
          format_message "Cannot call method #{@method_name} on abstract class #{@class_name}"
        end
      end
    end
  end
end
