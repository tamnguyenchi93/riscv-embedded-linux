# riscv-embedded-linux

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/tamnguyenchi93/riscv-embedded-linux)

This repo is to setup is my a walkthough of **Embedded Linux from Scratch in 45 minutes, on RISC-V** 
  - [Embedded Linux from Scratch in 45 minutes, on RISC-V-Youtube](https://www.youtube.com/watch?v=cIkTh3Xp3dA&ab_channel=Bootlin)
  [Embedded Linux from Scratch in 45 minutes, on RISC-V-Slide](https://bootlin.com/pub/conferences/2021/fosdem/opdenacker-embedded-linux-45minutes-riscv/opdenacker-embedded-linux-45minutes-riscv.pdf)

## Create Working Dir
```bash
mkdir tmp
cd tmp
export WORKING_DIR=`pwd`
cd -
```
## Generating a RISC-V musl toolchain with Buildroot
- Download Buildroot 2020.11.1 from [buildroot.org](https://buildroot.org/download.html)
```bash
wget https://buildroot.org/downloads/buildroot-2020.11.1.tar.gz -P ${WORKING_DIR}
```
- Extract buildroot source
```
tar xf ${WORKING_DIR}/buildroot-2020.11.1.tar.gz -C ${WORKING_DIR}
```
- Config buildroot with:
  - Architecture RISCV: `Target options -> Target Architecture`
  - C library musl: `Toolchain -> C library`
```bash
make -C ${WORKING_DIR}/buildroot-2020.11.1 menuconfig
```

- Save your configuration and build:
  - Build toolchain only: https://stackoverflow.com/a/44542383
```bash
make -C ${WORKING_DIR}/buildroot-2020.11.1 toolchain -j 8
```

- You have an toolchain archive in output/images/riscv64-buildroot-linux-musl_sdkbuildroot.tar.gz

- Extract toolchain
```bash
mkdir $HOME/toolchain
tar xf ${WORKING_DIR}/buildroot-2020.11.1/output/images/riscv64-buildroot-linux-musl_sdk-buildroot.tar.gz \
    -C $HOME/toolchain
```
- Run `relocate-sdk.sh`
```bash
cd $HOME/toolchain/riscv64-buildroot-linux-musl_sdk-buildroot
./relocate-sdk.sh
cd -
```

## Uboot Setup
- Download Uboot from [Github Release](https://github.com/u-boot/u-boot/releases)
```bash
wget https://github.com/u-boot/u-boot/archive/refs/tags/v2021.07.tar.gz -P ${WORKING_DIR}
```
- Extract source code:
```bash
tar xf ${WORKING_DIR}/v2021.07.tar.gz -C ${WORKING_DIR}
```
- We will choose the configuration for QEMU and U-Boot running in S Mode:
```bash
make -C ${WORKING_DIR}/u-boot-2021.07 qemu-riscv64_smode_defconfig
```
- Compile U-Boot
```bash
make -C ${WORKING_DIR}/u-boot-2021.07 -j8
```

# Setup OpenSBI
- Clone OpenSBI
```
git -C ${WORKING_DIR} clone https://github.com/riscv/opensbi.git 
cd ${WORKING_DIR}/opensbi
git checkout v0.8
cd -
make -C ${WORKING_DIR}/opensbi PLATFORM=generic FW_PAYLOAD_PATH=${WORKING_DIR}/u-boot-2021.07/u-boot.bin
```
- This generates the build/platform/generic/firmware/fw_payload.elf file
which is a binary that QEMU can boot.
- Starting U-Boot in QEMU
```bash
qemu-system-riscv64 -m 2G \
    -nographic \
    -machine virt \
    -smp 8 \
    -bios opensbi/build/platform/generic/firmware/fw_payload.elf
```
## Start qemu Ubuntu
