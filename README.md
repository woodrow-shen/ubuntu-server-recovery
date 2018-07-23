# The tool to create Ubuntu live server image with recovery function

## Prerequisites
```bash
sudo apt install -y golang-go bzr pxz dctrl-tools fuseiso
sudo apt install -y qemu-kvm libvirt-bin virtinst ovmf
```

## Generate image with recovery
``` bash
./tools/ubuntu-classic-recovery-image <ubuntu.iso>
```

## How to run recovery image with kvm+vnc
### Create a VM using virt-install as recovery installer
```bash
fallocate -l 16G ubuntu-18.04.img
cp outdir/ubuntu-server-bionic-<build-date>.img.xz .
unxz ubuntu-server-bionic-<build-date>.img.xz
sudo virt-install --connect qemu:///system --name intel-nuc \
		 --disk <topdir>/ubuntu-server-bionic-<build-date>.img,device=disk,bus=virtio \
		 --disk <topdir>/ubuntu-18.04.img,device=disk,bus=virtio \
		 --ram 1024 \
		 --boot uefi \
		 --network bridge:virbr0 \
		 --os-type=linux \
		 --graphics vnc,port=5900,listen=0.0.0.0 \
		 --noautoconsole
```

### Create a SSH tunnel for port forwarding from remote client
```bash
ssh -L 5900:localhost:5900 -N -f <username>@<host-ip>
```

### Use VNC clinet to connect VM
e.g. Use VNC viewer to connect 127.0.0.1:5900

### Create a VM for installing Ubuntu-server
```bash
sudo virsh -c qemu:///system shutdown intel-nuc
sudo virsh -c qemu:///system undefine --nvram intel-nuc
sudo virt-install --connect qemu:///system --name intel-nuc \
		 --disk ~/ubuntu-18.04.img,device=disk,bus=virtio \
		 --ram 1024 \
		 --boot uefi \
		 --network bridge:virbr0 \
		 --os-type=linux \
		 --graphics vnc,port=5900,listen=0.0.0.0 \
		 --noautoconsole
```

### Manager current VM
```bash
sudo virsh -c qemu:///system list
sudo virsh -c qemu:///system reboot intel-nuc
sudo virsh -c qemu:///system shutdown intel-nuc
sudo virsh -c qemu:///system undefine --nvram intel-nuc
```

# config for arm

## Prerequisites
- ubuntu-recovery-image: could be install from http://github.com/Lyoncore/ubuntu-recovery-image
- Branch for arm-config: arm


## Build image
``` bash
git clone https://github.com/Lyoncore/ubuntu-recovery.git
cd ubuntu-recovery/
go get launchpad.net/godeps
godeps -t -u dependencies.tsv
```

### For armhf (ex: pi3)

Build recovery.bin
``` bash
GOARCH=arm GOARM=7 CGO_ENABLED=1 CC=arm-linux-gnueabihf-gcc go run build.go build
```
Build base image
``` bash
./cook-image.sh
```

### For arm64
``` bash
GOARCH=arm64 CGO_ENABLED=1 CC=aarch64-linux-gnu-gcc go build -o local-includes/recovery/bin/recovery.bin ./src/
```

## Generate image with recovery
``` bash
<Path to>/ubuntu-recovery-image
```

## run tests
``` bash
cd src
go test -check.vv
```
