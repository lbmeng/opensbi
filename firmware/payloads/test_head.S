/*
 * SPDX-License-Identifier: BSD-2-Clause
 *
 * Copyright (c) 2019 Western Digital Corporation or its affiliates.
 *
 * Authors:
 *   Anup Patel <anup.patel@wdc.com>
 */

#include <sbi/riscv_encoding.h>
#define __ASM_STR(x)	x

#if __riscv_xlen == 64
#define __REG_SEL(a, b)		__ASM_STR(a)
#define RISCV_PTR		.dword
#elif __riscv_xlen == 32
#define __REG_SEL(a, b)		__ASM_STR(b)
#define RISCV_PTR		.word
#else
#error "Unexpected __riscv_xlen"
#endif

#define REG_L		__REG_SEL(ld, lw)
#define REG_S		__REG_SEL(sd, sw)

#define PTE_SIZE	8

	.align 3
	.section .entry, "ax", %progbits
	.globl _start
_start:
	/* Pick one hart to run the main boot sequence */
	la	a3, _hart_lottery
	li	a2, 1
	amoadd.w a3, a2, (a3)
	bnez	a3, _start_hang

	/* Save a0 and a1 */
	la	a3, _boot_a0
	REG_S	a0, 0(a3)
	la	a3, _boot_a1
	REG_S	a1, 0(a3)

	/* Zero-out BSS */
	la	a4, _bss_start
	la	a5, _bss_end
_bss_zero:
	REG_S	zero, (a4)
	add	a4, a4, __SIZEOF_POINTER__
	blt	a4, a5, _bss_zero

_start_warm:
	/* Disable and clear all interrupts */
	csrw	CSR_SIE, zero
	csrw	CSR_SIP, zero

	/* Setup exception vectors */
	li	a0, 0xffffffff80200000UL
	la	t5, _start
	sub	s3, a0, t5
	la	a2, vec
	add	a3, a2, s3
	csrw	CSR_STVEC, a3

	/*
	 * Setup PTE for the following mapping:
	 * 0xffffffff80000000 (V) -> 0x80000000 (P)
	 * 0xffffffffffffffff (V) -> 0xffffffff (P)
	 */
	li	a0, 0x80000000
	la	t0, pte

	li	t1, 0xffffffff80000000UL
	srli	t2, t1, 30
	andi	t2, t2, 0x1ff
	li	a2, PTE_SIZE
	mulw	t2, t2, a2
	add	t3, t0, t2

	mv	t5, a0

	srli	a0, a0, 30
	slli	a0, a0, 28
	li	t4, 0xcf
	or	t4, a0, t4
	sd	t4, (t3)

	addi	t3, t3, PTE_SIZE
	li	t1, 1 << 30	/* 1GiB size */
	add	a0, t5, t1
	srli	a0, a0, 30
	slli	a0, a0, 28
	li	t4, 0xcf
	or	t4, a0, t4
	sd	t4, (t3)

	/* Enable sv39 mmu */
	srli	t0, t0, 12
	li	a2, (8ULL << 60)
	or	t0, t0, a2
	sfence.vma
	csrw	satp, t0

	.align 2
vec:
	/* Setup stack */
	la	a3, _payload_end
	li	a4, 0x2000
	add	sp, a3, a4

	/* Jump to C main */
	la	a3, _boot_a0
	REG_L	a0, 0(a3)
	la	a3, _boot_a1
	REG_L	a1, 0(a3)
	call	test_main

	/* We don't expect to reach here hence just hang */
	j	_start_hang

	.align 3
	.section .entry, "ax", %progbits
	.globl _start_hang
_start_hang:
	wfi
	j	_start_hang

	.align	3
	.section .entry, "ax", %progbits
_hart_lottery:
	RISCV_PTR	0
_boot_a0:
	RISCV_PTR	0
_boot_a1:
	RISCV_PTR	0

	.data
	.align 12
pte:
	.space	0x1000, 0
