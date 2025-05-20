
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Add our Xen GRUB config
SRC_URI += "file://xen-grub.cfg"

do_install:append() {
    # Install custom GRUB configuration with Xen support
    if [ -e ${WORKDIR}/xen-grub.cfg ]; then
        install -d ${D}${EFI_FILES_PATH}
        install -m 0644 ${WORKDIR}/xen-grub.cfg ${D}${EFI_FILES_PATH}/grub.cfg
    fi
}

# Ensure the files are included in the package
FILES:${PN} += "${EFI_FILES_PATH}/grub.cfg"
