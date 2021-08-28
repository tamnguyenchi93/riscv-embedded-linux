export CROSS_COMPILE=arm-linux-gnueabi-
# export PATH=${WORKING_DIR}/toolchain/gcc-arm-none-eabi-10.3-2021.07/bin:$PATH
export ARCH=arm
# Fix alsa: Could not initialize DAC
# Link https://gitmemory.com/issue/umanovskis/baremetal-arm/18/780552151
export QEMU_AUDIO_DRV=none