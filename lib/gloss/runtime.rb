  
  ##### This file was generated by Gloss; any changes made here will be overwritten.
  ##### See / to make changes

require "stringio"
module Gloss
  class Runtime
    NON_EXISTENT_FILEPATH = "__string__"
    def self.process_string(str, options = Config.default_config)
      (if str.empty?
        return ["", nil].freeze
      end)
      out_io = StringIO.new
      error_msg = catch(:"error") { ||
        tree = Parser.new(str)
.run
        tc = TypeChecker.new(".")
        tc = ProgLoader.new(tc, NON_EXISTENT_FILEPATH, str)
.run
        rb_output = Visitor.new(tree, tc)
.run
        tc.run(NON_EXISTENT_FILEPATH, rb_output)
        Writer.new(rb_output, NON_EXISTENT_FILEPATH, out_io)
.run
nil      }
return [out_io.string, error_msg].freeze
    end
  end
end
