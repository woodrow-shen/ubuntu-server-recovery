# The tool to create Ubuntu live server image with recovery function
A tool can convert Ubuntu live server ISO to disk image with recovery, and you can choose "factory restore" mode to back to being initial when system seems abnormal to you. Then the recovery function will give you prompt to confirm if you really want to do this (Data will be lost later!), otherwise you will enter system again due to timeout. In my case, I used intel-nuc for experimental purposes and it didn't plug any monitor/KB/mouse etc. What I'd like to do is that making recovery smooth without user prompt, so I preserve a option to disable prompt to get my mind. Enjoy it!

## Support arches
+ amd64 (verified HW: intel-nuc)
+ arm64 (not tested yet, should be ok if go src compiled on native/cross)

## Prerequisites
```bash
sudo apt install -y golang-go bzr pxz dctrl-tools fuseiso kpartx
```

## Generate image with recovery
``` bash
./tools/ubuntu-classic-recovery-image <ubuntu.iso>
```
Here the ISO I used can be gotten from [ubuntu-18.04.1-live-server-amd64.iso](http://releases.ubuntu.com/18.04/ubuntu-18.04.1-live-server-amd64.iso), so the above can be issued by

```bash
./tools/ubuntu-classic-recovery-image ubuntu-18.04.1-live-server-amd64.iso
```

## How to flash recovery image to intel-nuc
### dd image to USB stick
Do the commands by any linux distro, here is for Ubuntu environment
```bash
xzcat ubuntu-server-bionic-<build-date>.img.xz | sudo dd of=/dev/sd* bs=32M;sync
partprobe
```

### Plug USB stick to intel-nuc and power on it
+ phase 1: copy recovery partition to storage(sata/nvme) in intel-nuc, poweroff once it's done. remove USB stick.
+ phase 2: Ubuntu installer goes well.
+ phase 3: Ubuntu server ready.

## How to run recovery with intel-nuc
+ power on
+ press "esc" and enter grub menu
+ choose "factory restore"
+ type "yes" for user prompt
+ wait for installation complete

## How to run recovery image with kvm+vnc
### Install libvirt packages
```bash
sudo apt install -y qemu-kvm libvirt-bin virtinst ovmf
```

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

## Run go tests
``` bash
cd src
go test -check.vv
```

# Create Ubuntu core with recovery function
TBC

# Reporting bugs
If you have found an issue with this tool, please file a bug on github.
