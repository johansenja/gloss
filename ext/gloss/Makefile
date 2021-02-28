CRYSTAL = crystal
TARGET = ../../lib/gls
PLATFORM = $(shell uname -s)

install: all

all: clean shards build

shards:
	shards

ifeq "$(PLATFORM)" "Darwin"
build: ./src/gloss.cr
	$(CRYSTAL) build  --link-flags "-dynamic -bundle -Wl,-undefined,dynamic_lookup" $< -o $(TARGET).bundle --no-debug --release
endif

ifeq "$(PLATFORM)" "Linux"
build: ./src/gloss.cr
	$(CRYSTAL) build $< --link-flags -lruby -o $(TARGET).so --no-debug --release
endif

clean:
	rm -f $(TARGET).*
