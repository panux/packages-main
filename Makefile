dirs = main dev extra languages libs testing

pkgs = $(foreach dir,$(dirs),$(basename $(shell ls $(dir)/*.pkgen)))



ifeq ($(ARCH),x86_64)
	pkgs += kernel/linux
endif

all: $(pkgs)

list:
	@echo $(pkgs)

$(pkgs) :
	bash buildpkg.sh $@ $(DEST) $(ARCH)
