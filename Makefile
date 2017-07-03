pkgs = basefs busybox gnupg libassuan libgcrypt libgpg-error libintl musl shpkg zlib kernel/linux dev/lua

all: $(pkgs)

$(pkgs) :
	bash buildpkg.sh $@ $(DEST)
