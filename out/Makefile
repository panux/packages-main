ifeq ($(odir),)
extra = out
odir = out
$(shell if [ ! -d out ]; then mkdir $(odir); fi)
endif
ifneq ($(shell if [ -d $(odir) ]; then echo good; else exit 1; fi),good)
$(error $(odir) does not exist)
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

define targ
$(2): $(1)
	cp -f $(1) $(2)
$(basename $(basename $(2))).pkginfo: $(2)
	(tar -xOf $(2) ./.pkginfo; echo -n SHA256SUM=\"; sha256sum $(2) | cut -d' ' -f1 | head -c -1; echo \") > $(basename $(basename $(2))).pkginfo
files:: $(2)
files:: $(basename $(basename $(2))).pkginfo
tlst += $(2) $(basename $(basename $(2))).pkginfo
ifeq ($(minisign),1)
$(basename $(basename $(2))).pkginfo.minisig: $(basename $(basename $(2))).pkginfo
	echo | minisign -SHm $(basename $(basename $(2))).pkginfo
files:: $(basename $(basename $(2))).pkginfo.minisig
tlst += $(basename $(basename $(2))).pkginfo.minisig
endif
endef
define targpkg
ifeq ($(shell if [ -d ../build/$(1)/out/$(ARCH) ]; then echo good; else exit 1; fi),good)
$(foreach t,$(wildcard ../build/$(1)/out/$(ARCH)/*.tar.gz),$(eval $(call targ,$(t),$(odir)/$(shell basename $(t)))))
endif
endef


all: files delold

$(foreach p,$(shell find ../pkgs -name "pkgen.yaml"),$(eval $(call	targpkg,$(shell basename $(dir $(p))))))

define chkold
ifeq ($(filter $(1),$(tlst)),)
$(1).del:
	rm $(1)
old += $(1).del
endif
endef
$(foreach f,$(shell ls $(odir)/*.tar.gz),$(eval $(call chkold,$(f))))
$(foreach f,$(shell ls $(odir)/*.pkginfo),$(eval $(call chkold,$(f))))
$(foreach f,$(shell ls $(odir)/*.minisig),$(eval $(call chkold,$(f))))

delold: $(old)
