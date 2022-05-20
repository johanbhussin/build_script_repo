#! /bin/sh

mkdir -p /build/linux_regtest
cd /build/linux_regtest

echo "cloning repo linux-bringup\n"
git clone --single-branch --branch socfpga-5.16_regression_test_defconfig https://github.com/intel-sandbox/linux-bringup

echo "cloning repo linux-socfpga\n"
git clone --single-branch --branch socfpga-5.16 https://github.com/intel-innersource/applications.fpga.soc.linux-socfpga

echo "copying modified defconfig from linux bringup to linux-socfpga"
cp /build/linux_regtest/linux-bringup/arch/arm64/configs/socfpga_allyes_defconfig /build/linux_regtest/applications.fpga.soc.linux-socfpga/arch/arm64/configs/

echo "Start compiling\n"
cd /build/linux_regtest/applications.fpga.soc.linux-socfpga/
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

# Required by NAND and QSPI build
echo "CONFIG_JFFS2_FS=y" >> arch/arm64/configs/socfpga_allyes_defconfig
echo "CONFIG_UBIFS_FS=y" >> arch/arm64/configs/socfpga_allyes_defconfig
echo "CONFIG_MTD_UBI=y" >> arch/arm64/configs/socfpga_allyes_defconfig

make socfpga_allyes_defconfig
make Image -j$(($(nproc)))
make intel/socfpga_agilex_socdk.dtb
make intel/socfpga_agilex_socdk_nand.dtb
make intel/socfpga_agilex_auth_ovl1.dtb

make -j 12 modules

# generate kernel itb
cp arch/arm64/boot/dts/intel/socfpga_agilex_socdk.dtb linux.dtb
cp arch/arm64/boot/Image Image
cp arch/arm64/boot/Image Image_sd
cp /build/linux_build/agilex_uboot/agilex_soc_devkit_ghrd_atfbl31/308/u-boot.dtb u-boot.dtb
/build/linux_build/agilex_uboot/agilex_soc_devkit_ghrd_atfbl31/308/tools/binman/binman build -u -d u-boot.dtb -O . -i kernel
cp kernel.itb kernel_sd.itb

# build kernel Image with disable QSPI 4k sector
echo "CONFIG_MTD_SPI_NOR_USE_4K_SECTORS=n" >> arch/arm64/configs/socfpga_allyes_defconfig
make socfpga_allyes_defconfig
make Image -j$(($(nproc)))

# use uboot qspi
cp arch/arm64/boot/Image Image
cp arch/arm64/boot/Image Image_qspi
cp arch/arm64/boot/dts/intel/socfpga_agilex_socdk.dtb linux.dtb
cp /build/linux_build/agilex_uboot/agilex_soc_qspi_devkit_ghrd_atfbl31/313/u-boot.dtb u-boot.dtb
/build/linux_build/agilex_uboot/agilex_soc_qspi_devkit_ghrd_atfbl31/313/tools/binman/binman build -u -d u-boot.dtb -O . -i kernel
cp kernel.itb kernel_qspi.itb


echo "Move compiled to folder\n"
mkdir -p /build/linux_regtest/arm64/5.16/agilex/

mv kernel_sd.itb /build/linux_regtest/arm64/5.16/agilex/kernel.itb
mv kernel_qspi.itb /build/linux_regtest/arm64/5.16/agilex/
mv Image_sd /build/linux_regtest/arm64/5.16/agilex/Image
mv Image_qspi /build/linux_regtest/arm64/5.16/agilex/
mv arch/arm64/boot/dts/intel/socfpga_agilex_socdk.dtb /build/linux_regtest/arm64/5.16/agilex/
mv drivers/mtd/tests/mtd_readtest.ko /build/linux_regtest/arm64/5.16/agilex/
mv drivers/mtd/tests/mtd_stresstest.ko /build/linux_regtest/arm64/5.16/agilex/
mv drivers/mtd/tests/mtd_speedtest.ko /build/linux_regtest/arm64/5.16/agilex/
mv drivers/firmware/stratix10-rsu.ko /build/linux_regtest/arm64/5.16/agilex/

echo ">>>>>>> $i DONE <<<<<<"