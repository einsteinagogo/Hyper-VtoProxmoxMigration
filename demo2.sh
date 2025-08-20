#!/bin/bash

# Source and destination paths
VHDX_PATH="/mnt/ntfs/VMs/hoplo-pi-hole_2.vhdx"
QCOW2_PATH="/root/hoplo.qcow2"
VMID=102
VM_NAME="Hoplo"
STORAGE="local-lvm"

echo "============================================"
echo "Starting Hyper-V VHDX -> Proxmox QCOW2 migration"
echo "VM Name: $VM_NAME, VMID: $VMID"
echo "Source VHDX: $VHDX_PATH"
echo "Destination QCOW2: $QCOW2_PATH"
echo "============================================"
echo

# Function to echo command, explain, and pause
run_cmd() {
    echo
    echo ">>> $1"
    echo "Explanation: $2"
    read -p "Press [Enter] to run this command..."
    eval "$1"
    echo "Done."
}

# Step 1: Convert VHDX to QCOW2
run_cmd "qemu-img convert -f vhdx -O qcow2 -p \"$VHDX_PATH\" \"$QCOW2_PATH\"" "Convert Hyper-V VHDX disk to Proxmox-friendly QCOW2 format with progress."

# Step 2: Create a new Proxmox VM
run_cmd "qm create $VMID --name \"$VM_NAME\" --memory 4096 --net0 virtio,bridge=vmbr0" "Create VM with 4GB RAM, virtio network, and VMID $VMID."

# Step 3: Import QCOW2 disk into Proxmox storage
run_cmd "qm importdisk $VMID \"$QCOW2_PATH\" $STORAGE" "Import the QCOW2 disk into storage $STORAGE."

# Step 4: Attach the imported disk to the VM
run_cmd "qm set $VMID --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$VMID-disk-0" "Attach the imported disk as SCSI0 with VirtIO controller for better performance."

# Step 5: Configure CPU, RAM, and network
run_cmd "qm set $VMID --cores 4 --memory 4096 --net0 virtio,bridge=vmbr0" "Set CPU cores to 4, RAM to 4GB, and configure network interface."

# Step 6: Enable UEFI firmware
run_cmd "qm set $VMID --bios ovmf" "Switch BIOS to OVMF (UEFI) for modern boot support."

# Step 7: Set boot order to use the attached disk
run_cmd "qm set $VMID --boot order=scsi0" "Ensure VM boots from the attached disk."

# Step 8: Display VM configuration
run_cmd "qm config $VMID" "Show current VM configuration before starting."

# Step 9: Start the VM
run_cmd "qm start $VMID" "Boot the VM."
echo
echo "VM $VM_NAME (ID: $VMID) started successfully!"
echo "============================================"
