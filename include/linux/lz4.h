/* SPDX-License-Identifier: GPL-2.0 */
/*
 * LZ4 Kernel Interface - Bridge to NEON-accelerated LZ4 library
 *
 * This header bridges the kernel's <linux/lz4.h> include convention
 * to the new LZ4 v1.10.0 library with ARM64 NEON acceleration.
 */

#ifndef __LINUX_LZ4_H__
#define __LINUX_LZ4_H__

/* Include the core LZ4 library header (with lz4armv8 NEON support) */
#include "../../lib/lz4/lz4.h"

/* --- Compatibility defines for existing kernel consumers --- */

/* Workspace sizes for LZ4_compress_default / LZ4_compress_fast */
#define LZ4_MEM_COMPRESS	LZ4_STREAM_MINSIZE

/* Workspace size for LZ4_compress_HC */
#define LZ4HC_MEM_COMPRESS	LZ4_STREAMHC_MINSIZE

/* Old HC compression level names -> new names */
#define LZ4HC_MIN_CLEVEL	LZ4HC_CLEVEL_MIN
#define LZ4HC_DEFAULT_CLEVEL	LZ4HC_CLEVEL_DEFAULT
#define LZ4HC_MAX_CLEVEL		12	/* new library max is 12, old was 16 */

#endif /* __LINUX_LZ4_H__ */
