#!/bin/bash
set -e

echo "🔍 INITIATING FORENSIC SDK REBUILD..."
echo "======================================"

# 1. CLEANUP
rm -rf sel4_sdk sovereign-sdk temp_sel4
echo "🗑️  Old artifacts destroyed."

# 2. SOVEREIGN FETCH
SEL4_VER="13.0.0"
echo "⬇️  Fetching seL4 v$SEL4_VER..."
mkdir -p temp_sel4 sel4_sdk
curl -L -s "https://github.com/seL4/seL4/archive/refs/tags/$SEL4_VER.tar.gz" -o temp_sel4/src.tar.gz
tar -xzf temp_sel4/src.tar.gz -C temp_sel4

SRC_ROOT="temp_sel4/seL4-$SEL4_VER/libsel4"
SDK_INC="$(pwd)/sovereign-sdk/include"

# 3. CONSTRUCT SDK
mkdir -p "$SDK_INC/sel4"
mkdir -p "$SDK_INC/sel4/arch"
mkdir -p "$SDK_INC/sel4/sel4_arch"

echo "📦 Positioning Headers..."

# A. Generic Headers
cp -r "$SRC_ROOT/include/"* "$SDK_INC/"

# B. Architecture Headers (x86)
cp -r "$SRC_ROOT/arch_include/x86/sel4/arch/"* "$SDK_INC/sel4/arch/"
cp -r "$SRC_ROOT/arch_include/x86/sel4/arch/"* "$SDK_INC/sel4/sel4_arch/"

# C. Mode Headers (The Critical 64-bit Types)
if [ -d "$SRC_ROOT/mode_include/64" ]; then
    echo "   -> Injecting 64-bit Mode headers..."
    cp -r "$SRC_ROOT/mode_include/64/"* "$SDK_INC/sel4/"
else
    # Fallback search if directory structure changed
    find temp_sel4 -name "simple_types.h" -exec cp {} "$SDK_INC/sel4/" \;
fi

# 4. THE "WE OWN IT" PATCHES (Critical for Bindgen)

# A. Create autoconf.h (Bindgen looks for this implicitly in some setups)
cat <<CONFIG > "$SDK_INC/sel4/autoconf.h"
#pragma once
#define CONFIG_WORD_SIZE 64
#define CONFIG_RET_TYPE_SIZE_BITS 32
#define CONFIG_KERNEL_MCS 1      
#define CONFIG_MAX_NUM_NODES 1   
#define CONFIG_DEBUG_BUILD 1
CONFIG
# Copy to config.h for compatibility
cp "$SDK_INC/sel4/autoconf.h" "$SDK_INC/sel4/config.h"

# B. The simple_types.h Brute Force
# We ensure this file exists in ALL potential include paths
TYPES_FILE=$(find "$SDK_INC" -name "simple_types.h" | head -n 1)
if [ -z "$TYPES_FILE" ]; then
    echo "❌ FATAL: simple_types.h missing."
    exit 1
fi
cp "$TYPES_FILE" "$SDK_INC/sel4/arch/simple_types.h"
cp "$TYPES_FILE" "$SDK_INC/sel4/sel4_arch/simple_types.h"
# Also place it at the root of 'sel4' just in case
cp "$TYPES_FILE" "$SDK_INC/sel4/simple_types.h"


# 5. CLEANUP & VERIFY
rm -rf temp_sel4
echo "======================================"
echo "✅ SDK REBUILT."
echo "   Verifying Identity..."
ls -l "$SDK_INC/sel4/autoconf.h"
ls -l "$SDK_INC/sel4/simple_types.h"
