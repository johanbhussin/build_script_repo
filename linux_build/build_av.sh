#! /bin/sh

#declare -a arr=("socfpga-5.10.50-lts" "socfpga-5.4.114-lts" "socfpga-5.4.104-lts" "socfpga-5.4.94-lts" "socfpga-5.4.84-lts" "socfpga-5.4.74-lts" "socfpga-5.4.64-lts")
declare -a arr=("socfpga-5.10.60-lts" "socfpga-5.10.80-lts" )


cd /build/linux_build/applications.fpga.soc.linux-socfpga

for i in "${arr[@]}"
do
 echo "go into linux socfpga repo\n" 
 cd /build/linux_build/applications.fpga.soc.linux-socfpga

 echo "Change Branch\n"
 git checkout "$i" 
 git rev-parse --abbrev-ref HEAD

 echo "Reset  git for clean build\n"
 git add --all
 git reset --hard HEAD


 echo "Start compiling\n"
 export ARCH=arm
 export CROSS_COMPILE=arm-none-eabi-
 make socfpga_defconfig
 make zImage -j 100
 make socfpga_arria5_socdk.dtb

 echo "Move compiled to folder\n"
 mkdir /build/linux_build/av/"$i"

 mv vmlinux /build/linux_build/av/"$i"
 mv arch/arm/boot/zImage /build/linux_build/av/"$i"
 mv arch/arm/boot/dts/socfpga_arria5_socdk.dtb /build/linux_build/av/"$i"

done
