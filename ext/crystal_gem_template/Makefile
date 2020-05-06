CRYSTAL = crystal
TARGET = ../../lib/crystal_gem_template.bundle

install: all

all: shards $(TARGET)

shards:
	shards

$(TARGET): ./src/crystal_gem_template.cr
	$(CRYSTAL) $< --link-flags "-dynamic -bundle -Wl,-undefined,dynamic_lookup" -o $(TARGET)

clean:
	rm -f *.bundle
