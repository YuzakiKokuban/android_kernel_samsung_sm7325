#!/bin/bash
#
# SM7325 (lahaina) kernel build script
# Prerequisite: source env_setup.sh first, or run directly (paths are auto-set)
#

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

export ARCH=arm64
export PROJECT_NAME=gts7xllite

# ── Toolchain paths ─────────────────────────────────────────
# Clang + LLVM toolchain (from prebuilts)
CLANG_BIN="${SCRIPT_DIR}/prebuilts-master/clang/host/linux-x86/clang-r416183b/bin"
CLANG="${CLANG_BIN}/clang"

# Build tools
BUILD_TOOLS_BIN="${SCRIPT_DIR}/prebuilts/build-tools/linux-x86/bin"
BUILD_TOOLS_PATH="${SCRIPT_DIR}/build/build-tools/path/linux-x86"
KERNEL_BUILD_TOOLS="${SCRIPT_DIR}/prebuilts/kernel-build-tools/linux-x86/bin"

# Cross-compile wrapper (symlinks to LLVM tools + gas assembler)
TOOLCHAIN_WRAPPER="${SCRIPT_DIR}/toolchain/bin"
CROSS_COMPILE="${TOOLCHAIN_WRAPPER}/aarch64-linux-gnu-"
CROSS_COMPILE_PREFIX="aarch64-linux-gnu-"

# PATH: toolchain wrapper FIRST so clang finds cross-as before system /usr/bin/as
export PATH="${TOOLCHAIN_WRAPPER}:${CLANG_BIN}:${BUILD_TOOLS_BIN}:${BUILD_TOOLS_PATH}:${KERNEL_BUILD_TOOLS}:${PATH}"

# Compiler (export as env var, not make arg — avoids shell escaping issues)
export CC="${CLANG}"

# Tell kernel Makefile to use clang for host tools too (avoids gcc)
export LLVM=1

# Explicit tool overrides
export AS="${TOOLCHAIN_WRAPPER}/aarch64-linux-gnu-as"
export LD=ld.lld
export AR=llvm-ar
export NM=llvm-nm
export OBJCOPY=llvm-objcopy
export OBJDUMP=llvm-objdump
export STRIP=llvm-strip

# bison needs explicit M4 path
export M4="${BUILD_TOOLS_BIN}/m4"

# ── Build flags ─────────────────────────────────────────────
KERNEL_MAKE_ENV="DTC_EXT=${SCRIPT_DIR}/tools/dtc CONFIG_BUILD_ARM64_DT_OVERLAY=y"
DEFCONFIG=vendor/gts7fewifi_eur_open_defconfig

mkdir -p "${SCRIPT_DIR}/out"

# ── Common make args ─────────────────────────────────────────
MAKE_ARGS="ARCH=arm64"
MAKE_ARGS+=" CROSS_COMPILE=${CROSS_COMPILE}"
MAKE_ARGS+=" AS=${AS}"
MAKE_ARGS+=" LD=ld.lld"
MAKE_ARGS+=" AR=llvm-ar"
MAKE_ARGS+=" NM=llvm-nm"
MAKE_ARGS+=" OBJCOPY=llvm-objcopy"
MAKE_ARGS+=" OBJDUMP=llvm-objdump"
MAKE_ARGS+=" STRIP=llvm-strip"
MAKE_ARGS+=" CLANG_TRIPLE=aarch64-linux-gnu-"
MAKE_ARGS+=" CONFIG_SECTION_MISMATCH_WARN_ONLY=y"

mkdir -p "${SCRIPT_DIR}/out"

# ── Build ───────────────────────────────────────────────────
JOBS=$(nproc)
echo "========================================="
echo " Building SM7325 kernel"
echo " CC:       ${CLANG}"
echo " AS:       ${AS}"
echo " CROSS:    ${CROSS_COMPILE}"
echo " JOBS:     ${JOBS}"
echo " OUT:      ${SCRIPT_DIR}/out"
echo "========================================="

set -e

# Step 1: generate .config
make -j"${JOBS}" -C "${SCRIPT_DIR}" O="${SCRIPT_DIR}/out" \
	${KERNEL_MAKE_ENV} \
	${MAKE_ARGS} \
	"${DEFCONFIG}"

# Step 2: build
make -j"${JOBS}" -C "${SCRIPT_DIR}" O="${SCRIPT_DIR}/out" \
	${KERNEL_MAKE_ENV} \
	${MAKE_ARGS}

# Copy output Image
cp "${SCRIPT_DIR}/out/arch/arm64/boot/Image" "${SCRIPT_DIR}/arch/arm64/boot/Image" 2>/dev/null || true

echo "========================================="
echo " Build finished!"
echo " Image: ${SCRIPT_DIR}/out/arch/arm64/boot/Image"
echo "========================================="
