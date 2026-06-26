#!/bin/bash
# Kernel build environment setup for SM7325 (lahaina)
# Usage: source env_setup.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Toolchain paths ──────────────────────────────────────────
CLANG_DIR="${SCRIPT_DIR}/prebuilts-master/clang/host/linux-x86/clang-r416183b"
BUILD_TOOLS_BIN="${SCRIPT_DIR}/prebuilts/build-tools/linux-x86/bin"
BUILD_TOOLS_PATH="${SCRIPT_DIR}/build/build-tools/path/linux-x86"
KERNEL_BUILD_TOOLS="${SCRIPT_DIR}/prebuilts/kernel-build-tools/linux-x86/bin"
TOOLCHAIN_WRAPPER="${SCRIPT_DIR}/toolchain/bin"

# Wrapper must come FIRST so clang finds cross-as before system /usr/bin/as
export PATH="${TOOLCHAIN_WRAPPER}:${CLANG_DIR}/bin:${BUILD_TOOLS_BIN}:${BUILD_TOOLS_PATH}:${KERNEL_BUILD_TOOLS}:${PATH}"

# ── Kernel build config ─────────────────────────────────────
export ARCH=arm64
export PROJECT_NAME=gts7xllite

# Use Clang + LLD for everything (no GCC needed)
export CC=clang
export AS="${TOOLCHAIN_WRAPPER}/aarch64-linux-gnu-as"
export LD=ld.lld
export NM=llvm-nm
export OBJCOPY=llvm-objcopy
export OBJDUMP=llvm-objdump
export STRIP=llvm-strip
export AR=llvm-ar

# Cross-compile target (uses toolchain wrapper symlinks)
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE="${SCRIPT_DIR}/toolchain/bin/aarch64-linux-gnu-"

# bison needs explicit M4 path (its hardcoded /usr/bin/m4 may not exist)
export M4="${BUILD_TOOLS_BIN}/m4"

# DTC
export DTC_EXT="${SCRIPT_DIR}/tools/dtc"

# Build flags
export KERNEL_DIR="${SCRIPT_DIR}"
export OUT_DIR="${SCRIPT_DIR}/out"

echo "========================================="
echo " SM7325 Kernel Build Environment"
echo "========================================="
echo " ARCH:       ${ARCH}"
echo " CC:         $(which clang)"
echo " LD:         $(which ld.lld)"
echo " CROSS_COMPILE: ${CROSS_COMPILE}"
echo " OUT_DIR:    ${OUT_DIR}"
echo "========================================="
