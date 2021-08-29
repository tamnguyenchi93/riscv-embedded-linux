export CROSS_COMPILE=riscv64-linux-
export PATH=${WORKING_DIR}/toolchain/riscv64--glibc--bleeding-edge-2020.08-1/bin:$PATH
export ARCH=riscv
# Fix alsa: Could not initialize DAC
# Link https://gitmemory.com/issue/umanovskis/baremetal-arm/18/780552151