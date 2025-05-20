SUMMARY = "Xen boot repair tools for Tegra platforms"
DESCRIPTION = "Scripts to fix Xen booting issues on NVIDIA Tegra platforms"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# Tell Yocto where to find the files
FILESEXTRAPATHS:prepend := "${THISDIR}/xen-tegra-boot-fix/files:"

SRC_URI = "file://xen-boot-repair.sh \
           file://xen-check.sh"

S = "${WORKDIR}"

RDEPENDS:${PN} = "bash findutils efibootmgr xen"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/xen-boot-repair.sh ${D}${bindir}/
    install -m 0755 ${WORKDIR}/xen-check.sh ${D}${bindir}/
}

FILES:${PN} = "${bindir}/xen-boot-repair.sh ${bindir}/xen-check.sh"

# Create systemd service to run repair on first boot
inherit systemd

SYSTEMD_SERVICE:${PN} = "xen-boot-repair.service"

do_install:append() {
    install -d ${D}${systemd_system_unitdir}
    cat > ${D}${systemd_system_unitdir}/xen-boot-repair.service << EOF
[Unit]
Description=Fix Xen booting configuration
After=local-fs.target
Before=xen.service

[Service]
Type=oneshot
ExecStart=${bindir}/xen-boot-repair.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
}

