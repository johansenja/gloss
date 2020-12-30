require "./lib/cr_ruby"
require "./cr_ast"
require "./rb_ast"
require "./parser"

def parse_buffer(self : CrRuby::VALUE, buffer : CrRuby::VALUE)
  plain_buffer = CrRuby.rb_str_to_str(buffer)
  c_buffer = CrRuby.rb_string_value_cstr(pointerof(plain_buffer))
  crystal_buffer = String.new(c_buffer)

  output = parse_buffer(crystal_buffer)

  CrRuby.rb_str_new_cstr(output)
end

def parse_buffer(buffer : String)
  begin
    tree = Gloss::Parser.parse buffer
    tree.to_rb.to_json
  rescue e : Crystal::SyntaxException
    pp e.backtrace
    e.to_s
  end
end

fun init = Init_gloss
  GC.init
  LibCrystalMain.__crystal_main(0, Pointer(Pointer(UInt8)).null)
  gloss = CrRuby.rb_define_module("Gloss");
  CrRuby.rb_define_singleton_method(gloss, "parse_buffer", ->parse_buffer(CrRuby::VALUE, CrRuby::VALUE), 1);
end
