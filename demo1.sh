#!/bin/bash

# Source and destination paths
VHDX_PATH="/mnt/ntfs/VMs/apistogramma-pi-hole_2.vhdx"
QCOW2_PATH="/root/apistogramma.qcow2"
VMID=101
VM_NAME="Apistogramma"
STORAGE="local-lvm"

echo "============================================"
echo "Starting Hyper-V VHDX -> Proxmox QCOW2 migration"
echo "VM Name: $VM_NAME, VMID: $VMID"
echo "Source VHDX: $VHDX_PATH"
echo "Destination QCOW2: $QCOW2_PATH"
echo "============================================"
echo

# Step 1: Convert VHDX to QCOW2 with progress
echo "[Step 1] Converting VHDX -> QCOW2..."
qemu-img convert -f vhdx -O qcow2 -p "$VHDX_PATH" "$QCOW2_PATH"
echo "Conversion complete."
echo

# Step 2: Create a new Proxmox VM
echo "[Step 2] Creating VM $VM_NAME (ID: $VMID)..."
qm create $VMID --name "$VM_NAME" --memory 4096 --net0 virtio,bridge=vmbr0
echo "VM created."
echo

# Step 3: Import QCOW2 disk into Proxmox storage
echo "[Step 3] Importing disk to $STORAGE..."
qm importdisk $VMID "$QCOW2_PATH" $STORAGE
echo "Disk import complete."
echo

# Step 4: Attach the imported disk to the VM
echo "[Step 4] Attaching disk to VM..."
qm set $VMID --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$VMID-disk-0
echo "Disk attached."
echo

# Step 5: Configure CPU, RAM, and network
echo "[Step 5] Configuring VM hardware..."
qm set $VMID --cores 4 --memory 4096 --net0 virtio,bridge=vmbr0
echo "Hardware configured."
echo

# Step 6: Enable UEFI (OVMF) firmware
echo "[Step 6] Setting BIOS to OVMF (UEFI)..."
qm set $VMID --bios ovmf
echo "UEFI enabled."
echo

# Step 7: Set boot order to use the attached disk
echo "[Step 7] Setting boot order..."
qm set $VMID --boot order=scsi0
echo "Boot order set."
echo

# Step 8: Display VM configuration
echo "[Step 8] VM configuration:"
qm config $VMID
echo

# Step 9: Start the VM
echo "[Step 9] Starting VM..."
qm start $VMID
echo "VM $VM_NAME (ID: $VMID) started successfully!"
echo "============================================"
