#!/bin/bash
set -e

echo "🔄 INITIATING SOVEREIGN RESET (GRAND UNIFIED)..."
echo "================================================="

# 1. CLEANUP
rm -rf sel4_sdk sovereign-sdk temp_sel4
echo "🗑️  Old artifacts destroyed."

# 2. SOVEREIGN FETCH
SEL4_VER="13.0.0"
echo "⬇️  Fetching seL4 v$SEL4_VER..."
mkdir -p temp_sel4 sel4_sdk
curl -L -s "https://github.com/seL4/seL4/archive/refs/tags/$SEL4_VER.tar.gz" -o temp_sel4/src.tar.gz
tar -xzf temp_sel4/src.tar.gz -C temp_sel4

# 3. SOURCE POSITIONING (The "Four Pillars" Strategy)
echo "📦 Positioning Raw Source..."
SRC_ROOT="temp_sel4/seL4-$SEL4_VER/libsel4"
TARGET_INC="sel4_sdk/include"

mkdir -p "$TARGET_INC"

# A. Generic Headers
cp -r "$SRC_ROOT/include/"* "$TARGET_INC/"

# B. Architecture Headers (x86 specific)
cp -r "$SRC_ROOT/arch_include/x86/"* "$TARGET_INC/"

# C. Platform Headers (PC99 / Generic x86)
if [ -d "$SRC_ROOT/sel4_plat/include" ]; then
    cp -r "$SRC_ROOT/sel4_plat/include/"* "$TARGET_INC/"
fi

# D. Mode Headers (The MISSING LINK: 64-bit types)
# This is where simple_types.h usually lives!
if [ -d "$SRC_ROOT/mode_include/64" ]; then
    echo "   -> Merging 64-bit Mode headers..."
    cp -r "$SRC_ROOT/mode_include/64/"* "$TARGET_INC/"
fi

# 4. SOVEREIGN SDK GENERATION
echo "🏗️  Constructing Sovereign SDK Artifact..."
SDK_DIR="$(pwd)/sovereign-sdk"
mkdir -p "$SDK_DIR/include/sel4/arch"
mkdir -p "$SDK_DIR/include/sel4/sel4_arch"

# Copy our Unified Source into the Artifact
cp -r "$TARGET_INC/"* "$SDK_DIR/include/"

# 5. HEADER COMPATIBILITY FIX (The "We Own It" Mapping)
# seL4 code is messy; it expects 'simple_types.h' in multiple places.
# We FORCE it to exist in all expected locations.

# Find simple_types.h wherever it ended up
SIMPLE_TYPES=$(find "$SDK_DIR/include" -name "simple_types.h" | head -n 1)

if [ -z "$SIMPLE_TYPES" ]; then
    echo "❌ FATAL: simple_types.h still not found. The fetch failed."
    exit 1
else
    echo "   -> Found simple_types.h at: $SIMPLE_TYPES"
    # Ensure it is in sel4/arch/ (Where Clang looks)
    cp "$SIMPLE_TYPES" "$SDK_DIR/include/sel4/arch/"
    # Ensure it is in sel4/sel4_arch/ (Legacy backup)
    cp "$SIMPLE_TYPES" "$SDK_DIR/include/sel4/sel4_arch/"
fi

# 6. IDENTITY INJECTION
cat <<CONFIG > "$SDK_DIR/include/sel4/config.h"
#pragma once
#define CONFIG_WORD_SIZE 64
#define CONFIG_RET_TYPE_SIZE_BITS 32
#define CONFIG_KERNEL_MCS 1      
#define CONFIG_MAX_NUM_NODES 1   
CONFIG

# 7. CLEANUP
rm -rf temp_sel4
echo "================================================="
echo "✅ RESET COMPLETE. SDK contains Mode-64 headers."
