require "./lib/cr_ruby"
require "./cr_ast"
require "./rb_ast"
require "./parser"

def parse_string(self : CrRuby::VALUE, str : CrRuby::VALUE)
  st = CrRuby.rb_str_to_str(str)
  string = String.new(CrRuby.rb_string_value_cstr(pointerof(st)))

  output = Gloss.parse_string(string)

  CrRuby.rb_str_new_cstr(output)
end

fun init = Init_gls
  GC.init
  LibCrystalMain.__crystal_main(0, Pointer(Pointer(UInt8)).null)
  gloss = CrRuby.rb_define_module("Gloss");
  CrRuby.rb_define_singleton_method(gloss, "parse_buffer", ->parse_string(CrRuby::VALUE, CrRuby::VALUE), 1);
end
