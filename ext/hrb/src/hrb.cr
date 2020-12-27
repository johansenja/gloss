require "./lib/cr_ruby"
require "./cr_ast"
require "./rb_ast"
require "./parser"

# fun pb = parse_buffer(buffer : UInt8*)
#   tree = Crystal::Parser.parse(String.new(buffer))
#   return CrRuby.rb_str_new_cstr(tree.to_rb.to_json)
# end

def pb(self : CrRuby::VALUE, buffer : CrRuby::VALUE)
  plain_buffer = CrRuby.rb_str_to_str(buffer)
  c_buffer = CrRuby.rb_string_value_cstr(pointerof(plain_buffer))
  crystal_buffer = String.new(c_buffer)

  output = parse_buffer(crystal_buffer)

  if output
    CrRuby.rb_str_new_cstr(output)
  end
end

# fun init = crystal_init : Void
#   GC.init
#   LibCrystalMain.__crystal_main(0, Pointer(Pointer(UInt8)).null)
# end

def parse_buffer(buffer : String)
  begin
    tree = Hrb::Parser.parse buffer
    tree.to_rb.to_json
  rescue e
    e.message
  end
end

fun init = Init_hrb
  GC.init
  LibCrystalMain.__crystal_main(0, Pointer(Pointer(UInt8)).null)
  hrb = CrRuby.rb_define_module("Hrb");
  CrRuby.rb_define_singleton_method(hrb, "parse_buffer", ->pb(CrRuby::VALUE, CrRuby::VALUE), 1);
end
