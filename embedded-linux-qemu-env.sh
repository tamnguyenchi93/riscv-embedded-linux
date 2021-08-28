export CROSS_COMPILE=arm-linux-
export PATH=${WORKING_DIR}/toolchain/x-tools/arm-training-linux-uclibcgnueabihf/bin:$PATH
export ARCH=arm
# Fix alsa: Could not initialize DAC
# Link https://gitmemory.com/issue/umanovskis/baremetal-arm/18/780552151
export QEMU_AUDIO_DRV=none