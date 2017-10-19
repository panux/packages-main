ifeq ($(odir),)
extra = out
odir = out
$(shell if [ ! -d out ]; then mkdir $(odir); fi)
endif
ifneq ($(shell if [ -d $(odir) ]; then echo good; exit 1; fi),good)
$(error $(odir) does not exist)
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

all: files delold

$(foreach t,$(shell find ../build -name '*.tar.gz'),$(eval $(call targ,$(t),$(odir)/$(shell basename $(t)))))

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
