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

rm -f /tmp/projects.sock

/usr/lib/virtiofsd \
  --socket-path=/tmp/projects.sock \
  --shared-dir=/mnt/ssd/projects/c++stuff/ \
  --sandbox none \
  --inode-file-handles=never \
  --cache=never &

sleep 1

qemu-system-x86_64 \
    -enable-kvm \
    -machine q35,memory-backend=mem1 \
    -cpu host,migratable=no,hv-passthrough,host-cache-info=on,l3-cache=on,+kvm-pv-eoi,+kvm-pv-unhalt \
    -smp 6,sockets=1,cores=6,threads=1 \
    -m 8G \
    -object memory-backend-memfd,id=mem1,size=8G,share=on \
    -drive file=/mnt/ssd/Vms/win11.qcow2,if=virtio,format=qcow2 \
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd \
    -drive if=pflash,format=raw,file=/home/justin/.config/libvirt/qemu/nvram/arch_VARS.4m.fd \
    -usb \
    -device usb-tablet \
    -device virtio-vga-gl \
    -display gtk,gl=on,show-cursor=on,clipboard=on \
    -device virtio-serial-pci \
    -chardev qemu-vdagent,id=vdagent,name=vdagent,clipboard=on,mouse=off \
    -device virtserialport,chardev=vdagent,name=com.redhat.spice.0 \
    -chardev socket,id=char0,path=/tmp/projects.sock \
    -device vhost-user-fs-pci,chardev=char0,tag=projects


# <domain type="kvm">
#   <name>win11</name>
#   <uuid>5d34c802-2924-42b4-b6b7-93ee4bee8ac2</uuid>
#   <metadata>
#     <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
#       <libosinfo:os id="http://microsoft.com/win/11"/>
#     </libosinfo:libosinfo>
#   </metadata>
#   <memory unit="KiB">8388608</memory>
#   <currentMemory unit="KiB">8388608</currentMemory>
#   <vcpu placement="static">6</vcpu>
#   <os firmware="efi">
#     <type arch="x86_64" machine="pc-q35-11.0">hvm</type>
#     <firmware>
#       <feature enabled="no" name="enrolled-keys"/>
#       <feature enabled="yes" name="secure-boot"/>
#     </firmware>
#     <loader readonly="yes" secure="yes" type="pflash" format="raw">/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd</loader>
#     <nvram template="/usr/share/edk2/x64/OVMF_VARS.4m.fd" templateFormat="raw" format="raw">/var/lib/libvirt/qemu/nvram/win11_VARS.fd</nvram>
#     <boot dev="hd"/>
#   </os>
#   <features>
#     <acpi/>
#     <apic/>
#     <hyperv mode="custom">
#       <relaxed state="on"/>
#       <vapic state="on"/>
#       <spinlocks state="on" retries="8191"/>
#       <vpindex state="on"/>
#       <runtime state="on"/>
#       <synic state="on"/>
#       <stimer state="on"/>
#       <frequencies state="on"/>
#       <tlbflush state="on"/>
#       <ipi state="on"/>
#       <avic state="on"/>
#     </hyperv>
#     <vmport state="off"/>
#     <smm state="on"/>
#   </features>
#   <cpu mode="host-passthrough" check="none" migratable="on">
#     <topology sockets="1" dies="1" clusters="1" cores="6" threads="1"/>
#   </cpu>
#   <clock offset="localtime">
#     <timer name="rtc" tickpolicy="catchup"/>
#     <timer name="pit" tickpolicy="delay"/>
#     <timer name="hpet" present="no"/>
#     <timer name="hypervclock" present="yes"/>
#   </clock>
#   <on_poweroff>destroy</on_poweroff>
#   <on_reboot>restart</on_reboot>
#   <on_crash>destroy</on_crash>
#   <pm>
#     <suspend-to-mem enabled="no"/>
#     <suspend-to-disk enabled="no"/>
#   </pm>
#   <devices>
#     <emulator>/usr/bin/qemu-system-x86_64</emulator>
#     <disk type="file" device="disk">
#       <driver name="qemu" type="qcow2"/>
#       <source file="/mnt/ssd/Vms/win11.qcow2"/>
#       <target dev="sda" bus="virtio"/>
#       <address type="pci" domain="0x0000" bus="0x05" slot="0x00" function="0x0"/>
#     </disk>
#     <disk type="file" device="cdrom">
#       <driver name="qemu" type="raw"/>
#       <target dev="sdb" bus="sata"/>
#       <readonly/>
#       <address type="drive" controller="0" bus="0" target="0" unit="1"/>
#     </disk>
#     <controller type="usb" index="0" model="qemu-xhci" ports="15">
#       <address type="pci" domain="0x0000" bus="0x02" slot="0x00" function="0x0"/>
#     </controller>
#     <controller type="pci" index="0" model="pcie-root"/>
#     <controller type="pci" index="1" model="pcie-root-port">
#       <model name="pcie-root-port"/>
#       <target chassis="1" port="0x10"/>
#       <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x0" multifunction="on"/>
#     </controller>
#     <controller type="pci" index="2" model="pcie-root-port">
#       <model name="pcie-root-port"/>
#       <target chassis="2" port="0x11"/>
#       <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x1"/>
#     </controller>
#     <controller type="pci" index="3" model="pcie-root-port">
#       <model name="pcie-root-port"/>
#       <target chassis="3" port="0x12"/>
#       <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x2"/>
#     </controller>
#     <controller type="pci" index="4" model="pcie-root-port">
#       <model name="pcie-root-port"/>
#       <target chassis="4" port="0x13"/>
#       <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x3"/>
#     </controller>
#     <controller type="pci" index="5" model="pcie-root-port">
#       <model name="pcie-root-port"/>
#       <target chassis="5" port="0x14"/>
#       <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x4"/>
#     </controller>
#     <controller type="pci" index="6" model="pcie-root-port">
#       <model name="pcie-root-port"/>
#       <target chassis="6" port="0x15"/>
#       <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x5"/>
#     </controller>
#     <controller type="pci" index="7" model="pcie-root-port">
#       <model name="pcie-root-port"/>
#       <target chassis="7" port="0x16"/>
#       <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x6"/>
#     </controller>
#     <controller type="pci" index="8" model="pcie-root-port">
#       <model name="pcie-root-port"/>
#       <target chassis="8" port="0x17"/>
#       <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x7"/>
#     </controller>
#     <controller type="pci" index="9" model="pcie-root-port">
#       <model name="pcie-root-port"/>
#       <target chassis="9" port="0x18"/>
#       <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x0" multifunction="on"/>
#     </controller>
#     <controller type="pci" index="10" model="pcie-root-port">
#       <model name="pcie-root-port"/>
#       <target chassis="10" port="0x19"/>
#       <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x1"/>
#     </controller>
#     <controller type="pci" index="11" model="pcie-root-port">
#       <model name="pcie-root-port"/>
#       <target chassis="11" port="0x1a"/>
#       <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x2"/>
#     </controller>
#     <controller type="pci" index="12" model="pcie-root-port">
#       <model name="pcie-root-port"/>
#       <target chassis="12" port="0x1b"/>
#       <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x3"/>
#     </controller>
#     <controller type="pci" index="13" model="pcie-root-port">
#       <model name="pcie-root-port"/>
#       <target chassis="13" port="0x1c"/>
#       <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x4"/>
#     </controller>
#     <controller type="pci" index="14" model="pcie-root-port">
#       <model name="pcie-root-port"/>
#       <target chassis="14" port="0x1d"/>
#       <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x5"/>
#     </controller>
#     <controller type="sata" index="0">
#       <address type="pci" domain="0x0000" bus="0x00" slot="0x1f" function="0x2"/>
#     </controller>
#     <controller type="virtio-serial" index="0">
#       <address type="pci" domain="0x0000" bus="0x03" slot="0x00" function="0x0"/>
#     </controller>
#     <interface type="network">
#       <mac address="52:54:00:53:0e:d8"/>
#       <source network="default"/>
#       <model type="e1000e"/>
#       <address type="pci" domain="0x0000" bus="0x01" slot="0x00" function="0x0"/>
#     </interface>
#     <serial type="pty">
#       <target type="isa-serial" port="0">
#         <model name="isa-serial"/>
#       </target>
#     </serial>
#     <console type="pty">
#       <target type="serial" port="0"/>
#     </console>
#     <channel type="spicevmc">
#       <target type="virtio" name="com.redhat.spice.0"/>
#       <address type="virtio-serial" controller="0" bus="0" port="1"/>
#     </channel>
#     <input type="tablet" bus="usb">
#       <address type="usb" bus="0" port="1"/>
#     </input>
#     <input type="mouse" bus="ps2"/>
#     <input type="keyboard" bus="ps2"/>
#     <tpm model="tpm-crb">
#       <backend type="emulator" version="2.0"/>
#     </tpm>
#     <graphics type="spice">
#       <listen type="none"/>
#       <image compression="off"/>
#       <gl enable="yes" rendernode="/dev/dri/by-path/pci-0000:09:00.0-render"/>
#     </graphics>
#     <sound model="ich9">
#       <address type="pci" domain="0x0000" bus="0x00" slot="0x1b" function="0x0"/>
#     </sound>
#     <audio id="1" type="spice"/>
#     <video>
#       <model type="virtio" heads="1" primary="yes" device="virtio-vga">
#         <acceleration accel3d="no"/>
#       </model>
#       <address type="pci" domain="0x0000" bus="0x00" slot="0x01" function="0x0"/>
#     </video>
#     <redirdev bus="usb" type="spicevmc">
#       <address type="usb" bus="0" port="2"/>
#     </redirdev>
#     <redirdev bus="usb" type="spicevmc">
#       <address type="usb" bus="0" port="3"/>
#     </redirdev>
#     <watchdog model="itco" action="reset"/>
#     <memballoon model="virtio">
#       <address type="pci" domain="0x0000" bus="0x04" slot="0x00" function="0x0"/>
#     </memballoon>
#   </devices>
# </domain>
