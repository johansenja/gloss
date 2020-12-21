CRYSTAL = crystal
TARGET = ../../lib/hrb.bundle

install: all

all: clean shards $(TARGET)

shards:
	shards

$(TARGET): ./src/hrb.cr
	$(CRYSTAL) build --link-flags "-dynamic -bundle -Wl,-undefined,dynamic_lookup" $< -o $(TARGET)

clean:
	rm -f ../../**/*.bundle*
