#! /bin/sh

declare -a arr=("socfpga-5.10.60-lts" "socfpga-5.10.80-lts" )

for i in "${arr[@]}"
do
 echo "go into linux socfpga repo\n"
 cd /build/linux_build/applications.fpga.soc.linux-socfpga

 echo "Reset  git for clean build\n"
 git add --all
 git reset --hard HEAD

 echo "Change Branch\n"
 git checkout "$i"
 git rev-parse --abbrev-ref HEAD

 echo "Start compiling\n"
 export ARCH=arm64
 export CROSS_COMPILE=aarch64-linux-gnu-

 # overlay setup
 sed -i 's/socfpga_agilex_socdk.dtb \\/&\nsocfpga_agilex_auth_ovl1.dtb \\/' arch/arm64/boot/dts/intel/Makefile

 echo "/dts-v1/;
 /plugin/;
 / {
	fragment@0 {
	target-path = \"/soc/base_fpga_region\";
	#address-cells = <1>;
	#size-cells = <1>;
	__overlay__ {
		#address-cells = <1>;
		#size-cells = <1>;
		authenticate-fpga-config;
		firmware-name = \"soc_agx_ovl1.rbf\";
		config-complete-timeout-us = <3000000>;
		};
	};
 };" > arch/arm64/boot/dts/intel/socfpga_agilex_auth_ovl1.dts

 # Required by NAND and QSPI build
 echo "CONFIG_JFFS2_FS=y" >> arch/arm64/configs/defconfig
 echo "CONFIG_UBIFS_FS=y" >> arch/arm64/configs/defconfig
 echo "CONFIG_MTD_UBI=y" >> arch/arm64/configs/defconfig

 # kernel compilation
 make defconfig
 make Image
 make intel/socfpga_agilex_socdk.dtb
 make intel/socfpga_agilex_socdk_nand.dtb
 make intel/socfpga_agilex_auth_ovl1.dtb

 make -j 12 modules
 mkdir linux_modules

 # copy needed modules
 cp drivers/crypto/intel_fcs.ko linux_modules
 cp drivers/firmware/stratix10-rsu.ko linux_modules
 cp drivers/fpga/*.ko linux_modules

 # generate kernel itb per Siew Chin's ask
 cp arch/arm64/boot/dts/intel/socfpga_agilex_socdk.dtb linux.dtb
 cp arch/arm64/boot/Image Image
 cp arch/arm64/boot/Image Image_sd
 cp /build/linux_build/agilex_uboot/agilex_soc_devkit_ghrd_atfbl31/308/u-boot.dtb u-boot.dtb
 /build/linux_build/agilex_uboot/agilex_soc_devkit_ghrd_atfbl31/308/tools/binman/binman build -u -d u-boot.dtb -O . -i kernel
 echo "UBOOT_ROOT_DIR = /build/linux_build/agilex_uboot/agilex_soc_devkit_ghrd_atfbl31/308" > scm_sd.txt
 cp kernel.itb kernel_sd.itb

 #UBOOT_ROOT_DIR=`arc resource-info uboot/agilex_soc_nand_devkit_ghrd_atfbl31/2021.04 UBOOT_ROOT_DIR`
 cp arch/arm64/boot/dts/intel/socfpga_agilex_socdk_nand.dtb linux.dtb
 cp arch/arm64/boot/Image Image_nand
 cp /build/linux_build/agilex_uboot/agilex_soc_nand_devkit_ghrd_atfbl31/294/u-boot.dtb u-boot.dtb
 /build/linux_build/agilex_uboot/agilex_soc_nand_devkit_ghrd_atfbl31/294/tools/binman/binman build -u -d u-boot.dtb -O . -i kernel
 echo "UBOOT_ROOT_DIR = /build/linux_build/agilex_uboot/agilex_soc_nand_devkit_ghrd_atfbl31/294" > scm_nand.txt
 cp kernel.itb kernel_nand.itb

 # build kernel Image with disable QSPI 4k sector
 echo "CONFIG_MTD_SPI_NOR_USE_4K_SECTORS=n" >> arch/arm64/configs/defconfig
 make defconfig
 make Image

 # use uboot qspi
 #UBOOT_ROOT_DIR=`arc resource-info uboot/agilex_soc_qspi_devkit_ghrd_atfbl31/2021.04 UBOOT_ROOT_DIR`
 cp arch/arm64/boot/Image Image
 cp arch/arm64/boot/Image Image_qspi
 cp arch/arm64/boot/dts/intel/socfpga_agilex_socdk.dtb linux.dtb
 cp /build/linux_build/agilex_uboot/agilex_soc_qspi_devkit_ghrd_atfbl31/313/u-boot.dtb u-boot.dtb
 /build/linux_build/agilex_uboot/agilex_soc_qspi_devkit_ghrd_atfbl31/313/tools/binman/binman build -u -d u-boot.dtb -O . -i kernel
 echo "UBOOT_ROOT_DIR = /build/linux_build/agilex_uboot/agilex_soc_qspi_devkit_ghrd_atfbl31/313" > scm_qspi.txt
 cp kernel.itb kernel_qspi.itb

 #Rename kernel image for SD as this is the default name
 rm -f Image
 mv Image_sd Image

 echo "Move compiled to folder\n"
 mkdir /build/linux_build/agilex/"$i"

 mv vmlinux /build/linux_build/agilex/"$i"
 mv Image /build/linux_build/agilex/"$i"
 mv Image_nand /build/linux_build/agilex/"$i"
 mv Image_qspi /build/linux_build/agilex/"$i"
 mv linux_modules /build/linux_build/agilex/"$i"
 mv arch/arm64/boot/dts/intel/socfpga_agilex_socdk.dtb /build/linux_build/agilex/"$i" 
 mv arch/arm64/boot/dts/intel/socfpga_agilex_socdk_nand.dtb /build/linux_build/agilex/"$i"
 mv arch/arm64/boot/dts/intel/socfpga_agilex_auth_ovl1.dtb /build/linux_build/agilex/"$i"
 mv kernel_sd.itb /build/linux_build/agilex/"$i"
 mv kernel_nand.itb /build/linux_build/agilex/"$i"
 mv kernel_qspi.itb /build/linux_build/agilex/"$i"
 mv scm_sd.txt /build/linux_build/agilex/"$i"
 mv scm_nand.txt /build/linux_build/agilex/"$i"
 mv scm_qspi.txt /build/linux_build/agilex/"$i"
 echo ">>>>>>> $i DONE <<<<<<"

done
