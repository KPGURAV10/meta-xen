FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Add our custom extlinux.conf template
SRC_URI += "file://extlinux-xen.conf.template"

# Ensure xen.cfg is copied to boot partition
do_install:append() {
    # Add the Xen configuration file to EFI directory
    install -d ${D}/boot/efi/EFI/BOOT
    cat > ${D}/boot/efi/EFI/BOOT/xen.cfg << EOF
[global]
default=xen

[xen]
options=console=dtuart dtuart=serial8250,mmio,0x3100000 dom0_mem=2048M dom0_max_vcpus=4
kernel=Image root=/dev/nvme0n1p1 rw console=hvc0 earlyprintk=xen
ramdisk=initrd.img
device_tree=tegra234-p3768-0000+p3767-0003.dtb
EOF

    # Create a directory for DTB files if it doesn't exist
    install -d ${D}/boot/dtb
    
    # Find and copy the DTB to all required locations
    if [ -e ${STAGING_KERNEL_DIR}/arch/arm64/boot/dts/nvidia/tegra234-p3768-0000+p3767-0003.dtb ]; then
        install -m 0644 ${STAGING_KERNEL_DIR}/arch/arm64/boot/dts/nvidia/tegra234-p3768-0000+p3767-0003.dtb ${D}/boot/
        install -m 0644 ${STAGING_KERNEL_DIR}/arch/arm64/boot/dts/nvidia/tegra234-p3768-0000+p3767-0003.dtb ${D}/boot/dtb/
        install -m 0644 ${STAGING_KERNEL_DIR}/arch/arm64/boot/dts/nvidia/tegra234-p3768-0000+p3767-0003.dtb ${D}/boot/efi/EFI/BOOT/
    fi
}

# Add the config files to the package
FILES:${PN} += "/boot/efi/EFI/BOOT/xen.cfg \
                /boot/dtb/tegra234-p3768-0000+p3767-0003.dtb \
                /boot/tegra234-p3768-0000+p3767-0003.dtb \
                /boot/efi/EFI/BOOT/tegra234-p3768-0000+p3767-0003.dtb"

do_install:append() {
    # Install our custom extlinux template
    if [ -e ${WORKDIR}/extlinux-xen.conf.template ]; then
        install -m 0644 ${WORKDIR}/extlinux-xen.conf.template ${D}${datadir}/tegra-boot-tools/extlinux.conf.xen
    fi
    
    # Create a script to set up the EFI boot entries for Xen
    install -d ${D}${bindir}
    cat > ${D}${bindir}/setup-xen-efi-boot.sh << 'EOF'
#!/bin/sh
set -e

# Set up Xen EFI boot entry
if [ -d /boot/efi/EFI/BOOT ] && [ -e /boot/xen ]; then
    echo "Setting up Xen EFI boot entry..."
    
    # Copy Xen to EFI directory if not already there
    if [ ! -e /boot/efi/EFI/BOOT/xen.efi ]; then
        cp /boot/xen /boot/efi/EFI/BOOT/xen.efi
    fi
    
    # Copy kernel to EFI directory
    if [ -e /boot/Image ] && [ ! -e /boot/efi/EFI/BOOT/Image ]; then
        cp /boot/Image /boot/efi/EFI/BOOT/Image
    fi
    
    # Find and copy DTB to EFI directory if not already there
    if [ ! -e /boot/efi/EFI/BOOT/tegra234-p3768-0000+p3767-0003.dtb ]; then
        DTB_PATH=$(find /boot -name "tegra234-p3768-0000+p3767-0003.dtb" -type f | head -1)
        if [ -n "$DTB_PATH" ]; then
            cp "$DTB_PATH" /boot/efi/EFI/BOOT/tegra234-p3768-0000+p3767-0003.dtb
        else
            echo "WARNING: DTB file not found in /boot"
        fi
    fi
    
    # Get the actual root partition
    ROOT_PART=$(findmnt -n -o SOURCE / | sed 's/^\/dev\///')
    BOOT_DEVICE=$(echo $ROOT_PART | sed 's/p*[0-9]$//')
    BOOT_PART=$(echo $ROOT_PART | grep -o 'p*[0-9]$' | grep -o '[0-9]')

    # Using the detected values
    efibootmgr -c -d /dev/$BOOT_DEVICE -p $BOOT_PART -L "Xen Hypervisor" -l '\EFI\BOOT\xen.efi' \
    -u "dom0_mem=2048M console=dtuart dtuart=serial8250,mmio,0x3100000 dom0_max_vcpus=4 -- \EFI\BOOT\Image root=/dev/$ROOT_PART rw console=hvc0 earlyprintk=xen"
  
else
    echo "Xen hypervisor or EFI directory not found"
fi

# Ensure DTB is available in all required locations
DTB_PATH=$(find /boot -name "tegra234-p3768-0000+p3767-0003.dtb" -type f | head -1)
if [ -n "$DTB_PATH" ]; then
    mkdir -p /boot/dtb
    mkdir -p /boot/efi/EFI/BOOT
    cp "$DTB_PATH" /boot/
    cp "$DTB_PATH" /boot/dtb/
    cp "$DTB_PATH" /boot/efi/EFI/BOOT/
    echo "DTB file copied to all required locations"
else
    echo "ERROR: DTB file not found anywhere in /boot"
fi
EOF
    chmod +x ${D}${bindir}/setup-xen-efi-boot.sh
}

FILES:${PN} += "${bindir}/setup-xen-efi-boot.sh ${datadir}/tegra-boot-tools/extlinux.conf.xen"

