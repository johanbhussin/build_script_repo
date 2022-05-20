#! /bin/sh

# declare -a arr=("socfpga-5.10.50-lts" "socfpga-5.4.114-lts" "socfpga-5.4.104-lts" "socfpga-5.4.94-lts" "socfpga-5.4.84-lts" "socfpga-5.4.74-lts" "socfpga-5.4.64-lts")
declare -a arr=("socfpga-5.10.60-lts" "socfpga-5.10.80-lts")


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

 # Required by NAND and QSPI build
 echo 'CONFIG_JFFS2_FS=y' >> arch/arm64/configs/defconfig
 echo "CONFIG_UBIFS_FS=y" >> arch/arm64/configs/defconfig
 echo "CONFIG_MTD_UBI=y" >> arch/arm64/configs/defconfig

 make defconfig
 make Image
 make altera/socfpga_stratix10_socdk.dtb
 make altera/socfpga_stratix10_socdk_nand.dtb

 make -j 12 modules
 mkdir linux_modules

 # copy needed modules
 cp drivers/firmware/stratix10-rsu.ko linux_modules
 cp drivers/crypto/intel_fcs.ko linux_modules
 
# generate kernel itb per Siew Chin's ask
 cp arch/arm64/boot/dts/altera/socfpga_stratix10_socdk.dtb linux.dtb
 cp arch/arm64/boot/Image Image
 cp arch/arm64/boot/Image Image_sd
 cp /build/linux_build/uboot_s10/s10_soc_devkit_ghrd_atfbl31/314/u-boot.dtb u-boot.dtb
 /build/linux_build/uboot_s10/s10_soc_devkit_ghrd_atfbl31/314/tools/binman/binman build -u -d u-boot.dtb -O . -i kernel
 echo "UBOOT_ROOT_DIR = /p/psg/swip/etools/uboot/s10_soc_devkit_ghrd_atfbl31/2021.04/314/" > scm_sd.txt
 cp kernel.itb kernel_sd.itb

 #UBOOT_ROOT_DIR=`/build/linux_build/308`
 cp arch/arm64/boot/dts/altera/socfpga_stratix10_socdk_nand.dtb linux.dtb
 cp arch/arm64/boot/Image Image_nand
 cp /build/linux_build/uboot_s10/s10_soc_nand_devkit_ghrd_atfbl31/305/u-boot.dtb u-boot.dtb
 /build/linux_build/uboot_s10/s10_soc_nand_devkit_ghrd_atfbl31/305/tools/binman/binman build -u -d u-boot.dtb -O . -i kernel
 echo "UBOOT_ROOT_DIR = /p/psg/swip/etools/uboot/s10_soc_nand_devkit_ghrd_atfbl31/2021.04/305"  > scm_nand.txt
 cp kernel.itb kernel_nand.itb

 # build kernel Image with disable QSPI 4k sector
 echo "CONFIG_MTD_SPI_NOR_USE_4K_SECTORS=n" >> arch/arm64/configs/defconfig
 make defconfig
 make Image

 # use uboot sdmmc (s10 uboot qspi not build)
 #UBOOT_ROOT_DIR=`/build/linux_build/308`
 cp arch/arm64/boot/Image Image
 cp arch/arm64/boot/Image Image_qspi
 cp arch/arm64/boot/dts/altera/socfpga_stratix10_socdk.dtb linux.dtb
 cp /build/linux_build/uboot_s10/s10_soc_qspi_devkit_ghrd_atfbl31/251/u-boot.dtb u-boot.dtb
 /build/linux_build/uboot_s10/s10_soc_qspi_devkit_ghrd_atfbl31/251/tools/binman/binman build -u -d u-boot.dtb -O . -i kernel
 echo "UBOOT_ROOT_DIR = /p/psg/swip/etools/uboot/s10_soc_qspi_devkit_ghrd_atfbl31/2021.04/251"  > scm_qspi.txt
 cp kernel.itb kernel_qspi.itb

 #Rename kernel image for SD as this is the default name
 rm -f Image
 mv Image_sd Image

 echo "Move compiled to folder\n"
 mkdir /build/linux_build/s10/"$i"


 mv vmlinux /build/linux_build/s10/"$i"
 mv Image /build/linux_build/s10/"$i"
 mv Image_nand /build/linux_build/s10/"$i"
 mv Image_qspi /build/linux_build/s10/"$i"
 mv linux_modules /build/linux_build/s10/"$i"
 mv arch/arm64/boot/dts/altera/socfpga_stratix10_socdk.dtb /build/linux_build/s10/"$i" 
 mv arch/arm64/boot/dts/altera/socfpga_stratix10_socdk_nand.dtb /build/linux_build/s10/"$i"
 mv kernel_sd.itb /build/linux_build/s10/"$i"
 mv kernel_nand.itb /build/linux_build/s10/"$i"
 mv kernel_qspi.itb /build/linux_build/s10/"$i"
 mv scm_sd.txt /build/linux_build/s10/"$i"
 mv scm_nand.txt /build/linux_build/s10/"$i"
 mv scm_qspi.txt /build/linux_build/s10/"$i"
 echo ">>>>>>> $i DONE <<<<<<"

done

