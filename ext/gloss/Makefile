CRYSTAL = crystal
TARGET = ../../lib/gls

PLATFORM = $(shell uname -s)

ifeq "$(PLATFORM)" "Darwin"
install: all

all: clean shards build

shards:
	shards

build: ./src/gloss.cr
	$(CRYSTAL) build  --link-flags "-dynamic -bundle -Wl,-undefined,dynamic_lookup" $< -o $(TARGET).bundle

clean:
	rm -f $(TARGET).bundle
	rm -f $(TARGET).bundle.dwarf
endif

ifeq "$(PLATFORM)" "Linux"
LLVM_TARGET = "$(shell uname -m)-unknown-linux-gnu"
install: all

all: clean shards build

shards:
	shards

build: ./src/gloss.cr
	$(CRYSTAL) build $< --cross-compile --target $(LLVM_TARGET) --link-flags "-dynamic -bundle -Wl,-undefined,dynamic_lookup" -o $(TARGET)

clean:
	rm -f $(TARGET).o
	rm -f $(TARGET).so
endif
