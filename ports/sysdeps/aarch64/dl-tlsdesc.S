/* Thread-local storage handling in the ELF dynamic linker.
   AArch64 version.
   Copyright (C) 2011-2012 Free Software Foundation, Inc.

   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, see
   <http://www.gnu.org/licenses/>.  */

#include <sysdep.h>
#include <tls.h>
#include "tlsdesc.h"

#define NSAVEDQREGPAIRS	16
#define SAVE_Q_REGISTERS				\
	stp	q0, q1,	[sp, #-32*NSAVEDQREGPAIRS]!;	\
	cfi_adjust_cfa_offset (32*NSAVEDQREGPAIRS);	\
	stp	 q2,  q3, [sp, #32*1];			\
	stp	 q4,  q5, [sp, #32*2];			\
	stp	 q6,  q7, [sp, #32*3];			\
	stp	 q8,  q9, [sp, #32*4];			\
	stp	q10, q11, [sp, #32*5];			\
	stp	q12, q13, [sp, #32*6];			\
	stp	q14, q15, [sp, #32*7];			\
	stp	q16, q17, [sp, #32*8];			\
	stp	q18, q19, [sp, #32*9];			\
	stp	q20, q21, [sp, #32*10];			\
	stp	q22, q23, [sp, #32*11];			\
	stp	q24, q25, [sp, #32*12];			\
	stp	q26, q27, [sp, #32*13];			\
	stp	q28, q29, [sp, #32*14];			\
	stp	q30, q31, [sp, #32*15];

#define RESTORE_Q_REGISTERS				\
	ldp	 q2,  q3, [sp, #32*1];			\
	ldp	 q4,  q5, [sp, #32*2];			\
	ldp	 q6,  q7, [sp, #32*3];			\
	ldp	 q8,  q9, [sp, #32*4];			\
	ldp	q10, q11, [sp, #32*5];			\
	ldp	q12, q13, [sp, #32*6];			\
	ldp	q14, q15, [sp, #32*7];			\
	ldp	q16, q17, [sp, #32*8];			\
	ldp	q18, q19, [sp, #32*9];			\
	ldp	q20, q21, [sp, #32*10];			\
	ldp	q22, q23, [sp, #32*11];			\
	ldp	q24, q25, [sp, #32*12];			\
	ldp	q26, q27, [sp, #32*13];			\
	ldp	q28, q29, [sp, #32*14];			\
	ldp	q30, q31, [sp, #32*15];			\
	ldp	 q0,  q1, [sp], #32*NSAVEDQREGPAIRS;	\
	cfi_adjust_cfa_offset (-32*NSAVEDQREGPAIRS);

	.text

	/* Compute the thread pointer offset for symbols in the static
	   TLS block. The offset is the same for all threads.
	   Prototype:
	   _dl_tlsdesc_return (tlsdesc *) ;
	 */
	.hidden _dl_tlsdesc_return
	.global	_dl_tlsdesc_return
	.type	_dl_tlsdesc_return,%function
	cfi_startproc
	.align 2
_dl_tlsdesc_return:
	ldr	x0, [x0, #8]
	RET
	cfi_endproc
	.size	_dl_tlsdesc_return, .-_dl_tlsdesc_return

	/* Handler for undefined weak TLS symbols.
	   Prototype:
	   _dl_tlsdesc_undefweak (tlsdesc *);

	   The second word of the descriptor contains the addend.
	   Return the addend minus the thread pointer. This ensures
	   that when the caller adds on the thread pointer it gets back
	   the addend.  */

	.hidden _dl_tlsdesc_undefweak
	.global	_dl_tlsdesc_undefweak
	.type	_dl_tlsdesc_undefweak,%function
	cfi_startproc
	.align  2
_dl_tlsdesc_undefweak:
	str	x1, [sp, #-16]!
	cfi_adjust_cfa_offset(16)
	ldr	x0, [x0, #8]
	mrs	x1, tpidr_el0
	sub	x0, x0, x1
	ldr	x1, [sp], #16
	cfi_adjust_cfa_offset(16)
	RET
	cfi_endproc
	.size	_dl_tlsdesc_undefweak, .-_dl_tlsdesc_undefweak

#ifdef SHARED
	/* Handler for dynamic TLS symbols.
	   Prototype:
	   _dl_tlsdesc_dynamic (tlsdesc *) ;

	   The second word of the descriptor points to a
	   tlsdesc_dynamic_arg structure.

	   Returns the offset between the thread pointer and the
	   object referenced by the argument.

	   ptrdiff_t
	   __attribute__ ((__regparm__ (1)))
	   _dl_tlsdesc_dynamic (struct tlsdesc *tdp)
	   {
	     struct tlsdesc_dynamic_arg *td = tdp->arg;
	     dtv_t *dtv = *(dtv_t **)((char *)__thread_pointer + DTV_OFFSET);
	     if (__builtin_expect (td->gen_count <= dtv[0].counter
		&& (dtv[td->tlsinfo.ti_module].pointer.val
		    != TLS_DTV_UNALLOCATED),
		1))
	       return dtv[td->tlsinfo.ti_module].pointer.val
		+ td->tlsinfo.ti_offset
		- __thread_pointer;

	     return ___tls_get_addr (&td->tlsinfo) - __thread_pointer;
	   }
	 */

	.hidden _dl_tlsdesc_dynamic
	.global	_dl_tlsdesc_dynamic
	.type	_dl_tlsdesc_dynamic,%function
	cfi_startproc
	.align 2
_dl_tlsdesc_dynamic:
# define NSAVEXREGPAIRS 2
	stp	x29, x30, [sp,#-(32+16*NSAVEXREGPAIRS)]!
	cfi_adjust_cfa_offset (32+16*NSAVEXREGPAIRS)
	mov	x29, sp

	/* Save just enough registers to support fast path, if we fall
	   into slow path we will save additional registers.  */

	stp	x1,  x2, [sp, #32+16*0]
	stp	x3,  x4, [sp, #32+16*1]

	mrs	x4, tpidr_el0
	ldr	x1, [x0,#8]
	ldr	x0, [x4]
	ldr	x3, [x1,#16]
	ldr	x2, [x0]
	cmp	x3, x2
	b.hi	2f
	ldr	x2, [x1]
	add	x0, x0, x2, lsl #4
	ldr	x0, [x0]
	cmn	x0, #0x1
	b.eq	2f
	ldr	x1, [x1,#8]
	add	x0, x0, x1
	sub	x0, x0, x4
1:
	ldp	 x1,  x2, [sp, #32+16*0]
	ldp	 x3,  x4, [sp, #32+16*1]

	ldp	x29, x30, [sp], #(32+16*NSAVEXREGPAIRS)
	cfi_adjust_cfa_offset (32+16*NSAVEXREGPAIRS)
# undef NSAVEXREGPAIRS
	RET
2:
	/* This is the slow path. We need to call __tls_get_addr() which
	   means we need to save and restore all the register that the
	   callee will trash.  */

	/* Save the remaining registers that we must treat as caller save.  */
# define NSAVEXREGPAIRS 7
	stp	 x5,  x6, [sp, #-16*NSAVEXREGPAIRS]!
	cfi_adjust_cfa_offset (16*NSAVEXREGPAIRS)
	stp	 x7,  x8, [sp, #16*1]
	stp	 x9, x10, [sp, #16*2]
	stp	x11, x12, [sp, #16*3]
	stp	x13, x14, [sp, #16*4]
	stp	x15, x16, [sp, #16*5]
	stp	x17, x18, [sp, #16*6]

	SAVE_Q_REGISTERS

	mov	x0, x1
	bl	__tls_get_addr

	mrs	x1, tpidr_el0
	sub	x0, x0, x1

	RESTORE_Q_REGISTERS

	ldp	 x7,  x8, [sp, #16*1]
	ldp	 x9, x10, [sp, #16*2]
	ldp	x11, x12, [sp, #16*3]
	ldp	x13, x14, [sp, #16*4]
	ldp	x15, x16, [sp, #16*5]
	ldp	x17, x18, [sp, #16*6]
	ldp	 x5,  x6, [sp], #16*NSAVEXREGPAIRS
	cfi_adjust_cfa_offset (-16*NSAVEXREGPAIRS)
	b	1b
	cfi_endproc
	.size	_dl_tlsdesc_dynamic, .-_dl_tlsdesc_dynamic
# undef NSAVEXREGPAIRS
#endif

	/* This function is a wrapper for a lazy resolver for TLS_DESC
	   RELA relocations.
	   When the actual resolver returns, it will have adjusted the
	   TLS descriptor such that we can tail-call it for it to return
	   the TP offset of the symbol.  */

	.hidden _dl_tlsdesc_resolve_rela
	.global	_dl_tlsdesc_resolve_rela
	.type	_dl_tlsdesc_resolve_rela,%function
	cfi_startproc
	.align 2
_dl_tlsdesc_resolve_rela:
#define	NSAVEXREGPAIRS 9
	stp	x29, x30, [sp, #-(32+16*NSAVEXREGPAIRS)]!
	cfi_adjust_cfa_offset (32+16*NSAVEXREGPAIRS)
	mov	x29, sp
	stp	 x1,  x4, [sp, #32+16*0]
	stp	 x5,  x6, [sp, #32+16*1]
	stp	 x7,  x8, [sp, #32+16*2]
	stp	 x9, x10, [sp, #32+16*3]
	stp	x11, x12, [sp, #32+16*4]
	stp	x13, x14, [sp, #32+16*5]
	stp	x15, x16, [sp, #32+16*6]
	stp	x17, x18, [sp, #32+16*7]
	str	x0,       [sp, #32+16*8]

	SAVE_Q_REGISTERS

	ldr	x1, [x3, #8]
	bl	_dl_tlsdesc_resolve_rela_fixup

	RESTORE_Q_REGISTERS

	ldr	x0, [sp, #32+16*8]
	ldr	x1, [x0]
	blr	x1

	ldp	 x1,  x4, [sp, #32+16*0]
	ldp	 x5,  x6, [sp, #32+16*1]
	ldp	 x7,  x8, [sp, #32+16*2]
	ldp	 x9, x10, [sp, #32+16*3]
	ldp	x11, x12, [sp, #32+16*4]
	ldp	x13, x14, [sp, #32+16*5]
	ldp	x15, x16, [sp, #32+16*6]
	ldp	x17, x18, [sp, #32+16*7]
	ldp	x29, x30, [sp], #(32+16*NSAVEXREGPAIRS)
	cfi_adjust_cfa_offset (-32+16*NSAVEXREGPAIRS)
	ldp	x2, x3, [sp], #16
	cfi_adjust_cfa_offset (-16)
	RET
#undef NSAVEXREGPAIRS
	cfi_endproc
	.size	_dl_tlsdesc_resolve_rela, .-_dl_tlsdesc_resolve_rela

	/* This function is a placeholder for lazy resolving of TLS
	relocations.  Once some thread starts resolving a TLS
	relocation, it sets up the TLS descriptor to use this
	resolver, such that other threads that would attempt to
	resolve it concurrently may skip the call to the original lazy
	resolver and go straight to a condition wait.

	When the actual resolver returns, it will have adjusted the
	TLS descriptor such that we can tail-call it for it to return
	the TP offset of the symbol.  */

	.hidden _dl_tlsdesc_resolve_hold
	.global	_dl_tlsdesc_resolve_hold
	.type	_dl_tlsdesc_resolve_hold,%function
	cfi_startproc
	.align 2
_dl_tlsdesc_resolve_hold:
#define	NSAVEXREGPAIRS 10
1:
	stp	x29, x30, [sp, #-(32+16*NSAVEXREGPAIRS)]!
	cfi_adjust_cfa_offset (32+16*NSAVEXREGPAIRS)
	mov	x29, sp
	stp	 x1,  x2, [sp, #32+16*0]
	stp	 x3,  x4, [sp, #32+16*1]
	stp	 x5,  x6, [sp, #32+16*2]
	stp	 x7,  x8, [sp, #32+16*3]
	stp	 x9, x10, [sp, #32+16*4]
	stp	x11, x12, [sp, #32+16*5]
	stp	x13, x14, [sp, #32+16*6]
	stp	x15, x16, [sp, #32+16*7]
	stp	x17, x18, [sp, #32+16*8]
	str	x0,       [sp, #32+16*9]

	SAVE_Q_REGISTERS

	adr	x1, 1b
	bl	_dl_tlsdesc_resolve_hold_fixup

	RESTORE_Q_REGISTERS

	ldr	x0, [sp, #32+16*9]
	ldr	x1, [x0]
	blr	x1

	ldp	 x1,  x2, [sp, #32+16*0]
	ldp	 x3,  x4, [sp, #32+16*1]
	ldp	 x5,  x6, [sp, #32+16*2]
	ldp	 x7,  x8, [sp, #32+16*3]
	ldp	 x9, x10, [sp, #32+16*4]
	ldp	x11, x12, [sp, #32+16*5]
	ldp	x13, x14, [sp, #32+16*6]
	ldp	x15, x16, [sp, #32+16*7]
	ldp	x17, x18, [sp, #32+16*8]
	ldp	x29, x30, [sp], #(32+16*NSAVEXREGPAIRS)
	cfi_adjust_cfa_offset (-32+16*NSAVEXREGPAIRS)
	RET
	cfi_endproc
	.size	_dl_tlsdesc_resolve_hold, .-_dl_tlsdesc_resolve_hold
#undef NSAVEXREGPAIRS
