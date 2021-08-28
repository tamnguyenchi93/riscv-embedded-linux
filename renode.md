# Renode
- Kill machine
##
```bash
export WORKING_DIR=<RootDIR>/labs/embedded-linux-renode-labs
```
- Install `mono-complete`
  - https://www.mono-project.com/download/stable/#download-lin
```bash
sudo apt install gnupg ca-certificates
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
echo "deb https://download.mono-project.com/repo/ubuntu stable-focal main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list
sudo apt update
sudo apt install mono-devel mono-complete
```

```bash
wget https://dl.antmicro.com/projects/renode/builds/renode-latest.deb -P ${WORKING_DIR}
sudo dpkg --install ${WORKING_DIR}/renode-latest.deb
```

```bash
git -C ${WORKING_DIR} clone https://github.com/buildroot/buildroot.git
make -C ${WORKING_DIR}/buildroot beaglev_defconfig
```

make -C ${WORKING_DIR}/buildroot menuconfig
  - Toolchain bootlin

make -C ${WORKING_DIR}/buildroot world
  
git -C ${WORKING_DIR} clone https://github.com/renode/renode.git
- Start gdb
  - https://renode.readthedocs.io/en/latest/debugging/gdb.html
  ```
  machine StartGdbServer 3333
  ```
