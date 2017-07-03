pkgs = base-meta basefs busybox gnupg libassuan libgcrypt libgpg-error libintl musl shpkg zlib readline kernel/linux dev/lua dev/ncurses

all: $(pkgs)

$(pkgs) :
	bash buildpkg.sh $@ $(DEST)
