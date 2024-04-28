CC = c++
OPT = -std=c++11 -O3

MAIN = transpose.cpp

TARGETDIR := bin

all: $(TARGETDIR)/transpose

debug: OPT += -DDEBUG -g
debug: all

$(TARGETDIR)/transpose: $(MAIN)
	mkdir -p $(@D)
	$(CC) $^ -o $@ $(OPT)

clean:
	rm -rf $(TARGETDIR)
