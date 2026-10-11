; Check how much RAM maxYMiser allocates for PCM sounds
; Use this as base for the faked Malloc() hack
; 
; Build with Devpac or vasm
;
; October 11, 2026
; ae@dhs.nu


start:
		move.l	4(sp),a5			;Store basepage addr

		move.l	a5,d0				;Basepage address
		add.l	#129,d0				;Offset to commandline
		move.l	d0,sndh_filename

		move.l	$0c(a5),d0			;Text
		add.l	$14(a5),d0			;Data
		add.l	$1c(a5),d0			;BSS
		add.l	#$100,d0			;Basepage
		add.l	#$1000,d0			;Stack
		move.l	a5,d1				;Basepage
		add.l	d0,d1				;End
		and.l	#-2,d1				;Even
		move.l	d1,sp				;Stackaddr

		move.l	d0,-(sp)			;mshrink()
		move.l	a5,-(sp)
		move.w	d0,-(sp)
		move.w	#$4a,-(sp)
		trap	#1
		lea	12(sp),sp

		lea	titlestring(pc),a0
		bsr	cconws

		bsr	load_sndh_file

		pea	do_test
		move.w	#$26,-(sp)			;supexec()
		trap	#14
		addq.l	#6,sp

		bsr	print_results

exit:
		lea	endstring(pc),a0
		bsr	cconws
		bsr	crawcin

		clr.w	-(sp)				;pterm0()
		trap	#1

do_test:
		moveq	#-1,d0
		bsr	malloc
		move.l	d0,before

		moveq	#1,d0
		move.l	sndh_address(pc),a0
		jsr	(a0)

		moveq	#-1,d0
		bsr	malloc
		move.l	d0,after

		move.l	before(pc),d1
		sub.l	d0,d1
		move.l	d1,diff		

		move.l	sndh_address(pc),a0
		jsr	(a0)

		rts


print_results:
;-------------- Print before
		lea	beforestring,a0
		bsr	cconws

		move.l	before,d0
		lea	numstring+1,a0
		lea	ascii,a1
		move.l	#$0000000f,d2
		moveq	#8-1,d7
.beforeloop:
		move.l	d0,d1
		lsl.l	#4,d0
		rol.l	#4,d1
		and.l	d2,d1
		move.b	(a1,d1.w),(a0)+

		dbra	d7,.beforeloop

		lea	numstring,a0
		bsr	cconws


;-------------- Print After
		lea	afterstring,a0
		bsr	cconws

		move.l	after,d0
		lea	numstring+1,a0
		lea	ascii,a1
		move.l	#$0000000f,d2
		moveq	#8-1,d7
.afterloop:
		move.l	d0,d1
		lsl.l	#4,d0
		rol.l	#4,d1
		and.l	d2,d1
		move.b	(a1,d1.w),(a0)+

		dbra	d7,.afterloop

		lea	numstring,a0
		bsr	cconws

;-------------- Print Diff
		lea	diffstring,a0
		bsr	cconws

		move.l	diff,d0
		lea	numstring+1,a0
		lea	ascii,a1
		move.l	#$0000000f,d2
		moveq	#8-1,d7
.diffloop:
		move.l	d0,d1
		lsl.l	#4,d0
		rol.l	#4,d1
		and.l	d2,d1
		move.b	(a1,d1.w),(a0)+

		dbra	d7,.diffloop

		lea	numstring,a0
		bsr	cconws
		rts


load_sndh_file:
		lea	loadingstring(pc),a0
		bsr	cconws

		move.l	sndh_filename(pc),a0
		bsr	cconws

		lea	crlf(pc),a0
		bsr	cconws

		move.l	sndh_filename(pc),a0
		bsr	fopen

		tst.l	d0
		bpl.s	.file_found
		lea	nofilestring(pc),a0
		bsr	cconws
		bra	exit

.file_found:	move.w	d0,fh
		moveq	#2,d1
		moveq	#0,d2
		bsr	fseek

		tst.l	d0
		bpl.s	.sizeok
		lea	filemptystring(pc),a0
		bsr	cconws
		bra	exit

.sizeok:	move.l	d0,sndh_size
		bsr	malloc

		tst.l	d0
		bne.s	.have_memory
		lea	nomemstring(pc),a0
		bsr	cconws
		bra	exit

.have_memory:	move.l	d0,sndh_address

		move.w	fh(pc),d0
		moveq	#0,d1
		moveq	#0,d2
		bsr	fseek

		move.w	fh(pc),d0
		move.l	sndh_address(pc),a0
		move.l	sndh_size(pc),d1
		bsr	fread

		move.w	fh(pc),d0
		bsr	fclose
		rts

malloc:
;in: d0.l amount
		move.l	d0,-(sp)
		move.w	#$48,-(sp)			;Malloc()
		trap	#1
		addq.l	#6,sp
		rts

cconws:
;in: a0.l address to null terminated string
		move.l	a0,-(sp)			;cconws()
		move.w	#9,-(sp)
		trap	#1
		addq.l	#6,sp
		rts

fseek:
;in:
;    d0.w file handle
;    d1.w mode (0=offset from start, 1=offset from current, 2=offset from end)
;    d2.l offset (bytes)
		move.w	d1,-(sp)			;Fseek()
		move.w	d0,-(sp)
		move.l	d2,-(sp)
		move.w	#$42,-(sp)
		trap	#1
		lea	10(sp),sp
		rts

fopen:
;in: a0.l filename address
		clr.w	-(sp)				;Fopen()
		move.l	a0,-(sp)
		move.w	#$3d,-(sp)
		trap	#1
		addq.l	#8,sp
		rts

fread:
;in: d0.w file handle
;    d1.l file size
;    a0.l address to buffer
		move.l	a0,-(sp)			;Fread()
		move.l	d1,-(sp)
		move.w	d0,-(sp)
		move.w	#$3f,-(sp)
		trap	#1
		lea	12(sp),sp
		rts

fclose:
;in: d0.w file handle
		move.w	d0,-(sp)			;Fclose()
		move.w	#$3e,-(sp)
		trap	#1
		addq.l	#4,sp
		rts

crawcin:
;out: d0.b Key pressed
		move.w	#7,-(sp)			;Crawcin()
		trap	#1
		addq.l	#2,sp
		rts

titlestring:	dc.b	"Measure maxYMiser Malloc() size v1.0",13,10,13,10,0
endstring:	dc.b	13,10,"Press any key to exit",13,10,0
loadingstring:	dc.b	"Loading: ",0
nomemstring:	dc.b	"Not enough memory, exiting",13,10,13,10,0
nofilestring:	dc.b	"File not found, exiting",13,10,13,10,0
filemptystring:	dc.b	"File empty, exiting",13,10,13,10,0
crlf_x2:	dc.b	13,10
crlf:		dc.b	13,10,0

beforestring:	dc.b	"Free mem before: ",0
afterstring:	dc.b	"Free mem after : ",0
diffstring:	dc.b	"Malloced size  : ",0
numstring:	dc.b	"$00000000",13,10,0
		even
ascii:		dc.b	"0123456789ABCDEF"
		even
before:		dc.l	0
after:		dc.l	0
diff:		dc.l	0
fh:		dc.w	0
sndh_filename:	dc.l	0
sndh_address:	dc.l	0
sndh_size:	dc.l	0