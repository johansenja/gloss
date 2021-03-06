CRYSTAL = crystal
PLATFORM = $(shell uname -s)

ifeq "$(PLATFORM)" "Darwin"
TARGET = ../../lib/gls.bundle

clean:
	rm -f $(TARGET) $(TARGET).dwarf
endif

ifeq "$(PLATFORM)" "Linux"
TARGET = ../../lib/gls.so

clean:
	rm -f $(TARGET)
endif

install: all

all: clean shards build

shards:
	shards

build: ./src/gloss.cr
	$(CRYSTAL) build  --link-flags "-shared -dynamic -Wl,-undefined,dynamic_lookup" $< -o $(TARGET) --release
