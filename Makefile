dirs = main dev extra languages libs

pkgs = $(foreach dir,$(dirs),$(basename $(shell ls $(dir)/*.pkgen)))
tpkgs = $(basename $(shell ls testing/*.pkgen))

ifeq ($(DEST),)
	DEST := $(shell mkdir -p out && realpath out)
endif
ifeq ($(ARCH),)
	ARCH := $(shell file /bin/ls | cut -d ',' -f2 | xargs)
	ifeq ($(ARCH),x86-64)
		ARCH=x86_64
	endif
	ifeq ($(ARCH),Intel 80386)
		ARCH=x86
	endif
endif

ifeq ($(ARCH),x86_64)
	pkgs += kernel/linux
endif

all: $(pkgs)

list:
	@echo Main: $(pkgs)
	@echo Testing: $(tpkgs)

$(pkgs) $(tpkgs):
	bash buildpkg.sh $@ $(DEST) $(ARCH)
