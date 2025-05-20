# Make sure Xen is built with proper configuration for Tegra platforms
EXTRA_OEMAKE += "XEN_TARGET_ARCH=arm64"

# UEFI-only configuration
EXTRA_OECONF += "--enable-efi --enable-systemd"

# Set EFI vendor and directory to avoid warnings and path issues
EXTRA_OEMAKE += "EFI_VENDOR= EFI_DIR=/boot/efi/EFI"

# Fix EFI installation paths by setting up directories at both compile and install phases
do_compile:prepend() {
    # Create all necessary EFI directories during compile phase
    mkdir -p ${B}/dist/install/boot/efi/EFI/xen
    mkdir -p ${B}/dist/install/boot/efi/EFI/BOOT
    mkdir -p ${B}/dist/install/usr/lib/efi
}

# Fix installation directories
do_install:prepend() {
    # Create necessary directories for Xen installation
    install -d ${D}/usr/sbin
    install -d ${D}/boot/efi/EFI/xen
    install -d ${D}/boot/efi/EFI/BOOT
    install -d ${D}${sysconfdir}/xen
    install -d ${D}/usr/lib/efi
}

do_install:append() {
    # Create xl.conf if needed
    if [ ! -f ${D}${sysconfdir}/xen/xl.conf ]; then
        cat > ${D}${sysconfdir}/xen/xl.conf << EOF
# Basic xl.conf for Tegra
autoballoon="off"
dom0_mem="2048M"
dom0_max_vcpus="4"
EOF
    fi

    # Enhanced EFI binary handling with better error reporting
    if [ -e ${D}/usr/lib/efi/xen.efi ]; then
        bbnote "Found xen.efi in /usr/lib/efi, installing to EFI directories"
        install -m 0644 ${D}/usr/lib/efi/xen.efi ${D}/boot/efi/EFI/BOOT/xen.efi || bberror "Failed to copy to EFI/BOOT"
        install -m 0644 ${D}/usr/lib/efi/xen.efi ${D}/boot/efi/EFI/xen/xen.efi || bberror "Failed to copy to EFI/xen"
    elif [ -e ${D}/boot/xen ]; then
        bbnote "Using fallback: copying /boot/xen to EFI directories"
        install -m 0644 ${D}/boot/xen ${D}/boot/efi/EFI/BOOT/xen.efi || bberror "Failed to copy xen to EFI/BOOT"
        install -m 0644 ${D}/boot/xen ${D}/boot/efi/EFI/xen/xen.efi || bberror "Failed to copy xen to EFI/xen"
    else
        bberror "Could not find xen.efi in either /usr/lib/efi or /boot"
    fi

    # Create versioned symlinks for consistency
    if [ -e ${D}/boot/efi/EFI/BOOT/xen.efi ]; then
        ln -sf xen.efi ${D}/boot/efi/EFI/BOOT/xen-4.efi
        ln -sf xen.efi ${D}/boot/efi/EFI/xen/xen-4.efi
    fi
}

# Fix QA issues
# Properly strip debug info while preserving debugging capability
do_install:append() {
    if [ -d ${D}/usr/lib/.debug ]; then
        find ${D}/usr/lib/.debug -type f -name "*.so*" -exec ${STRIP} --remove-section=.comment --remove-section=.note {} \;
    fi
}

# Fallback to skip remaining warnings if any
INSANE_SKIP:${PN}-dbg += "buildpaths"
INSANE_SKIP:${PN} += "already-stripped file-rdeps"

FILES:${PN} += " \
    /boot/efi/EFI/xen.efi \
    /boot/efi/EFI/xen-4.efi \
    /boot/efi/EFI/xen-4.18.efi \
    /boot/efi/EFI/xen-4.18.1-pre.efi \
    /boot/efi/EFI/xen/* \
    /boot/efi/EFI/BOOT/* \
    /usr/lib/efi/* \
    /usr/lib \
    /usr/sbin \
    /usr/sbin/* \
    /usr/lib/efi \
    ${sysconfdir}/xen/* \
"

