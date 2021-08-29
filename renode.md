## Renode
### Some usefull commands
- To remove a machine
  ```
  mach rem "name"
  ```
  or
  ```
  emulation RemoveMachine "name"
  ```
- To create uart emulator over internet
  - https://github.com/renode/renode/issues/95
```
emulation CreateServerSocketTerminal 1234 "uart-con" false
# Connect uart emulator socket
connector Connect sysbus.uart0 uart-con
```

### Renode without GUI
- Start `renode` without GUI. When you start renode without GUI. There is no `monitor` windows appear to interact with `renode`, instead of it renode with open telnet server for you to connect. Now you can connect renode with default port `1234`.
  ```bash
  $ renode --disable-xwt
  14:25:22.8109 [INFO] Loaded monitor commands from: /workspace/riscv-embedded-linux/labs/embedded-linux-renode-labs/renode/renode/scripts/monitor.py
  14:25:22.8474 [INFO] Monitor available in telnet mode on port 1234
  # Start renode with specific port 1235
  $ renode --disable-xwt --port 1235
  14:26:41.0165 [INFO] Loaded monitor commands from: /workspace/riscv-embedded-linux/labs/embedded-linux-renode-labs/renode/renode/scripts/monitor.py
  14:26:41.0557 [INFO] Monitor available in telnet mode on port 1235
  ```
- Connect to `monitor` server
```
$ telnet localhost 1235
Trying ::1...
Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.
Renode, version 1.12.0.6325 (2a4b9b11-202108290330)

(monitor) 
```

- Connect to uart console. [GitHub Issue](https://github.com/renode/renode/issues/95). There are 2 type of terminal:
  - ServerSocketTerminal
    - Telnet terminal server 
  - UartPtyTerminal.
    - Psuedo terminal slave.
    - You can connect `pts` device with screen
  ```
  # emulation CreateServerSocketTerminal port "name" 
  emulation CreateServerSocketTerminal 1235 "uart-con"
  # emulation CreateUartPtyTerminal "name" @path/to/file
  emulation CreateUartPtyTerminal "uart-con" @path/to/file
  ```

- Connect virtual terminal to uart device
```
# create connector from Uart device to terminal device
connector Connect sysbus.uart0 uart-con
```

- Create network
```
(monitor) emulation CreateSwitch "switch1"
(machine-0) connector Connect sysbus.ethernet switch1
emulation CreateTap "tap0" "tap"
connector Connect host.tap switch1
```
## Renode
```bash
export PS1="${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u \[\033[00m\]\[\033[01;34m\]\W\[\033[00m\] \$ "
export WORKING_DIR=<RootDIR>/labs/embedded-linux-renode-labs
echo "export PATH=$WORKING_DIR/renode/renode:$PATH" >> ~/.bashrc
```
```
mkdir -p $WORKING_DIR
mkdir -p $WORKING_DIR/toolchain
mkdir -p $WORKING_DIR/bootloader
mkdir -p $WORKING_DIR/thirdparty
mkdir -p $WORKING_DIR/buildroot
touch $WORKING_DIR/toolchain/.gitkeep
touch $WORKING_DIR/bootloader/.gitkeep
touch $WORKING_DIR/thirdparty/.gitkeep
touch $WORKING_DIR/buildroot/.gitkeep
```

- Install `mono-complete`
  - https://www.mono-project.com/download/stable/#download-lin
```bash
sudo apt install gnupg ca-certificates
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
echo "deb https://download.mono-project.com/repo/ubuntu stable-focal main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list
sudo apt update
sudo apt install mono-devel mono-complete
```

```bash
wget https://dl.antmicro.com/projects/renode/builds/renode-latest.deb -P ${WORKING_DIR}/renode
sudo dpkg --install ${WORKING_DIR}/renode/renode-latest.deb
```

- [Build renode from source](https://renode.readthedocs.io/en/latest/advanced/building_from_sources.html)
```bash
git -C ${WORKING_DIR}/renode/ clone https://github.com/renode/renode.git
cd ${WORKING_DIR}/renode/renode
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
./bootstrap
./configure --enable-local
make
```
- Build `cortexa9` toolchain
```bash
./ct-ng list-samples
./ct-ng show-riscv64-unknown-linux-gnu
./ct-ng riscv64-unknown-linux-gnu
```
- Config built target
  - Set Tuple's vendor string (TARGET_VENDOR) to training.
  - Set Tuple's alias (TARGET_ALIAS) to riscv-linux.
  - C-library: GLIBC (CT_LIBC_GLIBC)
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

- Download prebuilt toolchain
```
wget -P $WORKING_DIR/toolchain/ https://toolchains.bootlin.com/downloads/releases/toolchains/riscv64/tarballs/riscv64--glibc--bleeding-edge-2020.08-1.tar.bz2 
tar xf $WORKING_DIR/toolchain/riscv64--glibc--bleeding-edge-2020.08-1.tar.bz2 -C $WORKING_DIR/toolchain/
```
## U-Booot
```bash
sudo apt-get install swig
```
- Download Uboot from [Github Release](https://github.com/u-boot/u-boot/releases)
```bash
wget https://github.com/u-boot/u-boot/archive/refs/tags/v2021.07.tar.gz -P ${WORKING_DIR}/bootloader
```
- Extract source code:
```bash
tar xf ${WORKING_DIR}/bootloader/v2021.07.tar.gz -C ${WORKING_DIR}/bootloader
```
- We will choose the configuration for QEMU and U-Boot running in S Mode:
```bash
make -C ${WORKING_DIR}/bootloader/u-boot-2021.07 sifive_unleashed_defconfig
```

- Config
  ```bash
  make -C ${WORKING_DIR}/bootloader/u-boot-2021.07 menuconfig
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
make -C ${WORKING_DIR}/bootloader/u-boot-2021.07 -j8
```
## OpenSBI
- Target build OpenSBI with payload is U-boot
- Clone OpenSBI
```bash
git -C ${WORKING_DIR}/bootloader clone https://github.com/riscv/opensbi.git
cd ${WORKING_DIR}/bootloader/opensbi
git checkout v0.9
cd -
```
- Check out document of OpenSBI of [Sifive FU540](https://github.com/riscv/opensbi/blob/v0.9/docs/platform/sifive_fu540.md)
- Build fw_payload.elf file
```bash
make -C ${WORKING_DIR}/bootloader/opensbi PLATFORM=sifive/fu540 FW_PAYLOAD_PATH=${WORKING_DIR}/bootloader/u-boot-2021.07/u-boot.bin
```



## Linux Kernel

- Clone source code.
```bash
mkdir $WORKING_DIR/kernel
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.5.8.tar.gz -P $WORKING_DIR/kernel
tar xf $WORKING_DIR/kernel/linux-5.5.8.tar.gz -C $WORKING_DIR/kernel
cp $WORKING_DIR/kernel/data/config $WORKING_DIR/kernel/linux-5.5.8/.config
```
make -C $WORKING_DIR/kernel/linux-5.5.8 vexpress_defconfig
- Load defconfig file of sifife fu540 under `arch/riscv/`
make -C $WORKING_DIR/kernel/linux-5.5.8 menuconfig
```
- Make menuconfig to enable kernel log timestamp
  - CONFIG_PRINTK_TIME
```
make -C $WORKING_DIR/kernel/linux-5.5.8 menuconfig
make -C $WORKING_DIR/kernel/linux-5.5.8 -j8
```

- Inside of Uboot console
```bash
booti 0x8200000 - 0x81000000
```
### Boot with tftp

## Tiny filesystem

## Filesystems - Block file systems

## Third party libraries and applications
```bash
git -C ${WORKING_DIR} clone https://github.com/buildroot/buildroot.git
make -C ${WORKING_DIR}/buildroot beaglev_defconfig
```

make -C ${WORKING_DIR}/buildroot menuconfig
  - Toolchain bootlin

make -C ${WORKING_DIR}/buildroot world
  
git -C ${WORKING_DIR} clone https://github.com/renode/renode.git
- Start gdb
  - https://renode.readthedocs.io/en/latest/debugging/gdb.html
  ```
  machine StartGdbServer 3333
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
make -C $WORKING_DIR/buildroot/buildroot-2021.05.1 hifive_unleashed_defconfig
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