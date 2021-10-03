# Embedded Linux with Renode Emulator
- This series contain multiple labs that I try to replicate [Embedded Linux Qemu](embedded-linux-qemu.md). If you haven't check it yet, please check it first to get use to the terms, step build.
- What is [Renode](renode.io)?
    ```
    Renode is an open source software development framework with commercial support from Antmicro that lets you develop, debug and test multi-node device systems reliably, scalably and effectively.
    ```
- That have some cools feature like emulation whole board include SOC, peripherals, sensor, external flash,... To compare with qemu, qemu focus more SOC only.
- To better understand How to work with Renode please visit [Renode Document](https://renode.readthedocs.io/en/latest/) page. They have some emulate hardware that can run Linux. Follow to installation guide and try it.
- I will use RISC-V instead of ARM for this series.



## Lab 1: Install Renode.
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
./build.sh
```

## Lab 2: Prepare RISC-V toolchain.
- There are some options you can choose:
  - Install from your OS distribute.
  - Download pre-built toolchain from other organizations: Bootlin, CodeSourcery,... Check out [Elinux Prebuilt Toolchains](https://elinux.org/Toolchains#Prebuilt_toolchains)
  - Build your own toolchain with: Crosstool-NG, buildroot... Check out [Elinux Prebuilt Toolchains](https://elinux.org/Toolchains#Toolchain_building_systems)
- Unless you install toolchain to your system, you will need to export your toolchain path to system path.


### Build RICV toolchain with Crosstool-NG
- Export WORKING_DIR varibale
  ```bash
  export WORKING_DIR=/path/to/labs/embedded-linux-renode-labs
  export WORKING_DIR=`pwd`/labs/embedded-linux-renode-labs
  ```
- Install Crosstool-NG build dependencies:
  ```bash
  sudo apt-get install -y autoconf bison build-essential flex gawk \
          gettext g++ help2man libncurses-dev libtool-bin \
          texinfo unzip
  ```

- Clone crosstool-ng source from github
  ```bash
  git -C $WORKING_DIR/toolchain clone https://github.com/crosstool-ng/crosstool-ng.git
  ```

- Build `ct-ng` tool:
  ```bash
  cd $WORKING_DIR/toolchain/crosstool-ng
  ./bootstrap
  # https://crosstool-ng.github.io/docs/install/#hackers-way
  ./configure --enable-local
  make
  ```

- crosstool-ng has alot of define config for different architecture.
  ```bash
  # Query samples list
  ./ct-ng list-samples
  # View info of riscv64-unknown-linux-gnu
  ./ct-ng show-riscv64-unknown-linux-gnu
  # Use riscv64-unknown-linux-gnu config
  ./ct-ng riscv64-unknown-linux-gnu
  ```

- Config built target
  - Set Tuple's vendor string (TARGET_VENDOR) to training.
  - Set Tuple's alias (TARGET_ALIAS) to riscv-linux.
  - C-library: GLIBC (CT_LIBC_GLIBC)
  - Enable `CC_LANG_CXX`
  - keep `DEBUG_STRACE` ortherwise disbale Debug facilities
  - Set `Local tarballs directory` to `${WORKING_DIR}/toolchain/crosstool-ng-src`.
  - set `Prefix directory` to `${WORKING_DIR}/toolchain/x-tools/${CT_HOST:+HOST-${CT_HOST}/}${CT_TARGET}`
  ```bash
  ./ct-ng menuconfig
  ```
- Build toolchain
  ```bash
  # Create local tarbal dir
  mkdir -p ${WORKING_DIR}/toolchain/crosstool-ng-src
  # This will take very long time
  CT_TARGET=$WORKING_DIR/toolchain/ ./ct-ng build
  ```

- After build done the binary is at: `$WORKING_DIR/toolchain/x-tools/`. Export toolchain binary to system path
  ```bash
  export PATH=$WORKING_DIR/toolchain/x-tools/riscv64-training-linux-gnu/bin:$PATH
  ```
- You can clean to save space (a lot of space)
  ```bash
  ./ct-ng clean
  ```

### Download toolchain from Bootlin
- Download prebuilt toolchain
  ```bash
  wget -P $WORKING_DIR/toolchain/ https://toolchains.bootlin.com/downloads/releases/toolchains/riscv64/tarballs/riscv64--glibc--bleeding-edge-2020.08-1.tar.bz2 
  tar xf $WORKING_DIR/toolchain/riscv64--glibc--bleeding-edge-2020.08-1.tar.bz2 -C $WORKING_DIR/toolchain/
  ```
- Export toolchain path to system path:
  ```bash
  export PATH=${WORKING_DIR}/toolchain/riscv64--glibc--bleeding-edge-2020.08-1/bin:$PATH
  ```

## Lab 3: Build U-boot
- Export enviroment variable
  ```bash
  export CROSS_COMPILE=riscv64-linux-
  export ARCH=riscv
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

- Config uboot. We don't have chang anything here at this state.
  ```bash
  make -C ${WORKING_DIR}/bootloader/u-boot-2021.07 menuconfig
  ```
 
- Compile U-Boot
  ```bash
  make -C ${WORKING_DIR}/bootloader/u-boot-2021.07 -j8
  ```
- After compile u-boot binary is at: `${WORKING_DIR}/bootloader/u-boot-2021.07/u-boot.bin`. We can not test uboot right now, we need another bootloader to load 
## Lab 4: Build OpenSBI
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
  make -C ${WORKING_DIR}/bootloader/opensbi PLATFORM=sifive/fu540 \
    FW_PAYLOAD_PATH=${WORKING_DIR}/bootloader/u-boot-2021.07/u-boot.bin
  ```

- Test with renode:
  - Start renode
  ```bash
  cd $WORKING_DIR
  renode 
  ```
  - Inside renode monitor console:
  ```
  s @renode_scripts/hifive_unleashed_uboot.resc
  ```
  ```bash
  Trying 127.0.0.1...
  Connected to localhost.
  Escape character is '^]'.

  OpenSBI v0.9
    ____                    _____ ____ _____
    / __ \                  / ____|  _ \_   _|
  | |  | |_ __   ___ _ __ | (___ | |_) || |
  | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
  | |__| | |_) |  __/ | | |____) | |_) || |_
    \____/| .__/ \___|_| |_|_____/|____/_____|
          | |
          |_|

  Platform Name             : SiFive Freedom U540
  Platform Features         : timer,mfdeleg
  Platform HART Count       : 4
  Firmware Base             : 0x80000000
  Firmware Size             : 108 KB
  Runtime SBI Version       : 0.2

  Domain0 Name              : root
  Domain0 Boot HART         : 4
  Domain0 HARTs             : 1*,2*,3*,4*
  Domain0 Region00          : 0x0000000080000000-0x000000008001ffff ()
  Domain0 Region01          : 0x0000000000000000-0xffffffffffffffff (R,W,X)
  Domain0 Next Address      : 0x0000000080200000
  Domain0 Next Arg1         : 0x0000000088000000
  Domain0 Next Mode         : S-mode
  Domain0 SysReset          : yes

  Boot HART ID              : 4
  Boot HART Domain          : root
  Boot HART ISA             : rv64imafdcs
  Boot HART Features        : scounteren,mcounteren,time
  Boot HART PMP Count       : 16
  Boot HART PMP Granularity : 4
  Boot HART PMP Address Bits: 54
  Boot HART MHPM Count      : 0
  Boot HART MHPM Count      : 0
  Boot HART MIDELEG         : 0x0000000000000222
  Boot HART MEDELEG         : 0x000000000000b109


  U-Boot 2021.07 (Oct 02 2021 - 15:42:23 +0000)

  CPU:   rv64imac
  Model: SiFive HiFive Unleashed A00
  DRAM:  8 GiB
  MMC:   spi@10050000:mmc@0: 0
  Loading Environment from SPIFlash... jedec_spi_nor flash@0: unrecognized JEDEC id bytes: 00, 00, 00
  *** Warning - spi_flash_probe_bus_cs() failed, using default environment

  In:    serial@10010000
  Out:   serial@10010000
  Err:   serial@10010000
  Board serial number should not be 0 !!
  Net:   sifive-reset reset: failed to get cltx_reset reset
  ```
## Lab 5: Start Linux kernel
- Clone source code.
  ```bash
  mkdir $WORKING_DIR/kernel
  wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.5.8.tar.gz -P $WORKING_DIR/kernel
  tar xf $WORKING_DIR/kernel/linux-5.5.8.tar.gz -C $WORKING_DIR/kernel
  cp $WORKING_DIR/kernel/data/config $WORKING_DIR/kernel/linux-5.5.8/.config
  ```

- Load defconfig file of sifife fu540 under `arch/riscv/`
  ```bash
  make -C $WORKING_DIR/kernel/linux-5.5.8 defconfig
  ```
- Make menuconfig
  - CONFIG_PRINTK_TIME
  - Enable ramdisk support:
    - https://linuxlink.timesys.com/docs/classic/configuring_the_kernel_to_support_ram_disks
    - Block devices, enable the RAM disk support option. This sets `CONFIG_BLK_DEV_RAM=y`
    - Config ramcount = 8 and ramsize = 
  ```
  make -C $WORKING_DIR/kernel/linux-5.5.8 menuconfig
  make -C $WORKING_DIR/kernel/linux-5.5.8 -j8
  ```

### Test with renode:
- Start renode
```bash
cd $WORKING_DIR
renode 
```
- Inside renode monitor console:
```
s @renode_scripts/hifive_unleashed_linux.resc
```
- Uboot concole. Stop auto boot and run command below
  ```
  booti 0x82000000 - 0x81000000
  ```
- You should expect the linux kernel start and print early log but final kernel fails to start because it can't find root fs.
```
[    6.765263] VFS: Cannot open root device "(null)" or unknown-block(0,0): error -6
[    6.765861] Please append a correct "root=" boot option; here are the available partitions:
[    6.766418] 0100            8192 ram0 
[    6.766432]  (driver?)
[    6.766982] 0101            8192 ram1 
[    6.766996]  (driver?)
[    6.767546] 0102            8192 ram2 
[    6.767560]  (driver?)
[    6.768030] 0103            8192 ram3 
[    6.768124]  (driver?)
[    6.768630] 0104            8192 ram4 
[    6.768630]  (driver?)
[    6.769238] 0105            8192 ram5 
[    6.769252]  (driver?)
[    6.769872] 0106            8192 ram6 
[    6.769887]  (driver?)
[    6.770436] 0107            8192 ram7 
[    6.770451]  (driver?)
[    6.770930] DEBUG_BLOCK_EXT_DEVT is enabled, you need to specify explicit textual name for "root=" boot option.
[    6.771570] Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0)
[    6.772125] CPU: 0 PID: 1 Comm: swapper/0 Not tainted 5.5.8 #1
[    6.772428] Call Trace:
[    6.772718] [<ffffffe00003d094>] walk_stackframe+0x0/0xaa
[    6.773041] [<ffffffe00003d35e>] show_stack+0x2a/0x34
[    6.773371] [<ffffffe00065018c>] dump_stack+0x6c/0x86
[    6.773697] [<ffffffe0000420b8>] panic+0xe6/0x258
[    6.774016] [<ffffffe000000fe0>] mount_block_root+0x178/0x1f2
[    6.774346] [<ffffffe00000128a>] mount_root+0x10e/0x124
[    6.774671] [<ffffffe0000013da>] prepare_namespace+0x13a/0x17e
[    6.775004] [<ffffffe000000c16>] kernel_init_freeable+0x152/0x16e
[    6.775340] [<ffffffe0006650b6>] kernel_init+0x12/0xf0
[    6.775672] [<ffffffe00003bcf8>] ret_from_exception+0x0/0xc
[    6.776024] ---[ end Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0) ]---
```