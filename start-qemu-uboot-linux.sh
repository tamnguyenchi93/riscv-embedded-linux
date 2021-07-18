qemu-system-riscv64 -m 2G \
-nographic \
-machine virt \
-smp 1 \
-kernel  ${WORKING_DIR}/opensbi/build/platform/generic/firmware/fw_payload.elf \
	-drive file=${WORKING_DIR}/disk.img,format=raw,id=hd0 \
    -device virtio-blk-device,drive=hd0 \
	-append "root=/dev/vda2 rootwait console=ttyS0 rw"