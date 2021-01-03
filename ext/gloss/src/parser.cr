require "compiler/crystal/syntax/*"
require "./lexer"
require "./cr_ast"

module Gloss
  def self.parse_string(string : String)
    tree = Gloss::Parser.parse string
    tree.to_rb.to_json
  end

  class Parser < Crystal::Parser
    parse_operator :or_keyword, :and_keyword, "Or.new left, right", ":or"
    parse_operator :and_keyword, :prefix, "And.new left, right", ":and"
    parse_operator :not_keyword, :or_keyword, "Not.new parse_prefix", ":not"

    def parse_empty_array_literal
      line = @line_number
      column = @token.column_number

      # next_token_skip_space
      # next_token_skip_space_or_newline
      # of = nil
      Crystal::ArrayLiteral.new([] of Crystal::ASTNode) # .at_end(of)
    end

    def new_hash_literal(entries, line, column, end_location, allow_of = true)
      of = nil

      if allow_of
        if @token.keyword?(:of)
          next_token_skip_space_or_newline
          of_key = parse_bare_proc_type
          check :"=>"
          next_token_skip_space_or_newline
          of_value = parse_bare_proc_type
          of = Crystal::HashLiteral::Entry.new(of_key, of_value)
          end_location = of_value.end_location
        end

        # if entries.empty? && !of
        #   raise "for empty hashes use '{} of KeyType => ValueType'", line, column
        # end
      end

      Crystal::HashLiteral.new(entries, of).at_end(end_location)
    end

    def parse_rescue
      next_token_skip_space

      if @token.type == :CONST || @token.type == :"::"
        types = parse_rescue_types
        skip_space
      end

      if @token.type == :"=>"
        next_token_skip_space
      end

      if @token.type == :IDENT
        name = @token.value.to_s
        push_var_name name
        next_token_skip_space
      end

      check SemicolonOrNewLine

      next_token_skip_space_or_newline

      if @token.keyword?(:end)
        body = nil
      else
        body = parse_expressions
        skip_statement_end
      end

      Crystal::Rescue.new(body, types, name)
    end

    def parse_rescue_types
      types = [] of Crystal::ASTNode
      while true
        types << parse_generic
        skip_space
        if @token.type == :","
          next_token_skip_space
        else
          skip_space
          break
        end
      end
      types
    end


    def parse_arg(args, extra_assigns, parentheses, found_default_value, found_splat, found_double_splat, allow_restrictions)
      if @token.type == :"&"
        next_token_skip_space_or_newline
        block_arg = parse_block_arg(extra_assigns)
        skip_space_or_newline
        # When block_arg.name is empty, this is an anonymous argument.
        # An anonymous argument should not conflict other arguments names.
        # (In fact `args` may contain anonymous splat argument. See #9108).
        # So check is skipped.
        unless block_arg.name.empty?
          conflict_arg = args.any?(&.name.==(block_arg.name))
          conflict_double_splat = found_double_splat && found_double_splat.name == block_arg.name
          if conflict_arg || conflict_double_splat
            raise "duplicated argument name: #{block_arg.name}", block_arg.location.not_nil!
          end
        end
        return Crystal::Parser::ArgExtras.new(block_arg, false, false, false)
      end

      if found_double_splat
        raise "only block argument is allowed after double splat"
      end

      splat = false
      double_splat = false
      arg_location = @token.location
      allow_external_name = true

      case @token.type
      when :"*"
        if found_splat
          unexpected_token
        end

        splat = true
        allow_external_name = false
        next_token_skip_space
      when :"**"
        double_splat = true
        allow_external_name = false
        next_token_skip_space
      else
        # not a splat
      end

      found_space = false

      if splat && (@token.type == :"," || @token.type == :")")
        arg_name = ""
        uses_arg = false
        allow_restrictions = false
      else
        arg_location = @token.location
        arg_name, external_name, found_space, uses_arg = parse_arg_name(arg_location, extra_assigns, allow_external_name: allow_external_name)

        args.each do |arg|
          if arg.name == arg_name
            raise "duplicated argument name: #{arg_name}", arg_location
          end

          if arg.external_name == external_name
            raise "duplicated argument external name: #{external_name}", arg_location
          end
        end

        if @token.type == :SYMBOL
          raise "space required after colon in type restriction", @token
        end
      end

      default_value = nil
      restriction = nil
      keyword_arg = false
      found_colon = false

      # KEYWORD ARGUMENTS
      # eg. def abc(a: : String? = "")
      if @token.type == :":" && !found_space
        keyword_arg = true
        next_token_skip_space
        found_space = true
      end

      if allow_restrictions && @token.type == :":"
        if !default_value && !found_space
          raise "space required before colon in type restriction", @token
        end

        next_token_skip_space_or_newline

        location = @token.location
        splat_restriction = false
        if (splat && @token.type == :"*") || (double_splat && @token.type == :"**")
          splat_restriction = true
          next_token
        end

        restriction = parse_bare_proc_type

        if splat_restriction
          restriction = splat ? Crystal::Splat.new(restriction) : Crystal::DoubleSplat.new(restriction)
          restriction.at(location)
        end
        found_colon = true
      end

      if @token.type == :"="
        raise "splat argument can't have default value", @token if splat
        raise "double splat argument can't have default value", @token if double_splat

        slash_is_regex!
        next_token_skip_space_or_newline

        case @token.type
        when :__LINE__, :__END_LINE__, :__FILE__, :__DIR__
          default_value = Crystal::MagicConstant.new(@token.type).at(@token.location)
          next_token
        else
          @no_type_declaration += 1
          default_value = parse_op_assign
          @no_type_declaration -= 1
        end

        skip_space
      else
        if found_default_value && !found_splat && !splat && !double_splat
          raise "argument must have a default value", arg_location
        end
      end

      unless found_colon
        if @token.type == :SYMBOL
          raise "the syntax for an argument with a default value V and type T is `arg : T = V`", @token
        end

        if allow_restrictions && @token.type == :":"
          raise "the syntax for an argument with a default value V and type T is `arg : T = V`", @token
        end
      end

      raise "BUG: arg_name is nil" unless arg_name

      arg = Crystal::Arg.new(arg_name, default_value, restriction, external_name: external_name).at(arg_location)
      arg.keyword_arg = keyword_arg
      args << arg
      push_var arg

      Crystal::Parser::ArgExtras.new(nil, !!default_value, splat, !!double_splat)
    end

    def parse_arg_name(location, extra_assigns, allow_external_name)
      do_next_token = true
      found_string_literal = false
      invalid_internal_name = nil

      if allow_external_name && (@token.type == :IDENT || string_literal_start?)
        if @token.type == :IDENT
          if @token.keyword? && invalid_internal_name?(@token.value)
            invalid_internal_name = @token.dup
          end
          external_name = @token.type == :IDENT ? @token.value.to_s : ""
          next_token
        else
          external_name = parse_string_without_interpolation("external name")
          found_string_literal = true
        end
        found_space = @token.type == :SPACE || @token.type == :NEWLINE
        skip_space
        do_next_token = false
      end

      case @token.type
      when :IDENT
        if @token.keyword? && invalid_internal_name?(@token.value)
          raise "cannot use '#{@token}' as an argument name", @token
        end

        arg_name = @token.value.to_s
        if arg_name == external_name
          raise "when specified, external name must be different than internal name", @token
        end

        uses_arg = false
        do_next_token = true
      when :INSTANCE_VAR
        arg_name = @token.value.to_s[1..-1]
        if arg_name == external_name
          raise "when specified, external name must be different than internal name", @token
        end

        # If it's something like @select, we can't transform it to:
        #
        #     @select = select
        #
        # because if someone uses `to_s` later it will produce invalid code.
        # So we do something like:
        #
        # def method(select __arg0)
        #   @select = __arg0
        # end
        if !external_name && invalid_internal_name?(arg_name)
          arg_name, external_name = temp_arg_name, arg_name
        end

        ivar = Crystal::InstanceVar.new(@token.value.to_s).at(location)
        var = Crystal::Var.new(arg_name).at(location)
        assign = Crystal::Assign.new(ivar, var).at(location)
        if extra_assigns
          extra_assigns.push assign
        else
          raise "can't use @instance_variable here"
        end
        uses_arg = true
        do_next_token = true
      when :CLASS_VAR
        arg_name = @token.value.to_s[2..-1]
        if arg_name == external_name
          raise "when specified, external name must be different than internal name", @token
        end

        # Same case as :INSTANCE_VAR for things like @select
        if !external_name && invalid_internal_name?(arg_name)
          arg_name, external_name = temp_arg_name, arg_name
        end

        cvar = Crystal::ClassVar.new(@token.value.to_s).at(location)
        var = Crystal::Var.new(arg_name).at(location)
        assign = Crystal::Assign.new(cvar, var).at(location)
        if extra_assigns
          extra_assigns.push assign
        else
          raise "can't use @@class_var here"
        end
        uses_arg = true
        do_next_token = true
      else
        if external_name
          if found_string_literal
            raise "unexpected token: #{@token}, expected argument internal name"
          end
          if invalid_internal_name
            raise "cannot use '#{invalid_internal_name}' as an argument name", invalid_internal_name
          end
          arg_name = external_name
        else
          raise "unexpected token: #{@token}"
        end
      end

      if do_next_token
        next_token
        found_space = @token.type == :SPACE || @token.type == :NEWLINE
      end

      skip_space

      {arg_name, external_name, found_space, uses_arg}
    end

    ### USE [] INSTEAD OF CRYSTAL'S ()
    def parse_type_args(name)
      return name unless @token.type == :"["

      next_token_skip_space_or_newline
      args = [] of Crystal::ASTNode
      if named_tuple_start? || string_literal_start?
        named_args = parse_named_type_args(:"]")
      else
        args << parse_type_splat { parse_type_arg }
        while @token.type == :","
          next_token_skip_space_or_newline
          break if @token.type == :"]" # allow trailing comma
          args << parse_type_splat { parse_type_arg }
        end

        has_int = args.any? do |arg|
          arg.is_a?(Crystal::NumberLiteral) ||
            arg.is_a?(Crystal::SizeOf) ||
            arg.is_a?(Crystal::InstanceSizeOf) ||
            arg.is_a?(Crystal::OffsetOf)
        end
        if @token.type == :"->" && !has_int
          args = [parse_proc_type_output(args, args.first.location)] of Crystal::ASTNode
        end
      end

      skip_space_or_newline
      check :"]"
      end_location = token_end_location
      next_token

      Crystal::Generic.new(name, args, named_args).at(name).at_end(end_location)
    end

    def parse_atomic_without_location
      case @token.type
      when :"("
        parse_parenthesized_expression
      when :"[]"
        parse_empty_array_literal
      when :"["
        parse_array_literal
      when :"{"
        parse_hash_or_tuple_literal
      when :"{{"
        parse_percent_macro_expression
      when :"{%"
        parse_percent_macro_control
      when :"::"
        parse_generic_or_global_call
      when :"->"
        parse_fun_literal
      when :"@["
        parse_annotation
      when :NUMBER
        @wants_regex = false
        node_and_next_token Crystal::NumberLiteral.new(@token.value.to_s, @token.number_kind)
      when :CHAR
        node_and_next_token Crystal::CharLiteral.new(@token.value.as(Char))
      when :STRING, :DELIMITER_START
        parse_delimiter
      when :STRING_ARRAY_START
        parse_string_array
      when :SYMBOL_ARRAY_START
        parse_symbol_array
      when :SYMBOL
        node_and_next_token Crystal::SymbolLiteral.new(@token.value.to_s)
      when :GLOBAL
        new_node_check_type_declaration Crystal::Global
      when :"$~", :"$?"
        location = @token.location
        var = Crystal::Var.new(@token.to_s).at(location)

        old_pos, old_line, old_column = current_pos, @line_number, @column_number
        @temp_token.copy_from(@token)

        next_token_skip_space

        if @token.type == :"="
          @token.copy_from(@temp_token)
          self.current_pos, @line_number, @column_number = old_pos, old_line, old_column

          push_var var
          node_and_next_token var
        else
          @token.copy_from(@temp_token)
          self.current_pos, @line_number, @column_number = old_pos, old_line, old_column

          node_and_next_token Crystal::Global.new(var.name).at(location)
        end
      when :GLOBAL_MATCH_DATA_INDEX
        value = @token.value.to_s
        if value_prefix = value.rchop? '?'
          method = "[]?"
          value = value_prefix
        else
          method = "[]"
        end
        location = @token.location
        node_and_next_token Crystal::Call.new(Crystal::Global.new("$~").at(location), method, Crystal::NumberLiteral.new(value.to_i))
      when :__LINE__
        node_and_next_token Crystal::MagicConstant.expand_line_node(@token.location)
      when :__END_LINE__
        raise "__END_LINE__ can only be used in default argument value", @token
      when :__FILE__
        node_and_next_token Crystal::MagicConstant.expand_file_node(@token.location)
      when :__DIR__
        node_and_next_token Crystal::MagicConstant.expand_dir_node(@token.location)
      when :IDENT
        # NOTE: Update `Parser#invalid_internal_name?` keyword list
        # when adding or removing keyword to handle here.
        case @token.value
        when :begin
          check_type_declaration { parse_begin }
        when :nil
          check_type_declaration { node_and_next_token Crystal::NilLiteral.new }
        when :true
          check_type_declaration { node_and_next_token Crystal::BoolLiteral.new(true) }
        when :false
          check_type_declaration { node_and_next_token Crystal::BoolLiteral.new(false) }
        when :yield
          check_type_declaration { parse_yield }
        when :with
          check_type_declaration { parse_yield_with_scope }
        when :abstract
          check_type_declaration do
            check_not_inside_def("can't use abstract") do
              doc = @token.doc

              next_token_skip_space_or_newline
              case @token.type
              when :IDENT
                case @token.value
                when :def
                  parse_def is_abstract: true, doc: doc
                when :class
                  parse_class_def is_abstract: true, doc: doc
                when :struct
                  parse_class_def is_abstract: true, is_struct: true, doc: doc
                else
                  unexpected_token
                end
              else
                unexpected_token
              end
            end
          end
        when :def
          check_type_declaration do
            check_not_inside_def("can't define def") do
              parse_def
            end
          end
        when :macro
          check_type_declaration do
            check_not_inside_def("can't define macro") do
              parse_macro
            end
          end
        when :require
          check_type_declaration do
            check_not_inside_def("can't require") do
              parse_require
            end
          end
        when :case
          check_type_declaration { parse_case }
        when :select
          check_type_declaration { parse_select }
        when :if
          check_type_declaration { parse_if }
        when :unless
          check_type_declaration { parse_unless }
        when :include
          check_type_declaration do
            check_not_inside_def("can't include") do
              parse_include
            end
          end
        when :extend
          check_type_declaration do
            check_not_inside_def("can't extend") do
              parse_extend
            end
          end
        when :class
          check_type_declaration do
            check_not_inside_def("can't define class") do
              parse_class_def
            end
          end
        when :struct
          check_type_declaration do
            check_not_inside_def("can't define struct") do
              parse_class_def is_struct: true
            end
          end
        when :module
          check_type_declaration do
            check_not_inside_def("can't define module") do
              parse_module_def
            end
          end
        when :enum
          check_type_declaration do
            check_not_inside_def("can't define enum") do
              parse_enum_def
            end
          end
        when :while
          check_type_declaration { parse_while }
        when :until
          check_type_declaration { parse_until }
        when :return
          check_type_declaration { parse_return }
        when :next
          check_type_declaration { parse_next }
        when :break
          check_type_declaration { parse_break }
        when :lib
          check_type_declaration do
            check_not_inside_def("can't define lib") do
              parse_lib
            end
          end
        when :fun
          check_type_declaration do
            check_not_inside_def("can't define fun") do
              parse_fun_def top_level: true, require_body: true
            end
          end
        when :alias
          check_type_declaration do
            check_not_inside_def("can't define alias") do
              parse_alias
            end
          end
        when :pointerof
          check_type_declaration { parse_pointerof }
        when :sizeof
          check_type_declaration { parse_sizeof }
        when :instance_sizeof
          check_type_declaration { parse_instance_sizeof }
        when :offsetof
          check_type_declaration { parse_offsetof }
        when :typeof
          check_type_declaration { parse_typeof }
        when :private
          check_type_declaration { parse_visibility_modifier Crystal::Visibility::Private }
        when :protected
          check_type_declaration { parse_visibility_modifier Crystal::Visibility::Protected }
        when :asm
          check_type_declaration { parse_asm }
        when :annotation
          check_type_declaration do
            check_not_inside_def("can't define annotation") do
              parse_annotation_def
            end
          end
        else
          set_visibility parse_var_or_call
        end
      when :CONST
        parse_generic_or_custom_literal
      when :INSTANCE_VAR
        if @in_macro_expression && @token.value == "@type"
          @is_macro_def = true
        end
        new_node_check_type_declaration Crystal::InstanceVar
      when :CLASS_VAR
        new_node_check_type_declaration Crystal::ClassVar
      when :UNDERSCORE
        node_and_next_token Crystal::Underscore.new
      else
        unexpected_token_in_atomic
      end
    end
  end
end
