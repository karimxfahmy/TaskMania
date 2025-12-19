#!/bin/bash

################################################################################
# GPU Detection Test Script
# Tests GPU detection on VMware and other virtual environments
################################################################################

echo "=== GPU Detection Test ==="
echo ""

# Check for DRM devices
echo "1. Checking for DRM devices..."
if [ -d /sys/class/drm ]; then
    echo "   ✓ /sys/class/drm exists"
    for card in /sys/class/drm/card[0-9]; do
        if [ -d "$card" ]; then
            echo "   Found: $(basename $card)"
            if [ -f "$card/device/vendor" ]; then
                vendor=$(cat "$card/device/vendor")
                echo "      Vendor ID: $vendor"
            fi
            if [ -f "$card/device/device" ]; then
                device=$(cat "$card/device/device")
                echo "      Device ID: $device"
            fi
        fi
    done
else
    echo "   ✗ /sys/class/drm not found"
fi

echo ""

# Check for nvidia-smi
echo "2. Checking for NVIDIA tools..."
if command -v nvidia-smi &> /dev/null; then
    echo "   ✓ nvidia-smi found"
    nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo "   (but not working)"
else
    echo "   ✗ nvidia-smi not found"
fi

echo ""

# Check for rocm-smi
echo "3. Checking for AMD ROCm tools..."
if command -v rocm-smi &> /dev/null; then
    echo "   ✓ rocm-smi found"
else
    echo "   ✗ rocm-smi not found"
fi

echo ""

# Check PCI devices
echo "4. Checking PCI VGA devices..."
if command -v lspci &> /dev/null; then
    lspci | grep -i vga || echo "   No VGA devices found via lspci"
else
    echo "   ✗ lspci not available"
fi

echo ""

# Test actual GPU detection from monitor script
echo "5. Testing GPU detection from monitor script..."
if [ -f /app/scripts/system_monitor.sh ]; then
    /app/scripts/system_monitor.sh once 2>/dev/null | grep -A 30 '"gpu"' || echo "   Failed to extract GPU section"
else
    echo "   ✗ Monitor script not found"
fi

echo ""
echo "=== Test Complete ==="


