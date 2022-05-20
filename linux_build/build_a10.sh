#! /bin/sh

#declare -a arr=("socfpga-5.10.50-lts" "socfpga-5.4.114-lts" "socfpga-5.4.104-lts" "socfpga-5.4.94-lts" "socfpga-5.4.84-lts" "socfpga-5.4.74-lts" "socfpga-5.4.64-lts")
declare -a arr=("socfpga-5.10.60-lts" "socfpga-5.10.80-lts")

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
 make socfpga_arria10_socdk_sdmmc.dtb
 make socfpga_arria10_socdk_nand.dtb
 make socfpga_arria10_socdk_qspi.dtb

 echo "Move compiled to folder\n"
 mkdir /build/linux_build/a10/"$i"

 mv vmlinux /build/linux_build/a10/"$i"
 mv arch/arm/boot/zImage /build/linux_build/a10/"$i"
 mv arch/arm/boot/dts/socfpga_arria10_socdk_sdmmc.dtb /build/linux_build/a10/"$i"
 mv arch/arm/boot/dts/socfpga_arria10_socdk_nand.dtb /build/linux_build/a10/"$i"
 mv arch/arm/boot/dts/socfpga_arria10_socdk_qspi.dtb /build/linux_build/a10/"$i"

 echo ">>>>>>> $i DONE <<<<<<"
done
