# Tegra-specific components for Xen minimal image
# ================================================

# Base system components
IMAGE_INSTALL:append = " \
    tegra-firmware \
    sudo \
    vim \
    util-linux \
    e2fsprogs-mke2fs \
    efibootmgr \
    dtc \
    xen-tegra-boot-fix \
"

# Networking tools
IMAGE_INSTALL:append = " \
    iproute2 \
    bridge-utils \
    iptables \
    net-tools \
    pciutils \
"

# Diagnostic tools
IMAGE_INSTALL:append = " \
    ldd \
    strace \
    lsof \
"

# Make sure the DTB is included
IMAGE_BOOT_FILES:append = " tegra234-p3768-0000+p3767-0003.dtb"

# Ensure EFI support is enabled (safe append)
DISTRO_FEATURES:append = " efi"

# Include and enable the boot repair service
SYSTEMD_AUTO_ENABLE:pn-xen-tegra-boot-fix ?= "enable"

# Include Xen kernel modules if available
KERNEL_MODULES = "${@bb.utils.contains('MACHINE_FEATURES', 'xen', \
    'kernel-module-xen-blkback \
     kernel-module-xen-gntalloc \
     kernel-module-xen-gntdev \
     kernel-module-xen-netback \
     kernel-module-xen-wdt', \
    '', d)}"
IMAGE_INSTALL:append = " ${KERNEL_MODULES}"

# Make sure xen is deployed
do_build[depends] += "xen:do_deploy"

# Copy Xen EFI to the boot partition with comprehensive error reporting
IMAGE_CMD:wic:append = ";\
    if [ -f ${DEPLOY_DIR_IMAGE}/xen-efi-${MACHINE}.bin ]; then \
        cp ${DEPLOY_DIR_IMAGE}/xen-efi-${MACHINE}.bin ${IMAGE_ROOTFS}/boot/efi/EFI/BOOT/xen.efi; \
    elif [ -f ${DEPLOY_DIR_IMAGE}/xen-${MACHINE} ]; then \
        cp ${DEPLOY_DIR_IMAGE}/xen-${MACHINE} ${IMAGE_ROOTFS}/boot/efi/EFI/BOOT/xen.efi; \
    elif [ -f ${IMAGE_ROOTFS}/boot/xen ]; then \
        cp ${IMAGE_ROOTFS}/boot/xen ${IMAGE_ROOTFS}/boot/efi/EFI/BOOT/xen.efi; \
    else \
        echo 'Warning: Could not find Xen EFI binary at any of:'; \
        echo '  - ${DEPLOY_DIR_IMAGE}/xen-efi-${MACHINE}.bin'; \
        echo '  - ${DEPLOY_DIR_IMAGE}/xen-${MACHINE}'; \
        echo '  - ${IMAGE_ROOTFS}/boot/xen'; \
        exit 1; \
    fi \
"
