define genpkftarg
$(1)/$(2): $(3)/$(2) $(1)
	rm -rf $(1)/$(2)
	cp -r $(3)/$(2) $(1)/$(2)
$(1).files:: $(1)/$(2)
endef
define genpktarg
$(1):
	mkdir $(1)
$(foreach f,$(shell ls $(2)),$(eval $(call genpkftarg,$(1),$(shell basename $(f)),$(2))))
$(1)/Makefile: $(1)
	if [ ! -e $(1)/Makefile ]; then (cd $(1) && ln -s ../build.mk Makefile); fi
$(1)/pkgs.list:
	pkgen -i $(1)/pkgen.yaml -t pkglist -o $(1)/pkgs.list
$(1).build: $(1).files $(1)/Makefile $(1)/pkgs.list
	$(MAKE) -C $(1) build
$(1).prep: $(1).files $(1)/Makefile $(1)/pkgs.list
	$(MAKE) -C $(1) prep
pkgs += $(1)
endef

$(foreach p,$(shell dirname $(shell realpath $(shell find ../pkgs -name "pkgen.yaml"))),$(eval $(call genpktarg,$(shell basename $(p)),$(p))))
