dirs = main dev extra languages libs graphics server

.PHONY: $(dirs)

rpkgs = $(foreach dir,$(dirs),$(shell ls $(dir)/*.pkgen))
rtpkgs = $(shell ls testing/*.pkgen)

.PHONY: $(rpkgs) $(rtpkgs)

pkgs = $(basename $(rpkgs))
tpkgs = $(basename $(rtpkgs))

ifeq ($(DEST),)
	DEST := $(shell mkdir -p out && realpath out)
endif
ifeq ($(LOGS),)
	LOGS := $(shell mkdir -p logs && realpath logs)
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

$(pkgs) $(tpkgs) $(rpkgs) $(rtpkgs):
	@echo Building $(basename $(notdir $@)). . .
	@bash buildpkg.sh $(basename $@) $(DEST) $(ARCH) &> $(LOGS)/$(basename $(notdir $@)).log
	@echo Done building $(basename $(notdir $@))

kconf:
	bash tools/kconf.sh

define make-dir-target
  $1: $(basename $(shell ls $1/*.pkgen))
endef

$(foreach dir,$(dirs),$(eval $(call make-dir-target,$(dir))))
