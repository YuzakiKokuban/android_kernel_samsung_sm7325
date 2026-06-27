#!/bin/bash
# ============================================================
# Kokuban Local Build Script (ReSukiSU + AnyKernel3)
# SM7325 (lahaina) kernel — based on build_kernel.sh
#
# Usage: bash build_local.sh [VARIANT] [LOCALVERSION_SUFFIX]
#
#   variant: resukisu (default) | lkm
#   suffix:  optional extra version tag
#
# Examples:
#   bash build_local.sh                    # ReSuki build
#   bash build_local.sh lkm                # LKM build
#   bash build_local.sh resukisu "-test1"  # ReSuki + suffix
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ---- Project ----
DEFCONFIG="vendor/gts7fewifi_eur_open_defconfig"
DEVICE_CODENAME="gts7fewifi"
PROJECT_NAME="gts7xllite"
export PROJECT_NAME="${PROJECT_NAME}"

# ---- Version ----
LOCALVERSION_BASE="-qgki-Kokuban-Perica-DYF1"
VARIANT="${1:-resukisu}"
LOCALVERSION_SUFFIX="${2:-}"

case "$VARIANT" in
    resukisu|ReSuki|resuki)
        LOCALVERSION="${LOCALVERSION_BASE}-ReSuki"
        ;;
    lkm|LKM)
        LOCALVERSION="${LOCALVERSION_BASE}"
        ;;
    *)
        LOCALVERSION="${LOCALVERSION_BASE}-${VARIANT}"
        ;;
esac
[ -n "$LOCALVERSION_SUFFIX" ] && LOCALVERSION="${LOCALVERSION}${LOCALVERSION_SUFFIX}"

TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
ZIP_NAME="TabS7FE_Kernel-${VARIANT}-${TIMESTAMP}${LOCALVERSION_SUFFIX}.zip"

# ---- Toolchain paths ----
CLANG_BIN="${SCRIPT_DIR}/prebuilts-master/clang/host/linux-x86/clang-r416183b/bin"
CLANG="${CLANG_BIN}/clang"

BUILD_TOOLS_BIN="${SCRIPT_DIR}/prebuilts/build-tools/linux-x86/bin"
BUILD_TOOLS_PATH="${SCRIPT_DIR}/build/build-tools/path/linux-x86"
KERNEL_BUILD_TOOLS="${SCRIPT_DIR}/prebuilts/kernel-build-tools/linux-x86/bin"

TOOLCHAIN_WRAPPER="${SCRIPT_DIR}/toolchain/bin"
CROSS_COMPILE="${TOOLCHAIN_WRAPPER}/aarch64-linux-gnu-"

# --- PATH (toolchain wrapper first so clang finds cross-as) ---
export PATH="${TOOLCHAIN_WRAPPER}:${CLANG_BIN}:${BUILD_TOOLS_BIN}:${BUILD_TOOLS_PATH}:${KERNEL_BUILD_TOOLS}:${HOME}/.local/bin:${PATH}"

# ---- Environment (export so kbuild inherits them) ----
export ARCH=arm64

# Use LLVM=1 so the kernel Makefile treats CC=clang consistently
export LLVM=1
export CC="${CLANG}"

export AS="${TOOLCHAIN_WRAPPER}/aarch64-linux-gnu-as"
export LD=ld.lld
export AR=llvm-ar
export NM=llvm-nm
export OBJCOPY=llvm-objcopy
export OBJDUMP=llvm-objdump
export STRIP=llvm-strip

# bison needs explicit M4
export M4="${BUILD_TOOLS_BIN}/m4" 2>/dev/null || true

# ---- Build flags ----
KERNEL_MAKE_ENV="DTC_EXT=${SCRIPT_DIR}/tools/dtc CONFIG_BUILD_ARM64_DT_OVERLAY=y"

MAKE_ARGS="ARCH=arm64"
MAKE_ARGS+=" CROSS_COMPILE=${CROSS_COMPILE}"
MAKE_ARGS+=" LD=ld.lld AR=llvm-ar NM=llvm-nm"
MAKE_ARGS+=" OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip"
MAKE_ARGS+=" CLANG_TRIPLE=aarch64-linux-gnu-"
MAKE_ARGS+=" CONFIG_SECTION_MISMATCH_WARN_ONLY=y"
MAKE_ARGS+=" LOCALVERSION=${LOCALVERSION}"

# GNU Make 4.4+ breaks kernel 5.4; use local Make 4.3
MAKE="${HOME}/.local/bin/make"

OUT_DIR="${SCRIPT_DIR}/out"
CORES=$(nproc)

echo "=============================================="
echo " Kokuban Kernel Local Build"
echo "=============================================="
echo " Device:    ${DEVICE_CODENAME} (${PROJECT_NAME})"
echo " Defconfig: ${DEFCONFIG}"
echo " Variant:   ${VARIANT}"
echo " Version:   ${LOCALVERSION}"
echo " CC:        ${CLANG}"
echo " AS:        ${AS}"
echo " CROSS:     ${CROSS_COMPILE}"
echo " JOBS:      ${CORES}"
echo " OUT:       ${OUT_DIR}"
echo " Zip:       ${ZIP_NAME}"
echo "=============================================="

cd "${SCRIPT_DIR}"

# ---- Clean ----
rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}"

# ---- [1/4] defconfig ----
echo ""
echo "[1/4] Preparing defconfig..."
"${MAKE}" -j"${CORES}" -C "${SCRIPT_DIR}" O="${OUT_DIR}" \
    ${KERNEL_MAKE_ENV} \
    ${MAKE_ARGS} \
    "${DEFCONFIG}"

# ---- [2/4] build ----
echo ""
echo "[2/4] Building kernel..."
"${MAKE}" -j"${CORES}" -C "${SCRIPT_DIR}" O="${OUT_DIR}" \
    ${KERNEL_MAKE_ENV} \
    ${MAKE_ARGS}

# Copy Image to convenience location
cp "${OUT_DIR}/arch/arm64/boot/Image" "${SCRIPT_DIR}/arch/arm64/boot/Image" 2>/dev/null || true

echo ""
echo " ✓ Kernel built successfully"

# ---- [3/4] prepare AnyKernel3 ----
echo ""
echo "[3/4] Preparing AnyKernel3..."
AK3_DIR="${SCRIPT_DIR}/build/AnyKernel3"

rm -rf "${AK3_DIR}/Image" "${AK3_DIR}/dtb" "${AK3_DIR}/dtbo.img" "${AK3_DIR}/modules" 2>/dev/null || true

cp "${OUT_DIR}/arch/arm64/boot/Image" "${AK3_DIR}/" && echo "  ✓ Image" || { echo "  ✗ Image not found"; exit 1; }

find "${OUT_DIR}/arch/arm64/boot/dts" -name "*.dtb" -exec cp {} "${AK3_DIR}/dtb" \; 2>/dev/null && echo "  ✓ DTB" || true

if [ -f "${OUT_DIR}/arch/arm64/boot/dtbo.img" ]; then
    cp "${OUT_DIR}/arch/arm64/boot/dtbo.img" "${AK3_DIR}/" && echo "  ✓ DTBO"
fi

if ls "${OUT_DIR}"/*.ko 2>/dev/null | head -1 > /dev/null; then
    mkdir -p "${AK3_DIR}/modules"
    find "${OUT_DIR}" -name "*.ko" -not -path "*/vendor/*" -exec cp {} "${AK3_DIR}/modules/" \; 2>/dev/null
    echo "  ✓ Modules"
fi

sed -i "s/^kernel\.string=.*/kernel.string=Kokuban Kernel ${LOCALVERSION}/" "${AK3_DIR}/anykernel.sh"

# ---- [4/4] package ----
echo ""
echo "[4/4] Creating AnyKernel3 zip..."
( cd "${AK3_DIR}" && zip -r9 "${OUT_DIR}/${ZIP_NAME}" . -x '.git*' '*.gitignore' 'README*' '*placeholder' 2>&1 | tail -1 )

# ---- done ----
echo ""
echo "=============================================="
echo " BUILD SUCCESS"
echo "=============================================="
echo " Zip:     ${OUT_DIR}/${ZIP_NAME}"
ls -lh "${OUT_DIR}/${ZIP_NAME}"
echo ""
echo " Version: ${LOCALVERSION}"
echo ""
echo " --- localversion check ---"
strings "${OUT_DIR}/arch/arm64/boot/Image" 2>/dev/null | grep "Linux version" | head -1 || echo " (check Image)"
echo "=============================================="
