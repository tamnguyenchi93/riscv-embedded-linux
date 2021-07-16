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
make -C ${WORKING_DIR}/buildroot-2020.11.1 sdk -j 8
```

- You have an toolchain archive in output/images/riscv64-buildroot-linux-musl_sdkbuildroot.tar.gz

- Extract toolchain
```bash
mkdir $WORKING_DIR/toolchain
tar xf ${WORKING_DIR}/buildroot-2020.11.1/output/images/riscv64-buildroot-linux-musl_sdk-buildroot.tar.gz \
    -C ${WORKING_DIR}/toolchain
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

- Config
  - Unset: `CONFIG_ENV_IS_NOWHERE`
    - Very important. If you don't uboot will try to get env from nowhere and it will store your env to nowwhere
    ```
    => saveenv
    Saving Environment to nowhere... not possible
    ```
    

  - Config boot from FAT disk 
    - CONFIG_ENV_IS_IN_FAT=y
    - CONFIG_ENV_FAT_INTERFACE="virtio"
    - CONFIG_ENV_FAT_DEVICE_AND_PART="0:1"
 
```bash
make -C ${WORKING_DIR}/u-boot-2021.07 menuconfig
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
    -smp 2 \
    -bios ${WORKING_DIR}/opensbi/build/platform/generic/firmware/fw_payload.elf \
    -drive file=${WORKING_DIR}/disk.img,format=raw,id=hd0 \
    -device virtio-blk-device,drive=hd0 \
```

# Linux kernel

```bash
wget https://git.kernel.org/torvalds/t/linux-5.11-rc3.tar.gz -P ${WORKING_DIR}
```

```bash
tar xf ${WORKING_DIR}/linux-5.11-rc3.tar.gz -C ${WORKING_DIR}
```
```bash
make -C ${WORKING_DIR}/linux-5.11-rc3 defconfig
make -C ${WORKING_DIR}/linux-5.11-rc3 menuconfig
make -C ${WORKING_DIR}/linux-5.11-rc3 -j8
```
```
make -C ${WORKING_DIR}/opensbi PLATFORM=generic \
  FW_PAYLOAD_PATH=${WORKING_DIR}/linux-5.11-rc3/arch/riscv/boot/Image
```
```
qemu-system-riscv64 -m 2G \
-nographic \
-machine virt \
-smp 1 \
-kernel  ${WORKING_DIR}/opensbi/build/platform/generic/firmware/fw_payload.elf \
	-drive file=${WORKING_DIR}/disk.img,format=raw,id=hd0 \
  -device virtio-blk-device,drive=hd0 \
	-append "root=/dev/vda2 rootwait console=ttyS0"
```
## Start qemu Ubuntu
- This is a workaround in `GitPod`
```bash
qemu-system-x86_64 \
-nographic \
-drive file=$HOME/qemu/ubuntu-18.04-server-cloudimg-amd64.img,format=qcow2 \
-drive file=$HOME/qemu/user-data.img,format=raw \
-nic user,hostfwd=tcp::22222-:22 \
-m 1G
```

- Create disk.img for qemu
```bash
dd if=/dev/zero of=disk.img bs=1M count=128
```
- Create partition with `cfdisk`
  - Lable type: dos
  - Partition 1:
    - Primary partition
    - Bootable: True
    - size: 64 MB
    - type: `c W95 FAT32 (LBA)`
  - Partition 2:
    - Primary partition
    - size: 64 MB
    - type: Linux (default type)

```bash
cfdisk disk.img
```
- Verify image
```bash
fdisk -l disk.img
```
- Access the partitions in this disk image with `losetup`:
```bash
$ sudo losetup -f --show --partscan disk.img
/dev/loop0
$ ls /dev/loop0*
```
- Format partition
```bash
sudo mkfs.vfat -F 32 -n boot /dev/loop0p1
sudo mkfs.ext4 -L rootfs /dev/loop0p2
```
- Copy kernel `Image` to boot partition
```bash
sudo mkdir /mnt/boot
sudo mount /dev/loop0p1 /mnt/boot
cp ${WORKING_DIR}/linux-5.11-rc3/arch/riscv/boot/Image /mnt/boot
```
- Workaround with QEMU for git pod:
```bash
scp -P 22222 ${WORKING_DIR}/linux-5.11-rc3/arch/riscv/boot/Image ubuntu@localhost:~
```
```bash
sudo cp ~/Image /mnt/boot
sudo umount /mnt/boot
```
```bash
scp -P 22222 ubuntu@localhost:~/disk.img ${WORKING_DIR}
```
# Build Root-file system with busybox
- Download
```bash
wget https://busybox.net/downloads/busybox-1.33.1.tar.bz2 -P ${WORKING_DIR}
```
- Extract source
```bash
tar xf ${WORKING_DIR}/busybox-1.33.1.tar.bz2 -C ${WORKING_DIR}
```
- Build busybox 
```bash
make -C ${WORKING_DIR}/busybox-1.33.1 allnoconfig
make -C ${WORKING_DIR}/busybox-1.33.1 menuconfig
make -C ${WORKING_DIR}/busybox-1.33.1 -j8
make -C ${WORKING_DIR}/busybox-1.33.1 install
```
- Workaround for `GitPod`
```bash
scp -P 22222 -r ${WORKING_DIR}/busybox-1.33.1/_install ubuntu@localhost:~/
```
- Copy file system
```bash
sudo mkdir /mnt/rootfs
sudo mount /dev/loop0p2 /mnt/rootfs
sudo rsync -aH _install/ /mnt/rootfs/
sudo umount /mnt/rootfs

sudo mkdir /mnt/rootfs/dev
sudo mkdir /mnt/rootfs/proc
sudo mkdir /mnt/rootfs/sys
```
