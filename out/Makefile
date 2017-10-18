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
tars:: $(2)
tlst += $(2)
endef

all: tars delold out

$(foreach t,$(shell find ../build -name '*.tar.gz'),$(eval $(call targ,$(t),$(odir)/$(shell basename $(t)))))

define chkold
ifeq ($(filter $(1),$(tlst)),)
$(1).del:
	rm $(1)
old += $(1).del
endif
endef
$(foreach f,$(shell ls $(odir)/*.tar.gz),$(eval $(call chkold,$(f))))

delold: $(old)
