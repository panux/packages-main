pkgs = base-meta basefs busybox gnupg libassuan libgcrypt libgpg-error libintl musl shpkg zlib readline sl bash nano lpkg dev/lua dev/ncurses

ifeq ($(ARCH),x86_64)
	pkgs += kernel/linux
endif

all: $(pkgs)

$(pkgs) :
	bash buildpkg.sh $@ $(DEST) $(ARCH)
