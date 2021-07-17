qemu-system-x86_64 \
    -nographic \
    -drive file=$HOME/qemu/ubuntu-18.04-server-cloudimg-amd64.img,format=qcow2 \
    -drive file=$HOME/qemu/user-data.img,format=raw \
    -nic user,hostfwd=tcp::22222-:22 \
    -m 1G