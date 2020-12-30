require "mkmf"
# $makefile_created = true
find_executable("crystal") or abort <<~ERR
  You need crystal installed to use this gem.
  Please check out https://crystal-lang.org/ for information on how to install it.
ERR
# $LDFLAGS = "-rdynamic -L/usr/local/Cellar/crystal/0.35.1_1/embedded/lib -L/usr/local/lib -lpcre -lgc -lpthread /usr/local/Cellar/crystal/0.35.1_1/src/ext/libcrystal.a -L/usr/local/Cellar/libevent/2.1.12/lib -levent -liconv -ldl -Llib -lgloss"
# $LDFLAGS << " -Wl,-undefined,dynamic_lookup -Llib -lgloss "

create_makefile "gloss"
# $(CRYSTAL) $< --link-flags "-dynamic -bundle -Wl,-undefined,dynamic_lookup" -o $(TARGET)

# I feel like a bad person
# File.open(File.join(__dir__, "Makefile"), "w") do |f|
#   f.write <<~MAKEFILE
#     CRYSTAL = crystal
#     TARGET = ../../lib/gloss.bundle

#     install: all

#     all: clean shards $(TARGET)

#     shards:
#       shards

#     $(TARGET): ./src/gloss.cr
#       $(CRYSTAL) build --link-flags "-dynamic -bundle -Wl,-undefined,dynamic_lookup" $< -o $(TARGET)

#     clean:
#       rm -f ../../**/*.bundle*
#   MAKEFILE
# end
