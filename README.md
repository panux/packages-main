# packages-main (WIP) [![Gitter chat](https://badges.gitter.im/gitterHQ/gitter.png)](https://gitter.im/panux/panux-dev)
Packages for Project Panux

## Building
In order to build packages, all you need is docker and a shell. To try building a package (busybox in this example), run:
````sh
./build.sh meta/x86_64/busybox.meta
```
Once this finishes, there will be a busybox package stored into ````out/x86_64/busybox.tar.gz````.

**NOTE:** If there are not sufficient permissions, ````build.sh```` will re-execute itself with sudo. All permissions will be reset to the invoking user after the build completes. For this reason, it is best to let ````build.sh```` execute sudo by itself.

## How it works
Before this actually builds busybox, it compiles "bootstrap" copies of various packages which are necessary to compile themselves (e.g. gcc). It accomplishes this by building these packages in an Alpine Linux container.

Once the bootstrap is done, all other packages are built in Panux containers. The rootfs for these containers is built using the generated packages.

### Generated build files
````ccache````: stores the compiler cache; speeds up redundant builds  
````pkgens.list````: a lookup table for pkgen files; format ````name=path````; _Tip:_ use grep to search ````pkgens.list```` for a package  
````lists````: contains fragments of ````pkgens.list````, stored here as a cache for faster incremental builds  
````out````: output packages  
````out/bootstrap/<name>.tar.gz````: bootstrapped package of &lt;name&gt;  
````build/<name>/Dockerfile(.bootstrap)````: Dockerfile used to generate container for build  
````build/<name>/builddeps.list````: list of build dependencies for package  
````build/<name>/build-<arch>.mk````: generated Makefile run in build environment  
````build/<name>/src.tar````: tar file containing downloaded source and pkgen  
````build/<name>/rootfs.tar.gz````: tar file containing rootfs used as build environment  
````build/<name>/deplists````: folder containing list files of dependencies of the subpackages (used for dependency scanning)
