FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI += "file://xen-full.cfg"

# Make sure the kernel has the right configuration for Xen
do_configure:append() {
    # Verify Xen configurations were applied
    cat ${B}/.config | grep -E "CONFIG_XEN=|CONFIG_XEN_DOM0=" > /dev/null || (echo "ERROR: Xen kernel configs missing"; exit 1)
}

# Ensure device tree has Xen compatibility
do_compile:append() {
    if [ -e ${B}/arch/${ARCH}/boot/dts/nvidia/tegra234-p3768-0000+p3767-0003.dts ]; then
        # Add Xen compatibility string to device tree if not already present
        grep "xen,xen" ${B}/arch/${ARCH}/boot/dts/nvidia/tegra234-p3768-0000+p3767-0003.dts || \
        sed -i '/compatible =/ s/compatible = "nvidia,tegra234"/compatible = "nvidia,tegra234", "xen,xen"/' \
            ${B}/arch/${ARCH}/boot/dts/nvidia/tegra234-p3768-0000+p3767-0003.dts
        # Recompile device tree with Xen compatibility
        make -C ${B} dtbs
    fi
}

# Install Xen-compatible DTB
do_install:append() {
    # Create a backup of the original DTB
    if [ -e ${D}/boot/tegra234-p3768-0000+p3767-0003.dtb ]; then
        cp ${D}/boot/tegra234-p3768-0000+p3767-0003.dtb ${D}/boot/tegra234-p3768-0000+p3767-0003.dtb.orig
        
        # Ensure the modified DTB is properly installed
        if [ -e ${B}/arch/${ARCH}/boot/dts/nvidia/tegra234-p3768-0000+p3767-0003.dtb ]; then
            cp ${B}/arch/${ARCH}/boot/dts/nvidia/tegra234-p3768-0000+p3767-0003.dtb ${D}/boot/tegra234-p3768-0000+p3767-0003.dtb
        fi
    else
        # If DTB not in /boot, create the directory and install it
        #install -d ${D}/boot
        if [ -e ${B}/arch/${ARCH}/boot/dts/nvidia/tegra234-p3768-0000+p3767-0003.dtb ]; then
            cp ${B}/arch/${ARCH}/boot/dts/nvidia/tegra234-p3768-0000+p3767-0003.dtb ${D}/boot/tegra234-p3768-0000+p3767-0003.dtb
        fi
    fi
    
    # Also install to /boot/dtb and EFI directories
    #install -d ${D}/boot/dtb
    #install -d ${D}/boot/efi/EFI/BOOT
    if [ -e ${B}/arch/${ARCH}/boot/dts/nvidia/tegra234-p3768-0000+p3767-0003.dtb ]; then
        cp ${B}/arch/${ARCH}/boot/dts/nvidia/tegra234-p3768-0000+p3767-0003.dtb ${D}/boot/dtb/tegra234-p3768-0000+p3767-0003.dtb
        cp ${B}/arch/${ARCH}/boot/dts/nvidia/tegra234-p3768-0000+p3767-0003.dtb ${D}/boot/efi/EFI/BOOT/tegra234-p3768-0000+p3767-0003.dtb
    fi
  
}

# Fix QA issues
INSANE_SKIP:${PN} += "already-stripped"

# Explicit FILES declaration with all files and directories
FILES:${PN} += "/boot/tegra234-p3768-0000+p3767-0003.dtb \
                /boot/tegra234-p3768-0000+p3767-0003.dtb.orig \
                /boot/dtb/tegra234-p3768-0000+p3767-0003.dtb \
                /boot/efi/EFI/BOOT/tegra234-p3768-0000+p3767-0003.dtb \
                /boot/dtb \
                /boot/efi \
                /boot/efi/EFI \
                /boot/efi/EFI/BOOT"
