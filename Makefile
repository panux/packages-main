ifeq ($(ARCH),)
	ARCH := $(shell file /bin/ls | cut -d ',' -f2 | xargs)
	ifeq ($(ARCH),x86-64)
		ARCH=x86_64
	endif
	ifeq ($(ARCH),Intel 80386)
		ARCH=x86
	endif
endif
export ARCH

all: all.pkgs

define mkalias
$(1):
	+$(MAKE) -C build $(1)/.build
$(1).prep:
	+$(MAKE) -C build $(1).prep
$(1).clean:
	+$(MAKE) -C build $(1).clean
PREPS += $(1).prep
ifneq ($(2),testing)
ALLPKGS += $(1)/.build
endif
endef

$(foreach p,$(shell find pkgs -name "pkgen.yaml"),$(eval $(call	mkalias,$(shell basename $(dir $(p))),$(shell basename $(shell dirname $(dir $(p)))))))

all.pkgs:
	+$(MAKE) -C build $(ALLPKGS)

all.prep:
	+$(MAKE) -C build $(PREPS)

clean:
	+$(MAKE) -C build clean

kernel.conf:
	sh tools/kconf.sh $(ARCH)

busybox.conf: busybox.prep
	sh tools/conf-busybox.sh $(ARCH)
