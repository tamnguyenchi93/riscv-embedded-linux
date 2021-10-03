export CROSS_COMPILE=riscv-linux-
export PATH=${WORKING_DIR}/toolchain/x-tools/riscv64-training-linux-gnu/bin:$PATH
export ARCH=riscv
# Fix alsa: Could not initialize DAC
# Link https://gitmemory.com/issue/umanovskis/baremetal-arm/18/780552151