PKGEN = $(shell which pkgen)

define genpkftarg
$(1)/$(2): $(3)/$(2) $(1)/.dir
	if [ -e $(1)/$(2) ]; then rm -r $(1)/$(2); cp -r $(3)/$(2) $(1)/$(2); else cp -r $(3)/$(2) $(1)/$(2); fi
$(1)_files += $(1)/$(2)
endef
define genpktarg
$(1)/.dir:
	@if [ ! -d $(1) ]; then mkdir $(1); touch $(1)/.dir; fi
$(foreach f,$(shell ls $(2)),$(eval $(call genpkftarg,$(1),$(shell basename $(f)),$(2))))
$(1)/Makefile: $(1)/.dir build.mk
	cp -f build.mk $(1)/Makefile
$(1)/pkgs.list: $(1)/pkgen.yaml
	if [ -e $(1)/pkgs.list ]; then rm -f $(1)/pkgs.list; fi
	pkgen -i $(1)/pkgen.yaml -t pkglist -o $(1)/pkgs.list
$(1)/.build.$(ARCH): $(1)/.files $(1)/Makefile $(1)/pkgs.list $(PKGEN)
	+$(MAKE) -C $(1) build
	touch $(1)/.build.$(ARCH)
$(1).prep: $(1)/.files $(1)/Makefile $(1)/pkgs.list $(PKGEN)
	+$(MAKE) -C $(1) prep
$(1).clean:
	if [ -d $(1) ]; then rm -r $(1); fi
$(1)/.files: $($(1)_files)
	touch $(1)/.files
ifneq ($(wildcard $(1)),)
clean:: $(1).clean
endif
pkgs += $(1)
$(1)/.build: $(1)/.build.$(ARCH)
endef

clean::

$(foreach p,$(shell dirname $(shell realpath $(shell find ../pkgs -name "pkgen.yaml"))),$(eval $(call genpktarg,$(shell basename $(p)),$(p))))
