Script to generate binary for linux regression test. 

this is used for mainline branch. it uses modified defconfig by Dinh, so it need to be build separately than elinux jenkins build.

the script will do following step

1. Take custom defconfig, from linux-bringup repo. 
2. Copy defconfig into current mainline branch (eg 5.16) repo.
3. Compile linux.
4. Copy over the required files and create ARC resource for that.

it only need to be generated only when new mainline branch is added, so for now, no need to include in jenkins build.

the resource will be created in elinux/linux_regtest