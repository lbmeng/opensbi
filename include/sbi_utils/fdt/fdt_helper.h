// SPDX-License-Identifier: BSD-2-Clause
/*
 * fdt_helper.h - Flat Device Tree manipulation helper routines
 * Implement helper routines on top of libfdt for OpenSBI usage
 *
 * Copyright (C) 2020 Bin Meng <bmeng.cn@gmail.com>
 */

#ifndef __FDT_HELPER_H__
#define __FDT_HELPER_H__

/**
 * Fix up the CPU node in the device tree
 *
 * This routine updates the "status" property of a CPU node in the device tree
 * to "disabled" if that hart is in disabled state in OpenSBI.
 *
 * It is recommended that platform codes call this helper in their final_init()
 *
 * @param fdt: device tree blob
 */
void fdt_cpu_fixup(void *fdt);

/**
 * Fix up the PLIC node in the device tree
 *
 * This routine updates the "interrupt-extended" property of the PLIC node in
 * the device tree to hide the M-mode external interrupt from CPUs.
 *
 * It is recommended that platform codes call this helper in their final_init()
 *
 * @param fdt: device tree blob
 * @param compat: PLIC node compatible string
 */
void fdt_plic_fixup(void *fdt, const char *compat);

/**
 * Fix up the reserved memory node in the device tree
 *
 * This routine inserts a child node of the reserved memory node in the device
 * tree that describes the protected memory region done by OpenSBI via PMP.
 *
 * It is recommended that platform codes call this helper in their final_init()
 *
 * @param fdt: device tree blob
 * @return zero on success and -ve on failure
 */
int fdt_reserved_memory_fixup(void *fdt);

/**
 * General device tree fix-up
 *
 * This routine do all required device tree fix-ups for a typical platform.
 * It fixes up the PLIC node and the reserved memory node in the device tree
 * by calling the corresponding helper routines to accomplish the task.
 *
 * It is recommended that platform codes call this helper in their final_init()
 *
 * @param fdt: device tree blob
 */
void fdt_fixups(void *fdt);

#endif /* __FDT_HELPER_H__ */
