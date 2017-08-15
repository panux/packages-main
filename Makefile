dirs = main dev extra languages libs

pkgs = $(foreach dir,$(dirs),$(basename $(shell ls $(dir)/*.pkgen)))

tpkgs = $(basename $(shell ls testing/*.pkgen))

ifeq ($(ARCH),x86_64)
	pkgs += kernel/linux
endif

all: $(pkgs)

list:
	@echo $(pkgs)

$(pkgs) $(tpkgs):
	bash buildpkg.sh $@ $(DEST) $(ARCH)
