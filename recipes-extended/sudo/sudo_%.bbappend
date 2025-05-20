# Enable sudo for the xen user without password
do_install:append() {
    echo "xen ALL=(ALL) NOPASSWD: ALL" > ${D}${sysconfdir}/sudoers.d/xen
    chmod 0440 ${D}${sysconfdir}/sudoers.d/xen
}
