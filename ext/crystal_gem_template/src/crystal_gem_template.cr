require "./lib/cr_ruby"

def hello(addressee : String)
  "hello #{addressee}"
end

def hello_wrapper(self : CrRuby::VALUE, addressee : CrRuby::VALUE)
  # definitely nice to extract this sort of thing
  plain_addressee = CrRuby.rb_str_to_str(addressee)
  c_addressee = CrRuby.rb_string_value_cstr(pointerof(plain_addressee))
  crystal_addressee = String.new(c_addressee)

  hello_addressee = hello(crystal_addressee)

  CrRuby.rb_str_new_cstr(hello_addressee)
end

fun init = Init_crystal_gem_template
  GC.init
  LibCrystalMain.__crystal_main(0, Pointer(Pointer(UInt8)).null)

  crystal_gem_template = CrRuby.rb_define_module("CrystalGemTemplate")
  CrRuby.rb_define_method(crystal_gem_template, "hello", ->hello_wrapper, 1)
end
