FROM gitpod/workspace-full-vnc
USER gitpod

RUN mkdir $HOME/qemu

RUN wget https://cloud-images.ubuntu.com/releases/bionic/release/ubuntu-18.04-server-cloudimg-amd64.img \
        -P $HOME/qemu/

RUN sudo apt-get update
RUN sudo apt-get install -y qemu-system-misc \
                        cloud-image-utils \
                        qemu-system-x86-64 \
                        cpio rsync flex \
                        gnupg ca-certificates
# Setup latest version of renode from github
# RUN sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
#         echo "deb https://download.mono-project.com/repo/ubuntu stable-focal main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list && \
#         sudo apt update && \
#         sudo apt install -y mono-complete \
#         policykit-1 libgtk2.0-0 screen uml-utilities gtk-sharp2 libc6-dev gcc python3 python3-pip && \
#         sudo apt-get install -y ruby ruby-dev rpm 'bsdtar|libarchive-tools' \
#         sudo gem install fpm -v 1.4.0

# Download prebuilt image from antmicro data
RUN wget https://dl.antmicro.com/projects/renode/builds/renode-latest.deb -P /tmp && \
        sudo dpkg -i /tmp/renode-latest.deb && \
        rm /tmp/renode-latest.deb

RUN echo "#cloud-config\npassword: ubuntu\nchpasswd: { expire: False }\nssh_pwauth: True" > $HOME/qemu/user-data.yaml

RUN cloud-localds $HOME/qemu/user-data.img $HOME/qemu/user-data.yaml
