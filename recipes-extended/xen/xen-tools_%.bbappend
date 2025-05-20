# Remove the conflicting xl.conf file from xen-tools-xl package
do_install:append() {
    if [ -e ${D}${sysconfdir}/xen/xl.conf ]; then
        rm -f ${D}${sysconfdir}/xen/xl.conf
    fi
}

# Make sure the conflict with xen package is explicitly resolved
RCONFLICTS:${PN}-xl = ""
RREPLACES:${PN}-xl = ""
