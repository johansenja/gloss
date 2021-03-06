CRYSTAL = crystal
PLATFORM = $(shell uname -s)

ifeq "$(PLATFORM)" "Darwin"
TARGET = ../../lib/gls.bundle
else
TARGET = ../../lib/gls.so
endif

install: all

all: clean shards build

shards:
	shards

build: ./src/gloss.cr
	$(CRYSTAL) build  --link-flags "-shared -Wl,-undefined,dynamic_lookup" $< -o $(TARGET) --release

clean:
	rm -f $(TARGET)
	rm -f $(TARGET).dwarf
