
#!/bin/bash
# xen-check.sh - Verify Xen is working properly

echo "===== Xen Hypervisor Check ====="

# Check if Xen is running
echo -e "\nChecking if Xen is running:"
dmesg | grep -i xen

# Check if xl command is working
echo -e "\nChecking xl command:"
xl info

# Check dom0
echo -e "\nChecking dom0:"
xl list

# Check logs
echo -e "\nXen logs:"
grep -i xen /var/log/messages | tail -20 2>/dev/null || echo "No messages log found"
grep -i xen /var/log/syslog | tail -20 2>/dev/null || echo "No syslog found"

# Check EFI boot entries
echo -e "\nEFI boot entries:"
efibootmgr -v

# Check Xen files
echo -e "\nXen files:"
ls -la /boot/xen* 2>/dev/null || echo "No Xen files in /boot"
ls -la /boot/efi/EFI/BOOT/ 2>/dev/null || echo "No EFI boot directory"
