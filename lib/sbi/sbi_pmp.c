/*
 * SPDX-License-Identifier: BSD-2-Clause
 *
 * Copyright (c) 2020 Bin Meng <bmeng.cn@gmail.com>
 */

#include <sbi/sbi_ecall_interface.h>
#include <sbi/sbi_platform.h>

struct pmp_fw_prot_desc {
	unsigned long base;
	unsigned long size;
};

static int sbi_ecall_pmp_handler(struct sbi_scratch *scratch,
				 unsigned long extid, unsigned long funcid,
				 unsigned long *args, unsigned long *out_val,
				 struct sbi_trap_info *out_trap)
{
	const struct sbi_platform *plat = sbi_platform_ptr(scratch);
	struct pmp_fw_prot_desc *desc = (struct pmp_fw_prot_desc *)args[0];
	int ret = SBI_OK;

	if (!sbi_platform_has_pmp(plat))
		return SBI_ENOTSUPP;

	switch (funcid) {
	case SBI_EXT_PMP_GET_FW_PROT_DESC_SIZE:
		/* Only one memory region is protected */
		*out_val = sizeof(struct pmp_fw_prot_desc);
		break;
	case SBI_EXT_PMP_GET_FW_PROT_DESC:
		desc->base = scratch->fw_start;
		desc->size = scratch->fw_size;
		*out_val = 0;
		break;
	default:
		ret = SBI_ENOTSUPP;
	}

	return ret;
}

struct sbi_ecall_extension ecall_pmp = {
	.extid_start = SBI_EXT_PMP,
	.extid_end = SBI_EXT_PMP,
	.handle = sbi_ecall_pmp_handler,
};
