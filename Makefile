pkgs = main/base-meta main/basefs main/busybox main/gnupg main/musl libs/libassuan libs/libgcrypt libs/libgpg-error libs/libintl testing/perl testing/shpkg libs/zlib main/readline extra/sl extra/asciiquarium main/bash main/nano main/wget main/lpkg testing/git testing/openssl testing/curl testing/grub main/xz dev/lua dev/ncurses languages/go main/profile

ifeq ($(ARCH),x86_64)
	pkgs += kernel/linux
endif

all: $(pkgs)

$(pkgs) :
	bash buildpkg.sh $@ $(DEST) $(ARCH)
