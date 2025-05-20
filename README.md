# meta-xen

This Yocto layer provides comprehensive Xen hypervisor support for NVIDIA Jetson platforms, specifically optimized for the Jetson Orin Nano.

## Overview

The meta-xen layer enables full virtualization capabilities on NVIDIA Jetson platforms by integrating the Xen hypervisor with NVIDIA's specialized hardware and drivers. This allows running multiple virtual machines on a single Jetson device.

## Features

- Complete Xen hypervisor integration with NVIDIA Jetson platforms
- UEFI boot support for Xen
- Device passthrough configuration for NVIDIA GPUs
- Comprehensive toolset for managing Xen virtual machines
- Optimized kernel configuration for virtualization on ARM64

## Dependencies

This layer depends on:

- meta-tegra (https://github.com/OE4T/meta-tegra)
- meta-virtualization (https://git.yoctoproject.org/meta-virtualization)
- meta-openembedded/meta-oe (https://git.openembedded.org/meta-openembedded)
- meta-openembedded/meta-python (https://git.openembedded.org/meta-openembedded)
- meta-openembedded/meta-networking (https://git.openembedded.org/meta-openembedded)

## Usage

### Adding the Layer

Add this layer to your build environment:

```
bitbake-layers add-layer /path/to/meta-xen
```

### Configuration

Add the following to your local.conf:

```
# Enable virtualization features
DISTRO_FEATURES:append = " virtualization xen efi systemd"

# Xen version
PREFERRED_VERSION_xen = "4.18%"
PREFERRED_VERSION_xen-tools = "4.18%"

# Enable Xen on Tegra platform
MACHINE_FEATURES:append = " xen"

# Accept NVIDIA licenses
LICENSE_FLAGS_ACCEPTED += "commercial_nvidia-l4t"
```

### Building the Image

Build the full Xen-enabled image:

```
bitbake xen-tegra-full
```

### Booting with Xen

After flashing the image to your Jetson device, you can boot with Xen in two ways:

#### 1. Using extlinux.conf (Legacy boot)

Add the following entry to `/boot/extlinux/extlinux.conf`:

```
LABEL xen
    MENU LABEL Xen Hypervisor
    KERNEL /boot/xen
    APPEND dom0_mem=1024M console=dtuart dtuart=serial8250,mmio,0x3100000 dom0_max_vcpus=4
    FDT /boot/tegra234-p3768-0000+p3767-0005-nv.dtb
    XENPARAM /boot/Image
    XENFDT /boot/tegra234-p3768-0000+p3767-0005-nv.dtb
    XEN_INITRD /boot/initrd
    XINIT root=/dev/nvme0n1p1 rw rootwait console=hvc0 earlyprintk=xen
```

#### 2. Using UEFI boot (Recommended)

The image includes UEFI boot support with Xen. To use it:

1. Enter the UEFI boot menu by pressing ESC during boot
2. Select the Xen boot entry
3. Alternatively, use `efibootmgr` to set Xen as the default boot option

## Creating VMs

After booting into Xen, you can create VMs using the xl tools:

```
# Create a VM using the example config
xl create /etc/xen/xlexample.cfg

# List running VMs
xl list

# Connect to VM console
xl console example-vm
```

## Troubleshooting

### Verifying Xen is Running

Check if Xen is running with:

```
xl info
```

If you see an error about "privileged command interface," Xen is not running.

### Debug Logs

Check Xen boot logs with:

```
dmesg | grep -i xen
```

### Common Issues

1. **Missing xen binary**: Ensure the Xen hypervisor binary is present in /boot
2. **Boot configuration**: Verify the extlinux.conf or UEFI boot entries
3. **Kernel compatibility**: Make sure the kernel has Xen support enabled
4. **Permissions**: Xen commands need root privileges

## License

This layer is provided under the MIT license. See LICENSE for details.

## Maintainer

Please submit issues and pull requests on GitHub.
