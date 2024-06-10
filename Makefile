CC = nvcc
OPT =

MAIN = transpose.cu

TARGETDIR := bin

all: $(TARGETDIR)/transpose

debug: OPT += -DDEBUG -g
debug: all

$(TARGETDIR)/transpose: $(MAIN)
	mkdir -p $(@D)
	$(CC) $^ -o $@ $(OPT)

clean:
	rm -rf $(TARGETDIR)