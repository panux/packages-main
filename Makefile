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

all:
	echo "Not allowed"
	return 1

define mkalias
$(1):
	$(MAKE) -C build $(1).build
endef

$(foreach p,$(shell dirname $(shell realpath $(shell find pkgs -name "pkgen.yaml"))),$(eval $(call mkalias,$(shell basename $(p)))))
