docker pull panux/menuconf-docker

docker run -it --rm -v $(realpath kernel):/kernel panux/menuconf-docker 4.9.35 /kernel/kernel-x86_64.conf