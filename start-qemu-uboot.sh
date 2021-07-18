qemu-system-riscv64 -m 2G \
    -nographic \
    -machine virt \
    -smp 2 \
    -bios ${WORKING_DIR}/opensbi/build/platform/generic/firmware/fw_payload.elf
