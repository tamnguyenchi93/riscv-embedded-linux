# Renode

- Install `mono-complete`
  - https://www.mono-project.com/download/stable/#download-lin
```bash
sudo apt install gnupg ca-certificates
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
echo "deb https://download.mono-project.com/repo/ubuntu stable-focal main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list
sudo apt update
sudo apt install mono-devel
```

-
```bash
wget https://github.com/renode/renode/releases/download/v1.12.0/renode_1.12.0_amd64.deb -P ${WORKING_DIR}
sudo dpkg --install ${WORKING_DIR}/renode_1.12.0_amd64.deb
```

```bash
git -C ${WORKING_DIR} clone https://github.com/buildroot/buildroot.git
make -C ${WORKING_DIR}/buildroot beaglev_defconfig
```

make -C ${WORKING_DIR}/buildroot menuconfig
  - Toolchain bootlin
  