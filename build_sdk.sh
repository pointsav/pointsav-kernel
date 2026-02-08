#!/bin/bash
set -e

# Define Paths
PKG_ROOT="$(pwd)"
RAW_SOURCE="$PKG_ROOT/sel4_sdk"
SOVEREIGN_SDK="$PKG_ROOT/sovereign-sdk"

echo "🏗️  Building Sovereign SDK (Architecture: x86_64 / iMac)..."

# 1. Clean Slate
rm -rf "$SOVEREIGN_SDK"
mkdir -p "$SOVEREIGN_SDK/include/sel4"
mkdir -p "$SOVEREIGN_SDK/include/sel4/arch"
mkdir -p "$SOVEREIGN_SDK/include/sel4/sel4_arch"

# 2. FLATTEN HEADERS (Robust Mode)

# A. Base Headers
# We copy the CONTENTS of the include directory (folders like 'sel4', 'interfaces')
# We use -r to capture subdirectories.
if [ -d "$RAW_SOURCE/include" ]; then
    cp -r "$RAW_SOURCE/include/"* "$SOVEREIGN_SDK/include/"
else
    echo "❌ Error: Source include directory not found at $RAW_SOURCE/include"
    exit 1
fi

# B. Architecture Headers (x86_64)
# We find the specific x86 headers and merge them into the generic slots.
ARCH_SRC="$RAW_SOURCE/arch_include/x86/sel4/arch"

if [ -d "$ARCH_SRC" ]; then
    echo "   -> Merging x86 Architecture headers..."
    # Copy contents of x86 arch directly to include/sel4/arch
    cp -r "$ARCH_SRC/"* "$SOVEREIGN_SDK/include/sel4/arch/"
    # Duplicate to sel4_arch to satisfy legacy/internal includes
    cp -r "$ARCH_SRC/"* "$SOVEREIGN_SDK/include/sel4/sel4_arch/"
else
    echo "❌ Error: Architecture headers not found at $ARCH_SRC"
    exit 1
fi

# C. Config Headers (The Identity)
# Define the 64-bit iMac personality
cat <<CONFIG > "$SOVEREIGN_SDK/include/sel4/config.h"
#pragma once
#define CONFIG_WORD_SIZE 64
#define CONFIG_RET_TYPE_SIZE_BITS 32
#define CONFIG_KERNEL_MCS 1      
#define CONFIG_MAX_NUM_NODES 1   
CONFIG

# D. BootInfo Patch (Critical for Root-Task)
# Ensure the bootinfo types are visible
if [ -f "$SOVEREIGN_SDK/include/sel4/bootinfo_types.h" ]; then
    echo "   -> BootInfo types verified."
else
    echo "⚠️  Warning: bootinfo_types.h not found in root, searching..."
    find "$RAW_SOURCE" -name "bootinfo_types.h" -exec cp {} "$SOVEREIGN_SDK/include/sel4/" \;
fi

echo "✅ SDK Headers Flattened."

# 3. VERIFICATION
# Check for the file that caused the panic (simple_types.h)
if [ -f "$SOVEREIGN_SDK/include/sel4/arch/simple_types.h" ]; then
    echo "🔍 Verification Passed: simple_types.h is present."
else
    echo "❌ Verification Failed: simple_types.h is MISSING."
    echo "   listing include/sel4/arch:"
    ls "$SOVEREIGN_SDK/include/sel4/arch"
    exit 1
fi

echo "📦 Sovereign SDK Ready at: $SOVEREIGN_SDK"
