#! /bin/sh

declare -a arr=("socfpga-5.10.50-lts" "socfpga-5.4.114-lts" "socfpga-5.4.104-lts" "socfpga-5.4.94-lts" "socfpga-5.4.84-lts" "socfpga-5.4.74-lts" "socfpga-5.4.64-lts")

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
 export CROSS_COMPILE=aarch64-linux-gnu-
 export ARCH=arm64
 echo "CONFIG_EDAC=y" >> arch/arm64/configs/defconfig
 echo "CONFIG_EDAC_DEBUG=y" >> arch/arm64/configs/defconfig
 echo "CONFIG_EDAC_ALTERA=y" >> arch/arm64/configs/defconfig
 echo "CONFIG_EDAC_ALTERA_ARM64_WARM_RESET=y" >> arch/arm64/configs/defconfig
 echo "CONFIG_EDAC_ALTERA_SDRAM=y" >> arch/arm64/configs/defconfig
 echo "CONFIG_OF_CONFIGFS=y" >> arch/arm64/configs/defconfig
 sed -i "s/CONFIG_FPGA_MGR_STRATIX10_SOC=m/CONFIG_FPGA_MGR_STRATIX10_SOC=y/g" arch/arm64/configs/defconfig
 sed -i "s/CONFIG_FPGA_BRIDGE=m/CONFIG_FPGA_BRIDGE=y/g" arch/arm64/configs/defconfig
 sed -i "s/CONFIG_ALTERA_FREEZE_BRIDGE=m/CONFIG_ALTERA_FREEZE_BRIDGE=y/g" arch/arm64/configs/defconfig
 sed -i "s/CONFIG_FPGA_REGION=m/CONFIG_FPGA_REGION=y/g" arch/arm64/configs/defconfig
 sed -i "s/CONFIG_OF_FPGA_REGION=m/CONFIG_OF_FPGA_REGION=y/g" arch/arm64/configs/defconfig
 sed -i 's/CONFIG_INTEL_STRATIX10_RSU=m/CONFIG_INTEL_STRATIX10_RSU=y/g' arch/arm64/configs/defconfig
 make defconfig
 make -j Image 
 make intel/socfpga_n5x_socdk.dtb

 echo "Move compiled to folder\n"
 mkdir /build/linux_build/linux_dbe/"$i"

 mv .config /build/linux_build/linux_dbe/"$i"
 mv arch/arm64/boot/Image /build/linux_build/linux_dbe/"$i"
 mv arch/arm64/boot/dts/intel/socfpga_n5x_socdk.dtb /build/linux_build/linux_dbe/"$i"

 echo ">>>>>>> $i DONE <<<<<<"
done
