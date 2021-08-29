# Embedded Linux Qemu
- This lab is from https://bootlin.com/doc/training/embedded-linux-qemu/
apt-get install -y autoconf automake gdb git libffi-dev zlib1g-dev libssl-dev 
## QEMU Arm
- Export working dir
```bash
export WORKING_DIR=<RootDIR>/labs/embedded-linux-qemu-labs
```

## Building a cross-compiling toolchain
- Dependencies
```bash
sudo apt-get install -y autoconf \
        bison \
        build-essential \
        flex \
        gawk \
        gettext \
        g++ \
        help2man \
        libncurses-dev \
        libtool-bin \
        texinfo \
        unzip
```

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
  - Enable `CC_LANG_CXX`
  - keep `DEBUG_STRACE` ortherwise disbale Debug facilities
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
arm-linux-gcc -o $WORKING_DIR/toolchain/hello $WORKING_DIR/toolchain/hello.c
qemu-arm -L $WORKING_DIR/toolchain/x-tools/arm-training-linux-uclibcgnueabihf/arm-training-linux-uclibcgnueabihf/sysroot/ \
    $WORKING_DIR/toolchain/hello
```

- Clear crosstool build object
```bash
cd $WORKING_DIR/toolchain/crosstool-ng
./ct-ng clean
cd -
```

- It is worthy to know how to build your own toolchain. But you always can use pre-built arm cross compiler from OS distribute 
  - Install from OS distribute:
     ```bash
     sudo apt-get install gcc-arm-linux-gnueabi
     ```
  - download from [ARM official release](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads). I fail to build busybox with toolchain from ARM release.
    ```bash
    wget  https://developer.arm.com/-/media/Files/downloads/gnu-rm/10.3-2021.07/gcc-arm-none-eabi-10.3-2021.07-x86_64-linux.tar.bz2 -P $WORKING_DIR/toolchain
    tar xf $WORKING_DIR/toolchain/gcc-arm-none-eabi-10.3-2021.07-x86_64-linux.tar.bz2 -C $WORKING_DIR/toolchain
    ```
  - If you use pre-built toolchain, you need to modify [embedded-linux-qemu-env.sh](embedded-linux-qemu-env.sh) to correct value include
     - `CROSS_COMPILE`: toolchain prefix example `arm-none-eabi-`
     - `PATH`: your toolchain path
    
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
$ fdisk -l sd.img
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

- Setup tftp service on host
```bash
$ sudo apt install tftpd-hpa
# Start tftpserver
$ sudo service tftpd-hpa start
# Create test file
echo 'text' | sudo tee -a /srv/tftp/textfile.txt
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
    -net tap,script=$WORKING_DIR/../../qemu-myifup -net nic
```

- Set ip inside of Uboot. In real board, tftp usually for dev. You can usee `dhcp` command to get dynamic ip.

```
setenv ipaddr 192.168.0.100
setenv serverip 192.168.0.1
saveenv
```
- Test ttft server.
```
tftp 0x61000000 textfile.txt
md 0x61000000
```
qemu-img resize ~/qemu/ubuntu-18.04-server-cloudimg-amd64.img +128G

```
qemu-system-arm -M vexpress-a9 -m 128M -nographic \
-kernel $WORKING_DIR/bootloader/u-boot-2020.04/u-boot \
-sd $WORKING_DIR/sd.img
```

## Linux Kernel
- Clone source code.
```bash
mkdir $WORKING_DIR/kernel
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.5.8.tar.gz -P $WORKING_DIR/kernel
tar xf $WORKING_DIR/kernel/linux-5.5.8.tar.gz -C $WORKING_DIR/kernel

make -C $WORKING_DIR/kernel/linux-5.5.8 vexpress_defconfig
```
- Make menuconfig to enable kernel log timestamp
  - CONFIG_PRINTK_TIME
```
make -C $WORKING_DIR/kernel/linux-5.5.8 menuconfig
make -C $WORKING_DIR/kernel/linux-5.5.8 -j8
```
### Boot with tftp
- Copy linux kernel and dtb file to tftp dir
```bash
sudo cp $WORKING_DIR/kernel/linux-5.5.8/arch/arm/boot/zImage /srv/tftp/
sudo cp $WORKING_DIR/kernel/linux-5.5.8/arch/arm/boot/dts/vexpress-v2p-ca9.dtb /srv/tftp/
```

- tftp get linux image
```uboot-shell
tftp 0x61000000 zImage
tftp 0x62000000 vexpress-v2p-ca9.dtb 
```
- Start `linux` kernel
```
bootz 0x61000000 - 0x62000000
```

- For auto boot
```
setenv bootcmd 'tftp 0x61000000 zImage; tftp 0x62000000 vexpress-v2p-ca9.dtb;bootz 0x61000000 - 0x62000000'
saveenv
```
### Boot from sdcard
```bash
scp -P 22222 $WORKING_DIR/kernel/linux-5.5.8/arch/arm/boot/zImage ubuntu@localhost:~
scp -P 22222 $WORKING_DIR/kernel/linux-5.5.8/arch/arm/boot/dts/vexpress-v2p-ca9.dtb ubuntu@localhost:~
```

- Create image
```bash
$ dd if=/dev/zero of=$WORKING_DIR/sd.img bs=1M count=128
$ sudo losetup -f --show --partscan $WORKING_DIR/sd.img
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
sudo cp $WORKING_DIR/kernel/linux-5.5.8/arch/arm/boot/zImage /mnt/boot
sudo cp $WORKING_DIR/kernel/linux-5.5.8/arch/arm/boot/dts/vexpress-v2p-ca9.dtb /mnt/boot
sudo umount /mnt/boot
```
```bash
sudo losetup -d /dev/loop0
```

```bash
scp -P 22222 ubuntu@localhost:~/sd.img $WORKING_DIR
```

```bash
qemu-system-arm -M vexpress-a9 -m 128M -nographic \
-kernel $WORKING_DIR/bootloader/u-boot-2020.04/u-boot \
-sd $WORKING_DIR/sd.img
```

setenv bootargs console=ttyAMA0 earlyprintk=serial
fatload mmc 0 0x61000000 zImage
fatload mmc 0 0x62000000 vexpress-v2p-ca9.dtb
bootz 0x61000000 - 0x62000000

setenv bootargs console=ttyAMA0 earlyprintk=serial
setenv bootcmd 'fatload mmc 0 0x61000000 zImage; fatload mmc 0 0x62000000 vexpress-v2p-ca9.dtb;bootz 0x61000000 - 0x62000000'
saveenv

## Tiny filesystem
- Rebuilt kernel linux with `CONFIG_DEVTMPFS_MOUNT`
  - Make sure you update: new linux kernel into tftp dir or copy to sd card image.

- Get `busybox` source code:
```bash
wget https://busybox.net/downloads/busybox-1.33.0.tar.bz2 -P $WORKING_DIR/tinysystem
tar xf $WORKING_DIR/tinysystem/busybox-1.33.0.tar.bz2 -C $WORKING_DIR/tinysystem
```
- Busy-box make menuconfig or use `.config` from lab data
  - This pre-config file contain action: [labs/embedded-linux-qemu-labs/tinysystem/busybox-1.33.config](labs/embedded-linux-qemu-labs/tinysystem/busybox-1.33.config)
     - `CONFIG_PREFIX="../nfsroot"`

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

### Mount rootfs with nfs
- Install NFS server
```bash
sudo apt-get install -y nfs-kernel-server
echo "$WORKING_DIR/tinysystem/nfsroot 192.168.0.100(rw,no_root_squash,no_subtree_check)" | sudo tee -a /etc/exports
mkdir -p $WORKING_DIR/tinysystem/nfsroot
sudo /etc/init.d/rpcbind restart
sudo /etc/init.d/nfs-kernel-server restart
```

- Start qemu
```bash
sudo qemu-system-arm -M vexpress-a9 -m 128M -nographic \
    -kernel $WORKING_DIR/bootloader/u-boot-2020.04/u-boot \
    -sd $WORKING_DIR/sd.img \
    -net tap,script=$WORKING_DIR/../../qemu-myifup \
    -net nic
```

- Set bootargs in `uboot`
```
setenv bootargs ${bootargs} root=/dev/nfs ip=192.168.0.100:::::eth0 nfsroot=192.168.0.1:/home/linux/workspace/riscv-embedded-linux/labs/embedded-linux-qemu-labs/tinysystem/nfsroot,nfsvers=3,tcp rw
saveenv
```

------------------------
Common issues:
 - `VFS: Unable to mount root fs via NFS, trying floppy`: make sure that you config bootargs to correct path.
    - `/var/log/syslog`: check log system from host to get more infomation
      - If there is not file `/var/log/syslog`: check `rsyslog`
        ```bash
        $ service rsyslog status
        * rsyslogd is not running
        $ service rsyslog start
        * Starting enhanced syslogd rsyslogd
        $ service rsyslog status
        * rsyslogd is running
        ```
  - If you see error:
    ```
    process '-/bin/sh' (pid 102) exited. Scheduling for restart.
    can't open /dev/tty3: No such file or directory
    can't open /dev/tty2: No such file or directory
    ```
    - Please make sure your kernel image have `CONFIG_DEVTMPFS_MOUNT` and you update it.
    - Create folder `dev` under `labs/embedded-linux-qemu-labs/tinysystem/nfsroot`.
    

--------

- If everything work fine you will see the log: `VFS: Mounted root (nfs filesystem) on device 0:14.`. But of course system will fail because we don't have `rootfs`. We just verify that NFS config is working. Boot with nfs server could be usefull when bring up board.

### System configuration and startup
- Create system folder:
```bash 
mkdir $WORKING_DIR/tinysystem/nfsroot/etc
mkdir $WORKING_DIR/tinysystem/nfsroot/proc
mkdir $WORKING_DIR/tinysystem/nfsroot/sys
```

- Create `$WORKING_DIR/tinysystem/nfsroot/etc` with content see [examples/inittab](https://elixir.bootlin.com/busybox/latest/source/examples/inittab)
  - Target:
    - Execute `init.d/rcS` script
    - Start an "askfirst" shell on the console (whatever that may be). You can also specific console too.
  ```
  # Boot-time system configuration/initialization script.
  # This is run first except when booting in single-user mode.
  #
  ::sysinit:/etc/init.d/rcS
  
  # Start an "askfirst" shell on the console (whatever that may be)
  ::askfirst:-/bin/sh
  ```

- Create `$WORKING_DIR/tinysystem/nfsroot/etc/init.d/rcS`
  - Mount `proc` and mount `sys` folder.
  - Make sure chmod `$WORKING_DIR/tinysystem/nfsroot/etc/init.d/rcS` to excuted.
  ```bash
  #!/bin/sh
  echo "Mounting proc"
  mount -t proc nodev /proc
  echo "Mounting sys"
  mount -t sysfs nodev /sys
  ```
### Switching to shared libraries
- Try to build hello world on host and run on board.
- Build hello.c in `$WORKING_DIR/tinysystem/data/hello.c`

  ```bash
  # Build sample app
  arm-linux-gcc -o $WORKING_DIR/tinysystem/data/hello $WORKING_DIR/tinysystem/data/hello.c
  mv $WORKING_DIR/tinysystem/data/hello $WORKING_DIR/tinysystem/nfsroot/bin/hello
  # copy clib
  mkdir $WORKING_DIR/tinysystem/nfsroot/lib/
  cp $WORKING_DIR/toolchain/x-tools/arm-training-linux-uclibcgnueabihf/arm-training-linux-uclibcgnueabihf/sysroot/lib/ld-uClibc.so.0 $WORKING_DIR/tinysystem/nfsroot/lib/
  cp $WORKING_DIR/toolchain/x-tools/arm-training-linux-uclibcgnueabihf/arm-training-linux-uclibcgnueabihf/sysroot/lib/libc.so.0 $WORKING_DIR/tinysystem/nfsroot/lib/
  ```
### Implement a web interface for your device
```bash
cp -r $WORKING_DIR/tinysystem/data/www $WORKING_DIR/tinysystem/nfsroot
```

## Filesystems - Block file systems

```bash
$ sudo losetup -f --show --partscan $WORKING_DIR/sd.img
/dev/loop0
$ sudo mkfs.ext4 -L data /dev/loop0p3
```

- Create folder to mount disk.
```bash
sudo mkdir -p /mnt/data
sudo mkdir -p /mnt/filesystem
```
- Mount disk.
```bash
sudo mount /dev/loop0p1 /mnt/boot
sudo mount /dev/loop0p2 /mnt/filesystem
sudo mount /dev/loop0p3 /mnt/data
```
- Copy kernel iamge to boot partition
```bash
sudo cp $WORKING_DIR/kernel/linux-5.5.8/arch/arm/boot/zImage /mnt/boot
sudo cp $WORKING_DIR/kernel/linux-5.5.8/arch/arm/boot/dts/vexpress-v2p-ca9.dtb /mnt/boot
```
- Copy file system.
```
sudo mv $WORKING_DIR/tinysystem/nfsroot/www/upload/files /mnt/data/
sudo cp -r $WORKING_DIR/tinysystem/nfsroot/* /mnt/filesystem
```
- Unmount partition.
```bash
sudo umount /mnt/boot
sudo umount /mnt/data
sudo umount /mnt/filesystem
sudo losetup -d /dev/loop0
```
- Start qemu
```bash
sudo qemu-system-arm -M vexpress-a9 -m 128M -nographic \
    -kernel $WORKING_DIR/bootloader/u-boot-2020.04/u-boot \
    -sd $WORKING_DIR/sd.img \
    -net tap,script=$WORKING_DIR/../../qemu-myifup \
    -net nic
```
- Change uboot env to load Linux kernel from sd card instead of `tftp`. And set root file system to sd card partition 2.
```
setenv bootcmd 'fatload mmc 0:1 0x61000000 zImage; fatload mmc 0:1 0x62000000 vexpress-v2p-ca9.dtb;bootz 0x61000000 - 0x62000000'
setenv bootargs console=ttyAMA0 earlyprintk=serial root=/dev/mmcblk0p2 rootwait
saveenv
```

- Start boot.
```
boot
```

-------------------------------------------------------------
Note: Now you have a board with run a linux but that is. It just a normal linux without any application.
It is not like you computer that run other OS distribute like Ubuntu.

-------------------------------------------------------------

## Third party libraries and applications
- Audio support in the Kernel
- Re-compile kernel with audio support:
  - CONFIG_SOUND
  - CONFIG_SND
  - CONFIG_SND_USB
  - CONFIG_SND_USB_AUDIO
  ```bash
  make -C $WORKING_DIR/kernel/linux-5.5.8 menuconfig
  make -C $WORKING_DIR/kernel/linux-5.5.8 -j
  ```
- Create two spaces:
  - A `staging` space:
    - non-stripped versions of the libraries
    - not be used on our target
  - A `target` space
    - take a lot less space than the staging space
    - binaries and libraries, after stripping

```bash
mkdir -p $WORKING_DIR/thirdparty/staging
mkdir -p $WORKING_DIR/thirdparty/target
```

- Reuse tiny filesystem from previous lab:
```bash
cp -a $WORKING_DIR/tinysystem/nfsroot/* $WORKING_DIR/thirdparty/target
```
### alsa-lib
- Download version 1.2.3.2 (there’s an issue in version 1.2.4 for the moment)
```bash
wget https://www.alsa-project.org/files/pub/lib/alsa-lib-1.2.3.2.tar.bz2 -P $WORKING_DIR/thirdparty/
tar xf $WORKING_DIR/thirdparty/alsa-lib-1.2.3.2.tar.bz2 -C $WORKING_DIR/thirdparty/
```

- Configure `alsa-lib` with `arm-linux-gcc`
```bash
cd $WORKING_DIR/thirdparty/alsa-lib-1.2.3.2
CC=arm-linux-gcc ./configure --host=arm-linux
make
```
- Verify build complete
```bash
$ ll src/.libs/libasound.so*
lrwxrwxrwx 1 linux linux      18 Aug 22 13:00 src/.libs/libasound.so -> libasound.so.2.0.0*
lrwxrwxrwx 1 linux linux      18 Aug 22 13:00 src/.libs/libasound.so.2 -> libasound.so.2.0.0*
-rwxrwxr-x 1 linux linux 4011428 Aug 22 13:00 src/.libs/libasound.so.2.0.0*
```
- These symlinks
  - **libasound.so** is used at compile time when you want to compile an application
    - **-lLIBNAME** option to thecompiler, which will look for a file named **lib<LIBNAME>.so**
  - **libasound.so.2** is needed because it is the **SONAME** of the library.

- To read SONAME of a library
```bash
arm-linux-readelf -d src/.libs/libasound.so.2.0.0 | grep SONAME
```
- `configure` script where the library is going to be installed - when run time.
```bash
CC=arm-linux-gcc ./configure --host=arm-linux --prefix=/usr
make
```
- Install `alsa-lib` into our rootfile system at 
```bash
make DESTDIR=$WORKING_DIR/thirdparty/staging install
tree $WORKING_DIR/thirdparty/staging/usr
```

- Install the library in the target space
```bash
# create target/usr/lib directory
$ mkdir -p $WORKING_DIR/thirdparty/target/usr/lib
$ cp -a $WORKING_DIR/thirdparty/staging/usr/lib/libasound.so.2* $WORKING_DIR/thirdparty/target/usr/lib
# Check size of library 3.9M
$ ls -hs $WORKING_DIR/thirdparty/target/usr/lib/libasound.so.2.0.0
# Strip the library
arm-linux-strip $WORKING_DIR/thirdparty/target/usr/lib/libasound.so.2.0.0
# Size after srtip 796K
```
### Alsa-utils
- Download alsa-utils 1.2.4
```bash
wget https://www.alsa-project.org/files/pub/utils/alsa-utils-1.2.3.tar.bz2 -P $WORKING_DIR/thirdparty/
tar xf $WORKING_DIR/thirdparty/alsa-utils-1.2.3.tar.bz2 -C $WORKING_DIR/thirdparty/
```

- Compile als-utils. There are so many infomation about the command. Please check the lab document.
```bash
cd $WORKING_DIR/thirdparty/alsa-utils-1.2.3
LDFLAGS=-L$WORKING_DIR/thirdparty/staging/usr/lib \
    CPPFLAGS=-I$WORKING_DIR/thirdparty/staging/usr/include \
    CC=arm-linux-gcc ./configure --host=arm-linux --prefix=/usr \
    --disable-alsamixer --disable-xmlto
make
```
- Install to `$WORKING_DIR/thirdparty/staging`
```bash
make DESTDIR=$WORKING_DIR/thirdparty/staging install
```

- Again copy all necessary files in the target space, manually
```bash
cd ..
cp -a staging/usr/bin/a* staging/usr/bin/speaker-test target/usr/bin/
cp -a staging/usr/sbin/alsa* target/usr/sbin
arm-linux-strip target/usr/bin/a*
arm-linux-strip target/usr/bin/speaker-test
arm-linux-strip target/usr/sbin/alsactl
mkdir -p target/usr/share/alsa/pcm
cp -a staging/usr/share/alsa/alsa.conf* target/usr/share/alsa/
cp -a staging/usr/share/alsa/cards target/usr/share/alsa/
cp -a staging/usr/share/alsa/pcm/default.conf target/usr/share/alsa/pcm/
```

### libogg
- Download libogg 1.3.4
```bash
wget https://ftp.osuosl.org/pub/xiph/releases/ogg/libogg-1.3.4.tar.gz  -P $WORKING_DIR/thirdparty/
tar xf $WORKING_DIR/thirdparty/libogg-1.3.4.tar.gz -C $WORKING_DIR/thirdparty/
```
- Build `libogg`
```bash
cd $WORKING_DIR/thirdparty/libogg-1.3.4
CC=arm-linux-gcc ./configure --host=arm-linux --prefix=/usr
make 
make DESTDIR=$WORKING_DIR/thirdparty/staging/ install
```
- Manually instlal to `target` space:
```bash
cp -a $WORKING_DIR/thirdparty/staging/usr/lib/libogg.so.0* $WORKING_DIR/thirdparty/target/usr/lib/
arm-linux-strip $WORKING_DIR/thirdparty/target/usr/lib/libogg.so.0.8.4
```

### libvorbis
- Download libvorbis 1.3.7
```bash
wget https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-1.3.7.tar.gz -P $WORKING_DIR/thirdparty/
tar xf $WORKING_DIR/thirdparty/libvorbis-1.3.7.tar.gz -C $WORKING_DIR/thirdparty/
```
- Build `libvorbis`
```bash
cd $WORKING_DIR/thirdparty/libvorbis-1.3.7

CC=arm-linux-gcc ./configure --host=arm-linux --prefix=/usr \
    --with-ogg-includes=$WORKING_DIR/thirdparty/staging/usr/include \
    --with-ogg-libraries=$WORKING_DIR/thirdparty/staging/usr/lib
make 
make DESTDIR=$WORKING_DIR/thirdparty/staging/ install
```
- Manually install to `target` space:
```bash
cp -a $WORKING_DIR/thirdparty/staging/usr/lib/libvorbis.so.0* $WORKING_DIR/thirdparty/target/usr/lib/
arm-linux-strip $WORKING_DIR/thirdparty/target/usr/lib/libvorbis.so.0.4.9
cp -a $WORKING_DIR/thirdparty/staging/usr/lib/libvorbisfile.so.3* $WORKING_DIR/thirdparty/target/usr/lib/
arm-linux-strip $WORKING_DIR/thirdparty/target/usr/lib/libvorbisfile.so.3.3.8
```

### libao

- Download libao 1.2.0
```bash
wget https://ftp.osuosl.org/pub/xiph/releases/ao/libao-1.2.0.tar.gz -P $WORKING_DIR/thirdparty/
tar xf $WORKING_DIR/thirdparty/libao-1.2.0.tar.gz -C $WORKING_DIR/thirdparty/
```
- Build `libao`
```bash
cd $WORKING_DIR/thirdparty/libao-1.2.0
LDFLAGS=-L$WORKING_DIR/thirdparty/staging/usr/lib \
    CPPFLAGS=-I$WORKING_DIR/thirdparty/staging/usr/include \
    CC=arm-linux-gcc ./configure --host=arm-linux --prefix=/usr
make 
make DESTDIR=$WORKING_DIR/thirdparty/staging/ install
```
- Manually install to `target` space:
```bash
cp -a $WORKING_DIR/thirdparty/staging/usr/lib/libao.so.4* $WORKING_DIR/thirdparty/target/usr/lib/
arm-linux-strip $WORKING_DIR/thirdparty/target/usr/lib/libao.so.4.1.0
```
- Copy plugin that is loaded dynamically by libao at startup:
```bash
mkdir -p $WORKING_DIR/thirdparty/target/usr/lib/ao/plugins-4/
cp -a $WORKING_DIR/thirdparty/staging/usr/lib/ao/plugins-4/libalsa.so $WORKING_DIR/thirdparty/target/usr/lib/ao/plugins-4/
```

### vorbis-tools

- Download vorbis-tools 1.4.2
```bash
wget https://downloads.xiph.org/releases/vorbis/vorbis-tools-1.4.2.tar.gz -P $WORKING_DIR/thirdparty/
tar xf $WORKING_DIR/thirdparty/vorbis-tools-1.4.2.tar.gz -C $WORKING_DIR/thirdparty/
```
- Build `vorbis-tools`
```bash
cd $WORKING_DIR/thirdparty/vorbis-tools-1.4.2
LDFLAGS=-L$WORKING_DIR/thirdparty/staging/usr/lib \
    CPPFLAGS=-I$WORKING_DIR/thirdparty/staging/usr/include \
    CC=arm-linux-gcc ./configure --host=arm-linux --prefix=/usr
```
- NOTE: The worse thing can happen with cross compile is mixed between host library and target library. configure script uses the pkg-config system to get the configuration parameters
- Reconfig passing the PKG_CONFIG_LIBDIR and PKG_CONFIG_SYSROOT_DIR environment variables:
```bash
LDFLAGS=-L$WORKING_DIR/thirdparty/staging/usr/lib \
    CPPFLAGS=-I$WORKING_DIR/thirdparty/staging/usr/include \
    PKG_CONFIG_LIBDIR=$WORKING_DIR/thirdparty/staging/usr/lib/pkgconfig \
    PKG_CONFIG_SYSROOT_DIR=$WORKING_DIR/thirdparty/staging \
    CC=arm-linux-gcc \
    ./configure --host=arm-linux --prefix=/usr \
    --without-curl
```
- If you still cannot build because of wrong version of libraries. That maybe you did not install `pkg-config`
```bash
# after install pkg-config
# verify package in your staging space
$ PKG_CONFIG_LIBDIR=$WORKING_DIR/thirdparty/staging/usr/lib/pkgconfig pkg-config  --list-all
# Compare to host package
$ pkg-config --list-all
```

```bash
make 
make DESTDIR=$WORKING_DIR/thirdparty/staging/ install
```
- Manually install to `target` space:
```bash
cp -a $WORKING_DIR/thirdparty/staging/usr/bin/ogg* $WORKING_DIR/thirdparty/target/usr/bin
arm-linux-strip $WORKING_DIR/thirdparty/target/usr/bin/ogg*
```
## Testing
### Test with nfs root filesystem
- Add `$WORKING_DIR/thirdparty/target` and `$WORKING_DIR/thirdparty/staging` to nfsfile
```bash
echo "$WORKING_DIR/thirdparty/staging 192.168.0.100(rw,no_root_squash,no_subtree_check)" | sudo tee -a /etc/exports
echo "$WORKING_DIR/thirdparty/target 192.168.0.100(rw,no_root_squash,no_subtree_check)" | sudo tee -a /etc/exports
sudo /etc/init.d/rpcbind restart
sudo /etc/init.d/nfs-kernel-server restart
cp $WORKING_DIR/thirdparty/data/* $WORKING_DIR/thirdparty/target
```

- Start qemu
```bash
sudo qemu-system-arm -M vexpress-a9 -m 128M -nographic \
    -kernel $WORKING_DIR/bootloader/u-boot-2020.04/u-boot \
    -sd $WORKING_DIR/sd.img \
    -net tap,script=$WORKING_DIR/../../qemu-myifup \
    -net nic
```

- Set bootargs in `uboot`
```
setenv bootargs ${bootargs} root=/dev/nfs ip=192.168.0.100:::::eth0 nfsroot=192.168.0.1:/home/linux/workspace/riscv-embedded-linux/labs/embedded-linux-qemu-labs/thirdparty/target,nfsvers=3,tcp rw
saveenv
```

- Fix missing C library object.
  ```
  ERROR: Failed to load plugin /usr/lib/ao/plugins-4/libalsa.so => dlopen() failed
  === Could not load default driver and no driver specified in config file. Exiting.
  ```
- Strace error
```bash
cp $WORKING_DIR//toolchain/x-tools/arm-training-linux-uclibcgnueabihf/arm-training-linux-uclibcgnueabihf/debug-root/usr/bin/strace \
    $WORKING_DIR/thirdparty/target/usr/bin
```
```bash
ll $WORKING_DIR/thirdparty/target/lib
rm $WORKING_DIR/thirdparty/target/lib/ld-uClibc.so.0*
cp $WORKING_DIR//toolchain/x-tools/arm-training-linux-uclibcgnueabihf/arm-training-linux-uclibcgnueabihf/sysroot/lib/ld-uClibc-1.0.36.so* $WORKING_DIR/thirdparty/target/lib/

cd $WORKING_DIR/thirdparty/target/lib/
ln -s ld-uClibc-1.0.36.so* ld-uClibc.so.0
ln -s ld-uClibc-1.0.36.so* ld-uClibc.so.1
cd -
```

- Test `ogg123`
```
ogg123 /sample.ogg
```

## Builtroot
- Download buildroot source code
```bash
mkdir $WORKING_DIR/buildroot
wget https://buildroot.org/downloads/buildroot-2021.05.1.tar.gz -P $WORKING_DIR/buildroot
tar xf $WORKING_DIR/buildroot/buildroot-2021.05.1.tar.gz -C $WORKING_DIR/buildroot
```

- Config buildroot
```bash
make -C $WORKING_DIR/buildroot/buildroot-2021.05.1 menuconfig
```

- Build builtroot
```bash
make -C $WORKING_DIR/buildroot/buildroot-2021.05.1 -j3
```

- create nfsroot
```bash
mkdir -p $WORKING_DIR/buildroot/nfsroot
cd $WORKING_DIR/buildroot/nfsroot
tar xvf ../buildroot-2021.05.1/output/images/rootfs.tar
```
- Copy sample file
```bash
cp $WORKING_DIR/thirdparty/data/* $WORKING_DIR/buildroot/nfsroot/
```

- Add builtroot file system to nfs server
```bash
echo "$WORKING_DIR/buildroot/nfsroot 192.168.0.100(rw,no_root_squash,no_subtree_check)" | sudo tee -a /etc/exports
# restart nfs server
sudo /etc/init.d/rpcbind restart
sudo /etc/init.d/nfs-kernel-server
```

- Start qemu and edit uboot 
```
sudo qemu-system-arm -M vexpress-a9 -m 128M -nographic \
    -kernel $WORKING_DIR/bootloader/u-boot-2020.04/u-boot \
    -sd $WORKING_DIR/sd.img \
    -net tap,script=$WORKING_DIR/../../qemu-myifup \
    -net nic
```

- Set `bootargs`
```
setenv bootargs ${bootargs} root=/dev/nfs ip=192.168.0.100:::::eth0 nfsroot=192.168.0.1:/home/linux/workspace/riscv-embedded-linux/labs/embedded-linux-qemu-labs/buildroot/nfsroot,nfsvers=3,tcp rw
```

- Start boot and verify `ogg123`. Builtroot already setup every for us, we don't face the issue where lib is missed.
### Create file system in SD card instead of nfs
- TODO: 