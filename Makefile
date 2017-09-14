dirs = main dev extra languages libs graphics

.PHONY: $(dirs)

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

all: $(dirs)

list:
	@echo Main: $(pkgs)
	@echo Testing: $(tpkgs)

listraw:
	@echo $(pkgs)

listrawtesting:
	@echo $(tpkgs)

$(pkgs) $(tpkgs):
	@echo DEST: $(DEST)
	bash buildpkg.sh $@ $(DEST) $(ARCH)

kconf:
	bash tools/kconf.sh

define make-dir-target
  $1: $(basename $(shell ls $1/*.pkgen))
endef

$(foreach dir,$(dirs),$(eval $(call make-dir-target,$(dir))))
