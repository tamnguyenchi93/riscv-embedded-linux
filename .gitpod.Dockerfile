FROM gitpod/workspace-full-vnc
USER gitpod

RUN mkdir $HOME/qemu

RUN wget https://cloud-images.ubuntu.com/releases/bionic/release/ubuntu-18.04-server-cloudimg-amd64.img \
        -P $HOME/qemu/

RUN sudo apt-get update
RUN sudo apt-get install -y qemu-system-misc \
                        cloud-image-utils \
                        qemu-system-x86-64

RUN echo "#cloud-config\npassword: ubuntu\nchpasswd: { expire: False }\nssh_pwauth: True" > $HOME/qemu/user-data.yaml

RUN cloud-localds $HOME/qemu/user-data.img $HOME/qemu/user-data.yaml