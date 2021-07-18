# Riscv Embedded Linux

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/tamnguyenchi93/riscv-embedded-linux)

This repo is to setup is my a walkthough of **Embedded Linux from Scratch in 45 minutes, on RISC-V** 
  - [Embedded Linux from Scratch in 45 minutes, on RISC-V-Youtube](https://www.youtube.com/watch?v=cIkTh3Xp3dA&ab_channel=Bootlin)
  - [Embedded Linux from Scratch in 45 minutes, on RISC-V-Slide](https://bootlin.com/pub/conferences/2021/fosdem/opdenacker-embedded-linux-45minutes-riscv/opdenacker-embedded-linux-45minutes-riscv.pdf)

I setup an evironment for the lab with [GitPod](https://www.gitpod.io/). It has some limit because GitPod is container base, you don't have all permission as in your pc or VM.
  - Later in the lab you will have to create a raw `disk.img` for qemu to store your linux kernel image.

My workaround is running a Ubuntu VM with `qemu-system-x86_64` in GitPod that allows me to create `disk.img`. You don't have you build your own Ubuntu image from ISO file. I download prebuilt image from [cloud-images.ubuntu](cloud-images.ubuntu.com). 
  - `qemu-system-x86_64` and Ubuntu image setup with [gitpod custom docker image](https://www.gitpod.io/docs/config-docker).
  - Ubuntu VM:
    - Username: ubuntu
    - Password: ubuntu
    - Forward: ssh port (22) to 22222 localhost.
  - Workflow with Ubuntu VM:
    1. Start qemu with [start-qemu-x86_64.sh](start-qemu-x86_64.sh)
    2. Copy your file from GitPod env to VM with `scp`.
       - `scp -P 22222 <your-file> ubuntu@locahost:<path>`
    3. ssh to ubuntu VM and do what you have to do with your data.
       - `ssh -p 22222 ubuntu@locahost`
    4. Copy your output from VM to GitPod env.
       - `scp -P 22222 <your-file> ubuntu@locahost:<output> <path>`

I recommend you go through the lab to understand how it works. 

I also play around with opensbi:
 - The lab is focus on: OpenSBI -> U-Boot -> Linux -> Userspace
 - But OpenSBI allows to jump from OpenSBI to Linux. Please check [OpenSBI-Execution on QEMU RISC-V 64-bit](https://github.com/riscv/opensbi/blob/master/docs/platform/qemu_virt.md#execution-on-qemu-risc-v-64-bit).

 [My workthrough](walkthrough.md)
