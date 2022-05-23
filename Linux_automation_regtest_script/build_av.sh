#! /bin/sh

mkdir -p /build/linux_regtest
cd /build/linux_regtest

echo "cloning repo linux-bringup\n"
git clone --single-branch --branch socfpga-5.16_regression_test_defconfig https://github.com/intel-sandbox/linux-bringup

echo "cloning repo linux-socfpga\n"
git clone --single-branch --branch socfpga-5.16 https://github.com/intel-innersource/applications.fpga.soc.linux-socfpga

echo "copying modified defconfig from linux bringup to linux-socfpga"
cp /build/linux_regtest/linux-bringup/arch/arm/configs/socfpga_defconfig /build/linux_regtest/applications.fpga.soc.linux-socfpga/arch/arm/configs/

echo "Start compiling\n"
cd /build/linux_regtest/applications.fpga.soc.linux-socfpga/
export ARCH=arm
export CROSS_COMPILE=arm-none-eabi-

make defconfig
make zImage -j$(($(nproc)))
make socfpga_arria5_socdk.dtb

make -j 12 modules

echo "Move compiled to folder\n"
mkdir -p /build/linux_regtest/arm/5.16/av

cp arch/arm/boot/zImage /build/linux_regtest/arm/5.16/av
cp arch/arm/boot/dts/socfpga_arria5_socdk.dtb /build/linux_regtest/arm/5.16/av
cp drivers/mtd/tests/mtd_readtest.ko /build/linux_regtest/arm/5.16/av
cp drivers/mtd/tests/mtd_stresstest.ko /build/linux_regtest/arm/5.16/av
cp drivers/mtd/tests/mtd_speedtest.ko /build/linux_regtest/arm/5.16/av

echo ">>>>>>> $i DONE <<<<<<"
