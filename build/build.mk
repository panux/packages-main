all: build

PKGEN = $(shell which pkgen)

out/$(ARCH):
	mkdir -p out/$(ARCH)

define genouttarg
out/$(ARCH)/$(1).tar.gz: run.$(ARCH)
tars:: out/$(ARCH)/$(1).tar.gz
endef

$(foreach i,$(shell cat pkgs.list),$(eval $(call genouttarg,$(i))))

build: tars
	touch build

Dockerfile.$(ARCH): pkgen.yaml $(PKGEN)
	if [ -e Dockerfile.$(ARCH) ]; then rm -f Dockerfile.$(ARCH); fi
	pkgen -i pkgen.yaml -t dockerfile -arch $(ARCH) -o Dockerfile.$(ARCH)

buildenv-$(ARCH): Dockerfile.$(ARCH)
	docker build -f Dockerfile.$(ARCH) -t panux/buildenv:$(shell basename $(shell pwd))-$(ARCH) .
	touch buildenv-$(ARCH)

src/.dir:
	mkdir -p src
	touch src/.dir

src/Makefile: src/.dir pkgen.yaml $(PKGEN)
	if [ -e src/Makefile ]; then rm -f src/Makefile; fi
	pkgen -i pkgen.yaml -t srcmk -o src/Makefile

srcbuild: src/Makefile
	$(MAKE) -C src
	touch srcbuild

pkg-$(ARCH).mk: pkgen.yaml $(PKGEN)
	pkgen -i pkgen.yaml -t mk -arch $(ARCH) -o pkg-$(ARCH).mk

run.$(ARCH): buildenv-$(ARCH) srcbuild pkg-$(ARCH).mk out/$(ARCH)
	docker build -f Dockerfile.$(ARCH) -t panux/buildenv:$(shell basename $(shell pwd))-$(ARCH) .
	docker run --rm -v $(shell realpath src):/build/src -v $(shell realpath pkg-$(ARCH).mk):/build/Makefile -v $(shell realpath out/$(ARCH)):/build/out -e ARCH=$(ARCH) panux/buildenv:$(shell basename $(shell pwd))-$(ARCH) /build/src /build/Makefile /build/out
	touch run.$(ARCH)

prep: buildenv-$(ARCH) srcbuild pkg-$(ARCH).mk out/$(ARCH)
