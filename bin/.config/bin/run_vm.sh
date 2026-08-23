#!/bin/bash 

# VENUS
# qemu-system-x86_64 \
#     -enable-kvm \
#     -M q35 \
#     -cpu host,hv-passthrough \
#     -smp 6 \
#     -m 8G \
#     -drive file=/mnt/ssd/Vms/win11.qcow2 \
#     -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd \
#     -drive if=pflash,format=raw,file=/home/justin/.config/libvirt/qemu/nvram/arch_VARS.4m.fd  \
#     -usb \
#     -device usb-tablet \
#     -device virtio-vga-gl,hostmem=4G,blob=true,venus=true \
#     -object memory-backend-memfd,id=mem1,size=8G \
#     -machine memory-backend=mem1 \
#     -display gtk,gl=on,show-cursor=on


/usr/lib/virtiofsd --socket-path=/tmp/projects.sock --shared-dir=/mnt/windows_drive/Users/ibjal/Documents/C++Stuff &

qemu-system-x86_64 \
    -enable-kvm \
    -M q35 \
    -cpu host,hv-passthrough \
    -smp 6 \
    -m 8G \
    -drive file=/mnt/ssd/Vms/win11.qcow2 \
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd \
    -drive if=pflash,format=raw,file=/home/justin/.config/libvirt/qemu/nvram/arch_VARS.4m.fd  \
    -usb \
    -device usb-tablet \
    -device virtio-vga-gl \
    -object memory-backend-memfd,id=mem1,size=8G \
    -machine memory-backend=mem1 \
    -display gtk,gl=on,show-cursor=on \
    -chardev socket,id=char0,path=/tmp/projects.sock \
    -device vhost-user-fs-pci,chardev=char0,tag=projects
