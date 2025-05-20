#!/bin/sh
# Post-installation script for Xen on Tegra setup
set -e

echo "=== Running Xen post-installation setup ==="

# Set up network bridge for Xen
if [ ! -f /etc/systemd/network/50-xenbr0.netdev ]; then
    echo "Setting up Xen network bridge..."
    
    # Create bridge device
    cat > /etc/systemd/network/50-xenbr0.netdev << EOF
[NetDev]
Name=xenbr0
Kind=bridge
EOF
    
    # Configure bridge
    cat > /etc/systemd/network/50-xenbr0.network << EOF
[Match]
Name=xenbr0

[Network]
DHCP=yes
EOF
    
    # Configure primary ethernet to attach to bridge
    PRIMARY_ETH=$(ip -o link show | grep -E "^[0-9]+: e" | head -1 | awk -F': ' '{print $2}' | cut -d '@' -f1)
    if [ -n "$PRIMARY_ETH" ]; then
        cat > /etc/systemd/network/51-xen-bridge-${PRIMARY_ETH}.network << EOF
[Match]
Name=${PRIMARY_ETH}

[Network]
Bridge=xenbr0
EOF
    fi
    
    # Restart networking
    systemctl restart systemd-networkd
fi

# Ensure Xen starts at boot
if [ -x /usr/sbin/update-rc.d ]; then
    update-rc.d xencommons defaults
    update-rc.d xendomains defaults
elif [ -x /bin/systemctl ]; then
    systemctl enable xen-qemu-dom0-disk-backend.service
    systemctl enable xencommons.service
    systemctl enable xendomains.service
fi

# Set up extlinux.conf if it exists
if [ -f /boot/extlinux/extlinux.conf ]; then
    # Check if Xen entry already exists
    if ! grep -q "LABEL Xen" /boot/extlinux/extlinux.conf; then
        echo "Adding Xen boot entry to extlinux.conf..."
        # Back up original file
        cp /boot/extlinux/extlinux.conf /boot/extlinux/extlinux.conf.backup
        
        # Add Xen entry at the top
        cat > /boot/extlinux/extlinux.conf.new << EOF
MENU TITLE L4T boot options
TIMEOUT 30
DEFAULT Xen Hypervisor

LABEL xen
    MENU LABEL Xen Hypervisor
    LINUX /boot/xen
    APPEND dom0_mem=1024M console=dtuart dtuart=serial8250,mmio,0x3100000 dom0_max_vcpus=4
    FDT /boot/tegra234-p3768-0000+p3767-0003.dtb
    XENPARAM /boot/Image
    XEN_INITRD /boot/initrd
    XINIT root=/dev/nvme0n1p1 rw rootwait console=hvc0 earlyprintk=xen loglevel=15
    
LABEL primary
    MENU LABEL primary kernel
    LINUX /boot/Image
    FDT /boot/tegra234-p3768-0000+p3767-0003.dtb
    INITRD /boot/initrd
    APPEND ${cbootargs} mminit_loglevel=4 console=tty0 console=ttyTCU0,115200 firmware_class.path=/etc/firmware fbcon=map:0 nospectre_bhb root=/dev/nvme0n1p1 rw rootwait

EOF
        # Append original content
        grep -v "TIMEOUT" /boot/extlinux/extlinux.conf | grep -v "DEFAULT" >> /boot/extlinux/extlinux.conf.new
        
        # Replace original file
        mv /boot/extlinux/extlinux.conf.new /boot/extlinux/extlinux.conf
    fi
fi

# Set up EFI boot for Xen if system supports it
if [ -d /boot/efi ] && [ -e /boot/xen ] && command -v efibootmgr >/dev/null 2>&1; then
    echo "Setting up EFI boot for Xen..."
    
    # Run the provided script for setting up EFI boot
    if [ -x /usr/bin/setup-xen-efi-boot.sh ]; then
        /usr/bin/setup-xen-efi-boot.sh
    fi
fi

# Create test VM config
if [ ! -f /etc/xen/ubuntu-vm.cfg ]; then
    echo "Creating example VM configuration..."
    cat > /etc/xen/ubuntu-vm.cfg << EOF
# Example Ubuntu VM configuration for Jetson
name = "ubuntu-vm"
memory = 1024
vcpus = 2
disk = [ 'file:/var/lib/xen/images/ubuntu.img,xvda,w' ]
vif = [ 'bridge=xenbr0' ]
kernel = "/var/lib/xen/images/vmlinuz"
ramdisk = "/var/lib/xen/images/initrd.img"
extra = "root=/dev/xvda1 console=hvc0"
EOF
    
    # Create VM images directory
    mkdir -p /var/lib/xen/images
fi

echo "=== Xen post-installation setup complete ==="

exit 0
