CRYSTAL = crystal
TARGET = ../../lib/gloss.bundle

install: all

all: clean shards $(TARGET)

shards:
	shards

$(TARGET): ./src/gloss.cr
	$(CRYSTAL) build --link-flags "-dynamic -bundle -Wl,-undefined,dynamic_lookup" $< -o $(TARGET)

clean:
	rm -f ../../**/*.bundle*
