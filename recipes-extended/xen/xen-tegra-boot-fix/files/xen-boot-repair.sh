#!/bin/bash
# xen-boot-repair.sh - Fix Xen boot issues

echo "===== Xen Boot Repair Tool ====="
echo "Checking for DTB files..."

# Find all DTB files
echo "DTB files found:"
find /boot -name "*.dtb" -type f

# Check EFI configuration
echo -e "\nChecking EFI configuration:"
if [ -d /boot/efi/EFI/BOOT ]; then
    echo "EFI directory exists"
    ls -la /boot/efi/EFI/BOOT/
else
    echo "Creating EFI directory"
    mkdir -p /boot/efi/EFI/BOOT
fi

# Create directory structure
mkdir -p /boot/dtb

# Copy required files to EFI directory
echo -e "\nCopying necessary files to EFI directory:"
DTB_PATH=$(find /boot -name "tegra234-p3768-0000+p3767-0003.dtb" -type f | head -1)
if [ -n "$DTB_PATH" ]; then
    echo "Found DTB at $DTB_PATH"
    cp "$DTB_PATH" /boot/efi/EFI/BOOT/
    cp "$DTB_PATH" /boot/dtb/
    echo "DTB copied to EFI directory"
else
    echo "ERROR: DTB not found!"
fi

# Copy Xen and kernel to EFI directory
if [ -e /boot/xen ]; then
    echo "Found Xen at /boot/xen"
    cp /boot/xen /boot/efi/EFI/BOOT/xen.efi
    echo "Xen copied to EFI directory"
elif [ -e /usr/lib64/efi/xen.efi ]; then
    echo "Found Xen at /usr/lib64/efi/xen.efi"
    cp /usr/lib64/efi/xen.efi /boot/efi/EFI/BOOT/xen.efi
    echo "Xen copied to EFI directory"
else
    echo "ERROR: Xen hypervisor not found!"
fi

if [ -e /boot/Image ]; then
    echo "Found kernel at /boot/Image"
    cp /boot/Image /boot/efi/EFI/BOOT/
    echo "Kernel copied to EFI directory"
else
    echo "ERROR: Kernel not found!"
fi

# Create Xen configuration file
echo -e "\nCreating Xen configuration file:"
cat > /boot/efi/EFI/BOOT/xen.cfg << EOF
[global]
default=xen

[xen]
options=console=dtuart dtuart=serial8250,mmio,0x3100000 dom0_mem=2048M dom0_max_vcpus=4
kernel=Image root=/dev/nvme0n1p1 rw console=hvc0 earlyprintk=xen
device_tree=tegra234-p3768-0000+p3767-0003.dtb
EOF
echo "Xen configuration created"

# Setup EFI boot entry
echo -e "\nSetting up EFI boot entry:"
ROOT_PART=$(findmnt -n -o SOURCE / | sed 's/^\/dev\///')
BOOT_DEVICE=$(echo $ROOT_PART | sed 's/p*[0-9]$//')
BOOT_PART=$(echo $ROOT_PART | grep -o 'p*[0-9]$' | grep -o '[0-9]')

echo "Root partition: $ROOT_PART"
echo "Boot device: $BOOT_DEVICE"
echo "Boot partition: $BOOT_PART"

if [ -n "$BOOT_DEVICE" ] && [ -n "$BOOT_PART" ]; then
    if command -v efibootmgr >/dev/null 2>&1; then
        efibootmgr -v
        echo "Creating Xen boot entry..."
        # Remove existing Xen entries
        for entry in $(efibootmgr | grep "Xen" | awk '{print $1}' | sed 's/Boot//;s/\*//'); do
            if [ -n "$entry" ]; then
                efibootmgr -b $entry -B
            fi
        done
        
        # Add new Xen entry
        efibootmgr -c -d /dev/$BOOT_DEVICE -p $BOOT_PART -L "Xen Hypervisor" -l '\BOOT\xen.efi' \
        -u "dom0_mem=2048M console=dtuart dtuart=serial8250,mmio,0x3100000 dom0_max_vcpus=4 -- \BOOT\Image \
        root=/dev/$ROOT_PART rw console=hvc0 earlyprintk=xen device_tree=\BOOT\tegra234-p3768-0000+p3767-0003.dtb"
        
        # Make Xen the first boot option
        XEN_ENTRY=$(efibootmgr | grep "Xen Hypervisor" | awk '{print $1}' | sed 's/Boot//;s/\*//')
        if [ -n "$XEN_ENTRY" ]; then
            echo "Setting Xen as first boot option"
            efibootmgr -o $XEN_ENTRY
        fi
    else
        echo "WARNING: efibootmgr not available - EFI boot entry not created"
    fi
else
    echo "ERROR: Could not determine boot device and partition"
fi

echo -e "\nVerifying xl command availability:"
if command -v xl >/dev/null 2>&1; then
    echo "xl command is available"
    xl info || echo "xl info failed - Xen hypervisor not running"
else
    echo "WARNING: xl command not found"
    echo "Checking for Xen packages installation:"
    ls -la /usr/bin/xen* || echo "No Xen binaries found in /usr/bin"
    ls -la /usr/sbin/xen* || echo "No Xen binaries found in /usr/sbin"
    ls -la /usr/sbin/xl || echo "No xl command found in /usr/sbin"
fi

echo -e "\nXen boot repair completed!"

