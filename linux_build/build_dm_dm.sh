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
export ARCH=arm64
	export CROSS_COMPILE=aarch64-linux-gnu-
	
	#overlay setup
	sed -i 's/socfpga_n5x_socdk.dtb/ socfpga_n5x_socdk.dtb \\ \n socfpga_n5x_auth_ovl1.dtb/' arch/arm64/boot/dts/intel/Makefile
	
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
		    firmware-name = \"soc_n5x_ovl1.rbf\";
		    config-complete-timeout-us = <3000000>;
		    };
	    };
    };" > arch/arm64/boot/dts/intel/socfpga_n5x_auth_ovl1.dts


	make defconfig
	make Image
	make intel/socfpga_n5x_socdk.dtb
	
	#Build overlay dtb
    make intel/socfpga_n5x_auth_ovl1.dtb
	
	make -j 12 modules
	mkdir linux_modules

	# copy needed modules
	cp drivers/crypto/intel_fcs.ko linux_modules
	cp drivers/firmware/stratix10-rsu.ko linux_modules

	# generate kernel itb per Siew Chin's ask
	cp arch/arm64/boot/dts/intel/socfpga_n5x_socdk.dtb linux.dtb
	cp arch/arm64/boot/Image Image
	cp /p/psg/swip/etools/uboot/dm_soc_devkit_ghrd_atfbl31/2021.04/302/u-boot.dtb u-boot.dtb
	/p/psg/swip/etools/uboot/dm_soc_devkit_ghrd_atfbl31/2021.04/302/tools/binman/binman build -u -d u-boot.dtb -O . -i kernel
	echo "UBOOT_ROOT_DIR = /p/psg/swip/etools/uboot/dm_soc_devkit_ghrd_atfbl31/2021.04/302/" > scm_sd.txt
	cp kernel.itb kernel_sd.itb

 echo "Move compiled to folder\n"
 mkdir /build/linux_build/linux_dbe/"$i"

 mv .config /build/linux_build/linux_dbe/"$i"
 mv arch/arm64/boot/Image /build/linux_build/linux_dbe/"$i"
 mv arch/arm64/boot/dts/intel/socfpga_n5x_socdk.dtb /build/linux_build/linux_dbe/"$i"

 echo ">>>>>>> $i DONE <<<<<<"
done
