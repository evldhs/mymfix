; Hack that catches gemdos (trap #1) calls
; and replaces malloc() and Mxalloc() with 
; memory pointers to a predefined buffer
;
; Originally by ggn
; Fixes by Nerve and Evil
;
; October 11, 2026


sndh_bufsize:	equ	100000+64		;Use memcheck tool to see how much memory the tune Malloc()
						;Then add 64 or so bytes for address alignments

		section	text

sndh_init:
		move.l  $84.w,sndh_old_trap1	;Setup trap 1 to catch malloc() calls
		move.l  #sndh_trap1,$84.w

		moveq	#1,d0
		move.l	sndh_addr,a0
		jsr	(a0)

		move.l	sndh_old_trap1(pc),$84.w

		rts


sndh_trap1:
		move.l	sp,a0
		add.l	sndh_cpu_trap_offset,a0	;that's either 6 or 8 (68000/68030)
		cmp.w	#$48,(a0)		;malloc?
		beq.s	.do_malloc
		cmp.w	#$44,(a0)		;Mxalloc(size.l, mode.w)?
		bne.s	.no_malloc
.do_malloc:	
		move.l	2(a0),a0		;size.l for Malloc and Mxalloc; Mxalloc mode.w follows
		move.l	sndh_malloc_ptr(pc),d0	;the pointer to memory we're going to give
		add.l	#2,d0			;even address
		and.l	#-2,d0			;
		lea	0(a0,d0.l),a0		;advance our pointer as many bytes as those reserved
		move.l	a0,sndh_malloc_ptr	;save the pointer for next malloc
		rte				;and go back to program

.no_malloc:
		;cmp.w	#$49,(a0)		;mfree?
		;bne.s	sndh_no_mfree		;only do this if running from tos, just rte in the demo
		rte				;do nothing


sndh_no_mfree:
sndh_old_trap1	equ *+2
		jmp	0			;jump to O/S' vector

sndh_malloc_ptr:
		dc.l	sndh_mallocbuf

sndh_cpu_trap_offset:
		dc.l	6			;68000

		endc

		section	bss

sndh_mallocbuf:	ds.b	sndh_bufsize


