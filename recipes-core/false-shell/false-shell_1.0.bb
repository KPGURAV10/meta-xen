SUMMARY = "Shell that always returns false, needed for system users"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

INHIBIT_DEFAULT_DEPS = "1"
ALLOW_EMPTY:${PN} = "1"

do_install() {
    install -d ${D}${base_bindir}
    
    # Create /bin/false as a symlink to /bin/true if it exists
    if [ -e ${D}${base_bindir}/true ]; then
        ln -sf true ${D}${base_bindir}/false
    else
        # Otherwise create a simple script that exits with error
        cat > ${D}${base_bindir}/false << SCRIPT
#!/bin/sh
exit 1
SCRIPT
        chmod +x ${D}${base_bindir}/false
    fi
}

FILES:${PN} = "${base_bindir}/false"

REQUIRED_DISTRO_FEATURES = ""
RDEPENDS:${PN} = ""

# Make sure this gets built before any packages that need useradd
BBCLASSEXTEND = "native nativesdk"
