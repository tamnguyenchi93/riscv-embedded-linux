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
cd $WORKING_DIR/u-boot-2020.04/
cat $WORKING_DIR//embedded-linux-qemu-labs/bootloader/data/vexpress_flags_reset.patch | patch -p1
```
- Use define config `vexpress_ca9x4_defconfig`
```bash
make -C $WORKING_DIR/u-boot-2020.04/ vexpress_ca9x4_defconfig
```
- Config uboot environment
```bash
make -C $WORKING_DIR/u-boot-2020.04/ menuconfig
make -C $WORKING_DIR/u-boot-2020.04/ -j
```
```bash
qemu-system-arm -M vexpress-a9 -m 128M -nographic -kernel u-boot
qemu-system-arm -M vexpress-a9 -m 128M -nographic \
  -kernel $WORKING_DIR/u-boot-2020.04/u-boot \
  -sd sd.img
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
# Create partition
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

qemu-system-arm -M vexpress-a9 -m 128M -nographic \
-kernel u-boot-2020.04/u-boot \
-sd sd.img