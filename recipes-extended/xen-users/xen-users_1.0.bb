SUMMARY = "Create and configure xen and root users"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit useradd

# SHA-512 hash of the password "xen123" for the xen user
XEN_PASSWORD = "$6$z4zwrXaB1$cK0x4vw.fYwbOh/S7F4ZKfH8o7AvdPOCdtgXkWtSVaasF0HCZwq/Dz2M/K2BchLxGj6yvtRvXJB2kJijZuwpb."

# SHA-512 hash of the password "root123" for the root user
ROOT_PASSWORD = "$6$wVkTqPvC$e.4KPS2CHu3F.uQcJc8.QpFqc0cK9wqTAiCxLVl7g/PiAm6VWqd5HzVsVefkb3SJN8wmNEiVw9LtxJf3YaD7Y."

# Set up the xen user
USERADD_PACKAGES = "${PN}"
USERADD_PARAM:${PN} = "-u 1000 -d /home/xen -m -s /bin/bash -p '${XEN_PASSWORD}' -G sudo xen"

# Setup the root user password
pkg_postinst:${PN}() {
    if [ -n "$D" ]; then
        # Running in the context of image building
        # Set the root password
        sed -i "s,root:[^:]*:,root:${ROOT_PASSWORD}:," $D/etc/shadow
        
        # Make sure root shell is set correctly
        sed -i "s,root:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*,root:x:0:0:root:/home/root:/bin/bash," $D/etc/passwd
        
        # Create /bin/false if it doesn't exist
        if [ ! -e $D/bin/false ]; then
            mkdir -p $D/bin
            cat > $D/bin/false << SCRIPT
#!/bin/sh
exit 1
SCRIPT
            chmod +x $D/bin/false
        fi
    else
        # Running on the target
        # This won't happen in normal Yocto builds
        echo "xen-users package installed on the target system"
    fi
}

ALLOW_EMPTY:${PN} = "1"
PACKAGES = "${PN}"
FILES:${PN} = ""

# Ensure sudo is available
RDEPENDS:${PN} = "sudo"
