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

## Lab 5: Start Linux kernel