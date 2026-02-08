#!/bin/bash
set -e

echo "🏗️  BUILDING PRODUCTION-GRADE SOVEREIGN SDK (Hermetic w/ Absolute Paths)..."
echo "========================================================================="

# 1. SETUP
rm -rf sel4_sdk sovereign-sdk temp_sel4
SEL4_VER="13.0.0"
# Capture the Absolute Root of the build immediately
BUILD_ROOT="$(pwd)"
SDK_ROOT="$BUILD_ROOT/sovereign-sdk"
INCLUDE_DIR="$SDK_ROOT/include"
TOOLS_DIR="$BUILD_ROOT/tools"

# 2. VENDOR TOOLING
mkdir -p "$TOOLS_DIR/ply"
touch "$TOOLS_DIR/ply/__init__.py"

echo "🛠️  Verifying Toolchain..."

# A. Bitfield Generator
if [ ! -f "$TOOLS_DIR/bitfield_gen.py" ]; then
    echo "   -> Fetching bitfield_gen.py..."
    curl -L -s "https://raw.githubusercontent.com/seL4/seL4/13.0.0/tools/bitfield_gen.py" -o "$TOOLS_DIR/bitfield_gen.py"
fi

# B. PLY Dependencies
if [ ! -f "$TOOLS_DIR/ply/lex.py" ]; then
    echo "   -> Fetching Dependency: lex.py..."
    curl -L -s "https://raw.githubusercontent.com/dabeaz/ply/master/src/ply/lex.py" -o "$TOOLS_DIR/ply/lex.py"
    cp "$TOOLS_DIR/ply/lex.py" "$TOOLS_DIR/lex.py"
fi

if [ ! -f "$TOOLS_DIR/ply/yacc.py" ]; then
    echo "   -> Fetching Dependency: yacc.py..."
    curl -L -s "https://raw.githubusercontent.com/dabeaz/ply/master/src/ply/yacc.py" -o "$TOOLS_DIR/ply/yacc.py"
    cp "$TOOLS_DIR/ply/yacc.py" "$TOOLS_DIR/yacc.py"
fi

# C. UMM Dependency
if [ ! -f "$TOOLS_DIR/umm.py" ]; then
    echo "   -> Fetching Dependency: umm.py..."
    curl -L -s "https://raw.githubusercontent.com/seL4/seL4/13.0.0/tools/umm.py" -o "$TOOLS_DIR/umm.py"
fi

# 3. FETCH KERNEL SOURCE
echo "⬇️  Fetching seL4 Kernel v$SEL4_VER..."
mkdir -p temp_sel4
curl -L -s "https://github.com/seL4/seL4/archive/refs/tags/$SEL4_VER.tar.gz" -o temp_sel4/src.tar.gz
tar -xzf temp_sel4/src.tar.gz -C temp_sel4
SRC_ROOT="temp_sel4/seL4-$SEL4_VER/libsel4"

# 4. PREPARE SDK DIRECTORIES
mkdir -p "$INCLUDE_DIR/sel4/arch"
mkdir -p "$INCLUDE_DIR/sel4/sel4_arch"
mkdir -p "$INCLUDE_DIR/sel4/mode"

echo "📦 Merging Headers..."

# Pillars A, B, C
cp -r "$SRC_ROOT/include/"* "$INCLUDE_DIR/"
cp -r "$SRC_ROOT/arch_include/x86/"* "$INCLUDE_DIR/"

if [ -d "$SRC_ROOT/sel4_arch_include/x86_64" ]; then
    echo "   -> Merging x86_64 Headers..."
    cp -r "$SRC_ROOT/sel4_arch_include/x86_64/"* "$INCLUDE_DIR/"
else
    echo "❌ FATAL: x86_64 headers missing."
    exit 1
fi

# 5. CODE GENERATION (Hermetic & Absolute)
echo "⚙️  Generating Hardware Types..."

# Find the relative path first
REL_BF_FILE=$(find "$SRC_ROOT" -name "types.bf" | grep "x86_64" | head -n 1)

if [ -z "$REL_BF_FILE" ]; then
    echo "❌ FATAL: types.bf spec file not found."
    exit 1
fi

# CONVERT TO ABSOLUTE PATH (The Fix)
# We prepend the BUILD_ROOT to the relative path found by 'find'
ABS_BF_FILE="$BUILD_ROOT/$REL_BF_FILE"

echo "   -> Spec File: $ABS_BF_FILE"

# Change to tools directory to satisfy Python imports
cd "$TOOLS_DIR"
# Pass the ABSOLUTE path to the script
python3 bitfield_gen.py "$ABS_BF_FILE" "$INCLUDE_DIR/sel4/sel4_arch/types_gen.h"
# Return to build root
cd "$BUILD_ROOT"

# 6. CONFIGURATION IDENTITY
echo "   -> Generating Identity (autoconf.h)..."
cat <<CONFIG > "$INCLUDE_DIR/sel4/autoconf.h"
#pragma once
/* PointSav Sovereign Identity: x86_64 (iMac) */
#define CONFIG_ARCH_X86_64 1
#define CONFIG_ARCH_X86 1
#define CONFIG_WORD_SIZE 64
#define CONFIG_USER_TOP 0xa0000000
#define CONFIG_MAX_NUM_NODES 1
#define CONFIG_KERNEL_MCS 1
#define CONFIG_DEBUG_BUILD 1
CONFIG
cp "$INCLUDE_DIR/sel4/autoconf.h" "$INCLUDE_DIR/sel4/config.h"

# 7. VERIFICATION
echo "🔍 Verifying Generated Artifact..."
if [ -s "$INCLUDE_DIR/sel4/sel4_arch/types_gen.h" ]; then
    echo "✅ SUCCESS: types_gen.h generated and populated."
else
    echo "❌ FAILURE: types_gen.h is empty or missing."
    exit 1
fi

rm -rf temp_sel4
echo "========================================================================="
echo "📦 SDK Ready."
