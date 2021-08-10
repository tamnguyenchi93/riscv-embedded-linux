# Embedded Linux Qemu
- This lab is from https://bootlin.com/doc/training/embedded-linux-qemu/

## QEMU Arm
- Export working dir
```bash
export WORKING_DIR=<RootDIR>/labs/embedded-linux-qemu-labs
```

## Building a cross-compiling toolchain
- Clone source
```bash
git -C $WORKING_DIR/toolchain clone https://github.com/crosstool-ng/crosstool-ng.git
```

- Setup `ct-ng` tool:
```bash
cd $WORKING_DIR/toolchain/crosstool-ng
git checkout 79fcfa17
./bootstrap
./configure --enable-local
make
```
- Build `cortexa9` toolchain
```bash
./ct-ng list-samples
./ct-ng show-arm-cortexa9_neon-linux-gnueabihf
./ct-ng arm-cortexa9_neon-linux-gnueabihf
```
- Config built target
  - Set Tuple's vendor string (TARGET_VENDOR) to training.
  - Set Tuple's alias (TARGET_ALIAS) to arm-linux.
  - C-library: uClibc (LIBC_UCLIBC)
```bash
./ct-ng menuconfig
# This will take very long time
./ct-ng build
```
- After build done the binary is at: `~/x-tools/`
```bash
cp -r ~/x-tools/ $WORKING_DIR/toolchain/x-tools
```
- Source environment script:
```bash
cd <ROOT_DIR>
source embedded-linux-qemu-env.sh
```

- Test toolchain
```bash
# Build hello program
cd 
arm-linux-gcc -o $WORKING_DIR/toolchain/hello $WORKING_DIR/toolchain/hello.c
qemu-arm -L $WORKING_DIR/toolchain/x-tools/arm-training-linux-uclibcgnueabihf/arm-training-linux-uclibcgnueabihf/sysroot/ \
    $WORKING_DIR/toolchain/hello
```

- Clear crosstool build object
```bash
cd $WORKING_DIR/crosstool-ng
./ct-ng clean
cd -
```
## U-Booot
- Download u-boot-2020.04
```bash
wget https://github.com/u-boot/u-boot/archive/refs/tags/v2020.04.tar.gz -P $WORKING_DIR/bootloader
tar xf $WORKING_DIR/bootloader/v2020.04.tar.gz -C $WORKING_DIR/bootloader
```
- 
```bash
cd $WORKING_DIR/bootloader/u-boot-2020.04/
cat $WORKING_DIR/bootloader/data/vexpress_flags_reset.patch | patch -p1
```
- Use define config `vexpress_ca9x4_defconfig`
```bash
make -C $WORKING_DIR/bootloader/u-boot-2020.04/ vexpress_ca9x4_defconfig
```
- Config uboot environment
  - Unset Environment in flash memory (CONFIG_ENV_IS_IN_FLASH)
  - Set Environment is in a FAT filesystem (CONFIG_ENV_IS_IN_FAT)
  - Set Name of the block device for the environment (CONFIG_ENV_FAT_INTERFACE): `mmc`
  - Device and partition for where to store the environment in FAT (CONFIG_ENV_FAT_DEVICE_AND_PART): `0:1`
  - Enable `editenv` command (CONFIG_CMD_EDITENV).
  - Enable `bootd` command (CONFIG_CMD_BOOTD).
```bash
make -C $WORKING_DIR/bootloader/u-boot-2020.04/ menuconfig
make -C $WORKING_DIR/bootloader/u-boot-2020.04/ -j
```
```bash
qemu-system-arm -M vexpress-a9 -m 128M -nographic -kernel $WORKING_DIR/bootloader/u-boot-2020.04/u-boot
```
- SD card setup
```bash
# Star QEMU Ubuntu with ubuntu:ubuntu
start-qemu-x86_64.sh
```
- Create image with 3 partitions:
  - 64MB, with the FAT16 partition type.
  - 8MB, for rootfs.
  - rest of the SD card image, that will be used for the data filesystem.
```bash
dd if=/dev/zero of=sd.img bs=1M count=512
dd if=/dev/zero of=sd.img bs=1M count=128
# Create partition
cfdisk sd.img
```

- Verify image to make sure partitions are created.
```bash
$ fdisk -l disk.img
Disk sd.img: 512 MiB, 536870912 bytes, 1048576 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0xd9363149

Device     Boot  Start     End Sectors  Size Id Type
sd.img1    *      2048  133119  131072   64M  6 FAT16
sd.img2         133120  149503   16384    8M 83 Linux
sd.img3         149504 1048575  899072  439M 83 Linux
```

- 
```bash
$ sudo losetup -f --show --partscan sd.img
/dev/loop0
```

```
sudo mkfs.vfat -F 16 -n boot /dev/loop<x>p1
```
- Start `qemu-system-arm` with `sd.img`:
```bash
qemu-system-arm -M vexpress-a9 -m 128M -nographic \
-kernel $WORKING_DIR/bootloader/u-boot-2020.04/u-boot \
-sd $WORKING_DIR/sd.img
```

- Setup network script
```bash
chmod +x $WORKING_DIR/bootloader/qemu-myifup
```
- Start `qemu` with network card
```bash
sudo qemu-system-arm -M vexpress-a9 -m 128M -nographic \
-kernel $WORKING_DIR/bootloader/u-boot-2020.04/u-boot \
-sd $WORKING_DIR/sd.img \
-net tap,script=$WORKING_DIR/bootloader/qemu-myifup -net nic  -nic user,
```

qemu-img resize ~/qemu/ubuntu-18.04-server-cloudimg-amd64.img +128G

```
qemu-system-arm -M vexpress-a9 -m 128M -nographic \
-kernel $WORKING_DIR/bootloader/u-boot-2020.04/u-boot \
-sd $WORKING_DIR/sd.img \
-nic user
```

## Linux Kernel
mkdir $WORKING_DIR/kernel
wget https://mirrors.edge.kernel.org/pub/linux/kernel/v5.x/linux-5.5.8.tar.gz -P $WORKING_DIR/kernel
tar xf $WORKING_DIR/kernel/linux-5.5.8.tar.gz -C $WORKING_DIR/kernel

make -C $WORKING_DIR/kernel/linux-5.5.8 vexpress_defconfig
make -C $WORKING_DIR/kernel/linux-5.5.8 -j


scp -P 22222 $WORKING_DIR/kernel/linux-5.5.8/arch/arm/boot/zImage ubuntu@localhost:~
scp -P 22222 $WORKING_DIR/kernel/linux-5.5.8/arch/arm/boot/dts/vexpress-v2p-ca9.dtb ubuntu@localhost:~


```bash
$ sudo losetup -f --show --partscan sd.img
/dev/loop0
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
```

- Copy `Kernel image` to `boot` partition.
```bash
sudo cp ~/zImage /mnt/boot
sudo cp ~/vexpress-v2p-ca9.dtb /mnt/boot
sudo umount /mnt/boot
```

```bash
scp -P 22222 ubuntu@localhost:~/sd.img $WORKING_DIR
```

```bash
qemu-system-arm -M vexpress-a9 -m 128M -nographic \
-kernel $WORKING_DIR/bootloader/u-boot-2020.04/u-boot \
-sd $WORKING_DIR/sd.img
```

setenv bootargs console=ttyAMA0 earlycon=sbi
fatload mmc 0 0x61000000 zImage
fatload mmc 0 0x62000000 vexpress-v2p-ca9.dtb
bootz 0x61000000 - 0x62000000

setenv bootargs console=ttyAMA0 earlycon=sbi
setenv bootcmd 'fatload mmc 0 0x61000000 zImage; fatload mmc 0 0x62000000 vexpress-v2p-ca9.dtb;bootz 0x61000000 - 0x62000000'
saveenv

## Tiny filesystem

```bash
wget https://busybox.net/downloads/busybox-1.33.0.tar.bz2 -P $WORKING_DIR/tinysystem
tar xf $WORKING_DIR/tinysystem/busybox-1.33.0.tar.bz2 -C $WORKING_DIR/tinysystem
```
- Busy-box make menuconfig or use `.config` from lab data
```bash
cp $WORKING_DIR/tinysystem/data/busybox-1.33.config $WORKING_DIR/tinysystem/busybox-1.33.0/.config
# Config busybox your self
make -C $WORKING_DIR/tinysystem/busybox-1.33.0 menuconfig
```
- Build busybox
```bash
make -C $WORKING_DIR/tinysystem/busybox-1.33.0 -j
make -C $WORKING_DIR/tinysystem/busybox-1.33.0 install
```