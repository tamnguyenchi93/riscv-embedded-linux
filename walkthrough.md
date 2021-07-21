# Walkthrough
## Create Working Dir
- Create working dir.
```bash
mkdir tmp
```
- Create `WORKING_DIR` environment variable.
  - **NOTE**: Do this to every new console you have.
```bash
cd tmp
export WORKING_DIR=`pwd`
cd -
```

## Generating a RISC-V musl toolchain with Buildroot
- Download Buildroot 2020.11.1 from [buildroot.org](https://buildroot.org/download.html).
```bash
wget https://buildroot.org/downloads/buildroot-2020.11.1.tar.gz -P ${WORKING_DIR}
```

- Extract buildroot source.
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
- Source env. 
  - **NOTE**: Do this to every new console you have.
```
source riscv64-env.sh
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
make -C ${WORKING_DIR}/u-boot-2021.07 a
```

- Config
  ```bash
  make -C ${WORKING_DIR}/u-boot-2021.07 menuconfig
  ```
  - Unset: `CONFIG_ENV_IS_NOWHERE`
    - Very important. If you don't uboot will try to get env from nowhere and it will store your env to nowwhere. 
    ```
    => saveenv
    Saving Environment to nowhere... not possible
    ```
  - Config boot from FAT disk 
    - CONFIG_ENV_IS_IN_FAT=y
    - CONFIG_ENV_FAT_INTERFACE="virtio"
    - CONFIG_ENV_FAT_DEVICE_AND_PART="0:1"
 
- Compile U-Boot
```bash
make -C ${WORKING_DIR}/u-boot-2021.07 -j8
```

## OpenSBI
- Clone OpenSBI
```bash
git -C ${WORKING_DIR} clone https://github.com/riscv/opensbi.git 
cd ${WORKING_DIR}/opensbi
git checkout v0.8
cd -
```
- Build fw_payload.elf file
```bash
make -C ${WORKING_DIR}/opensbi PLATFORM=generic FW_PAYLOAD_PATH=${WORKING_DIR}/u-boot-2021.07/u-boot.bin
```

- Starting U-Boot in QEMU
```bash
./start-qemu-uboot.sh
```

## Linux kernel

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

## Create disk.img to store your linux kernel
- This is a workaround in `GitPod`
- Start qemu
```bash
./start-qemu-x86_64.sh
```

- Create disk.img for qemu
```bash
dd if=/dev/zero of=disk.img bs=1M count=128
```
- Create partition with `cfdisk`
  ```bash
  cfdisk disk.img
  ```
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

- Verify image to make sure partitions are created.
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
```

- Copy `Kernel image` from gitpod to Ubuntu VM:
```bash
scp -P 22222 ${WORKING_DIR}/linux-5.11-rc3/arch/riscv/boot/Image ubuntu@localhost:~
```
- Copy `Kernel image` to `boot` partition.
```bash
sudo cp ~/Image /mnt/boot
sudo umount /mnt/boot
```
- Copy `disk.img` from VM to gitpod env:
```bash
scp -P 22222 ubuntu@localhost:~/disk.img ${WORKING_DIR}
```
- Start Kernel
```bash
./start-qemu-uboot-linux.sh
```
  - Now you can load Linux kernel from: `OpenSBI -> U-Boot -> Linux`.
    - You will see some error and kernel panic log.
    - Now you need to build root file system with busybox to have User application.

## Build Root file system with busybox
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

sudo mkdir /mnt/rootfs/dev
sudo mkdir /mnt/rootfs/proc
sudo mkdir /mnt/rootfs/sys
sudo umount /mnt/rootfs
```

- Start Qemu:
```
./start-qemu-uboot-linux.sh
```
- Now you have user application. But it is not fully work, please check the lab know what to do next to make it work.
# OpenSBI start Linux Kernel
- https://github.com/riscv/opensbi/blob/master/docs/platform/qemu_virt.md
- Recompile OpenSBI with payload is Linux kernel.
```bash
make -C ${WORKING_DIR}/opensbi PLATFORM=generic \
  FW_PAYLOAD_PATH=${WORKING_DIR}/linux-5.11-rc3/arch/riscv/boot/Image
```
- Start qemu
  ```bash
  qemu-system-riscv64 -m 2G \
      -nograph
      ic \
      -machine virt \
      -smp 2 \
      -bios ${WORKING_DIR}/opensbi/build/platform/generic/firmware/fw_payload.elf
  ```
  - What you expect here is OpenSBI will boot and jump to Linux kernel but it will end with
    ```
    [    0.696120] ---[ end Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0) ]--
    ```
    That is because you do not have rootfs available.

- Start qemu with `disk.img`
  ```bash
  qemu-system-riscv64 -m 2G \
  -nographic \
  -machine virt \
  -smp 1 \
  -kernel  ${WORKING_DIR}/opensbi/build/platform/generic/firmware/fw_payload.elf \
    -drive file=${WORKING_DIR}/disk.img,format=raw,id=hd0 \
    -device virtio-blk-device,drive=hd0 \
    -append "root=/dev/vda2 rootwait console=ttyS0"
  ```
  - Now we have `rootfs` available at `/dev/vda2` in `${WORKING_DIR}/disk.img`. This image is create with 2 partition
    - boot: Linux Kernel.
    - rootfs: busybox.
    - `-append "root=/dev/vda2 rootwait console=ttyS0"`
      - `append`: is used to add boot command for kernel.
      - `root=/dev/vda2`: tell kernel look for rootfs in `/dev/vda2`.

- Start qemu with `rootfs.img`.
  - `rootfs.img`: contain only one partition for `busybox`.
  - Check section **Create disk.img to store your linux kernel**
  ```bash
  qemu-system-riscv64 -m 2G \
  -nographic \
  -machine virt \
  -smp 1 \
  -kernel  ${WORKING_DIR}/opensbi/build/platform/generic/firmware/fw_payload.elf \
    -drive file=${WORKING_DIR}/rootfs.img,format=raw,id=hd0 \
    -device virtio-blk-device,drive=hd0 \
    -append "root=/dev/vda1 rootwait console=ttyS0 rw"
  ``` 