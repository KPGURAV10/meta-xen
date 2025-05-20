# recipes-virtualization/images/xen-tegra-full.bb
SUMMARY = "Complete image with Xen hypervisor for Jetson Orin Nano"
DESCRIPTION = "Image with Xen hypervisor, DOM0 and management tools optimized for NVIDIA Jetson platforms"
LICENSE = "MIT"

# Inherit core-image
inherit core-image

# Add additional Tegra-specific components not already in the minimal image
IMAGE_INSTALL:append = " \
    htop \
    lsof \
    strace \
    gdb \
    file \
    python3 \
    python3-pip \
    i2c-tools \
    usbutils \
    ethtool \
    tcpdump \
    iperf3 \
    rsync \
    curl \
    wget \
"

# Distro features with wayland and opengl, x11 for fallback
DISTRO_FEATURES:append = " virtualization xen wayland libvirt opengl x11"

# Package installation with weston and GPU support
IMAGE_INSTALL += " \
    xen xen-tools libvirt \
    weston weston-init weston-examples \
    kernel-module-xen-blkback kernel-module-xen-netback \
"

PREFERRED_PROVIDER_virtual/kernel ?= "linux-yocto"
PREFERRED_VERSION_linux-yocto = "6.6%"

# Xen config
PREFERRED_VERSION_xen = "4.18%"
PREFERRED_VERSION_xen-tools = "4.18%"

# Enable additional features
IMAGE_FEATURES:append = " package-management ssh-server-openssh"

# Include development tools for more complete image
IMAGE_FEATURES:append = " tools-debug tools-sdk dev-pkgs"

# Additional configuration for Xen on Tegra
XEN_KERNEL_MODULES:append = " kernel-module-xen-gntalloc"

# Create a first-boot setup script for Xen
ROOTFS_POSTPROCESS_COMMAND:append = " setup_xen_firstboot;"

setup_xen_firstboot() {
    # Create a firstboot script
    install -d ${IMAGE_ROOTFS}/usr/local/bin
    cat > ${IMAGE_ROOTFS}/usr/local/bin/xen-firstboot-setup.sh << 'EOF'
#!/bin/bash
# First boot setup for Xen on Tegra
echo "Setting up network bridge for Xen..."
cat > /etc/network/interfaces.d/xenbr0 << BRIDGE
auto xenbr0
iface xenbr0 inet dhcp
    bridge_ports eth0
    bridge_stp off
    bridge_waitport 0
    bridge_fd 0
BRIDGE

# Create a domain config template
mkdir -p /etc/xen
cat > /etc/xen/vm-template.cfg << TEMPLATE
name = "guest-vm"
memory = 2048
vcpus = 2
disk = [ 'phy:/dev/loop0,xvda,w' ]
vif = [ 'bridge=xenbr0' ]
TEMPLATE

# Mark first boot as completed
touch /var/lib/xen/firstboot-done
EOF
    chmod +x ${IMAGE_ROOTFS}/usr/local/bin/xen-firstboot-setup.sh
    
    # Create systemd service to run first boot script
    install -d ${IMAGE_ROOTFS}/etc/systemd/system
    cat > ${IMAGE_ROOTFS}/etc/systemd/system/xen-firstboot.service << 'EOF'
[Unit]
Description=Xen First Boot Setup
After=network.target
ConditionPathExists=!/var/lib/xen/firstboot-done

[Service]
Type=oneshot
ExecStart=/usr/local/bin/xen-firstboot-setup.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    
    # Enable the service
    install -d ${IMAGE_ROOTFS}/etc/systemd/system/multi-user.target.wants
    ln -sf /etc/systemd/system/xen-firstboot.service ${IMAGE_ROOTFS}/etc/systemd/system/multi-user.target.wants/
}
