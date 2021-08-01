# BeagleV
## Memory Map
0. 0x1800_0000 - 0x1801_FFFF, intRAM0
1. 0x1808_0000 - 0x1809_FFFF, intRAM1
2. 0x1840_0000 - 0x1840_7FFF, ROM
## WSL workaround

- Symlink linux workspace into C folder.

## 
```bash
git -C ${WORKING_DIR} clone https://github.com/buildroot/buildroot.git
make -C ${WORKING_DIR}/buildroot beaglev_defconfig
```

make -C ${WORKING_DIR}/buildroot menuconfig
  - Toolchain bootlin

git -C ${WORKING_DIR} clone https://github.com/renode/renode.git

