[BITS 32]
[ORG 0x10000]

;;BASIC FORTH LIKE MACROS------------------------------
%macro _DUP 0
	lea	ESI, [ESI-4]		;stack pointer down one cell
	mov [ESI], EAX			;Copy TOS to NOS
%endmacro

%macro DROP 0
	lodsd					;mov EAX, [ESI], add ESI,4 
%endmacro

%macro next	1
	dec	ecx
	jnz	%1
%endmacro

code:	;we don't have a code and data section this is a flat binary
MULTIBOOT_PAGE_ALIGN   equ 1<<0
MULTIBOOT_MEMORY_INFO  equ 1<<1
MULTIBOOT_AOUT_KLUDGE  equ 1<<16

MULTIBOOT_HEADER_MAGIC equ 0x1BADB002
MULTIBOOT_HEADER_FLAGS equ MULTIBOOT_PAGE_ALIGN | MULTIBOOT_MEMORY_INFO | MULTIBOOT_AOUT_KLUDGE
CHECKSUM               equ -(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS)

; The Multiboot header
   align 4
mboot:
   dd MULTIBOOT_HEADER_MAGIC
   dd MULTIBOOT_HEADER_FLAGS
   dd CHECKSUM
   dd mboot ; these are PHYSICAL addresses
   dd code  ; start of kernel 
   dd edata ; end of kernel .data section
   dd end   ; end of kernel BSS
   dd start ; kernel entry point (initial E
;;----------------main loop--------------------------	
start:
abort:
	mov esi, 0xa0000		;set data stack
	mov esp, 0x9f800		;set return stack
	mov ebx, 0xB8000
	mov	dword [here],dictionary
	call clr
	mov edx,keys
	mov	[board],edx
	_DUP
	mov	eax,forth0
	call	hdot
	_DUP
	mov	eax,dictionary
	call	hdot
	_DUP
preaccept:
	_DUP
	xor	eax,eax
	mov	dword [chars],0x0
accept:
	call KEY
	cmp	al,0x06	;temporary backspace
	jne	.ne
	sub	ebx,[chars]
	sub ebx,[chars]
	;should add stuff here to do
	DROP
	DROP
	jmp	preaccept
	;cmp		al,'.'
	;jne		.ne
	;	call dots
.ne		
	cmp	al,5
	jae	accept1		;(packed space)
		push	eax
		mov	ecx,[cex]
		cmp	dword [chars],0x0
		jnz	.else
		DROP
		mov	ecx,nop1
		jmp	.af
.else:	mov	eax,' '
		call emit
.af:	call ecx	;ex_s old choice
		_DUP
		pop	eax
		cmp	al,0
			jz	.bf
		mov	ecx,[packs-4+eax*4]
		mov	[cpack],ecx
		mov	ecx,[ex_s-4+eax*4]
		mov	[cex],ecx
		mov	cl,[ccol-1+eax]
		mov	[colour],cl
.bf		DROP
		jmp preaccept
accept1:
	_DUP
	call emit
	call [cpack]
	inc	dword [chars]
	DROP
	jmp accept
	jmp	$					;loop forever (v.important)
here	dd	dictionary	
packs	dd	pack, numpack, pack, pack	
ex_s		dd	ex, nop0,	compile, define
ccol	db	0x07, 0x08, 0x06, 0x05
cex		dd	ex
cpack	dd	pack
chars dd 0x0
;;-----nops---
nop1:	DROP
nop0:	ret	
;;---------------------Basic Words---------------------
keys	db	0x0, 0x1B,'1','2','3','4','5','6','7','8','9','0','-','=',0x6 	; null,ESC,BKSP
		db	0x0,'q','w','e','r','t','y','u','i','o','p','[',']',0			; tab,cr 
		db	0x0,'a','s','d','f','g','h','j','k','l',';',0,' '
		db	0x0,' ','z','x','c','v','b','n','m',',','.','/',0				; lshft,rshft
		db	'*',0x0,0x0,0x0,1,2,3,4							; alt,space
shift	db	0x0, 0x1B,'!','@','£','$','%','^','&','*','(',')','_','+',0 	; null,ESC,BKSP
		db	0x0,'Q','W','E','R','T','Y','U','I','O','P','{','}',0			; tab,cr 
		db	0x0,'A','S','D','F','G','H','J','K','L',':','"','|'
		db	0x0,'~','Z','X','C','V','B','N','M','<','>','?',0				; lshft,rshft
		db	'*',0x0,' ',0x0,1,2,3,4										; alt,space, ,f1,f2,f3
board	dd	keys
colour	db 0x07	; grey
ctrl	db 0x0
KEY:	_DUP	
		mov	edx,[board]
		xor		eax,eax		;clear eax
	 .loop:		;call pause - switch to other stuff while we
				;wait for a key press
			in		al, 0x64	;check if key press waiting
			test	al, 1
			jz		.loop
		in		al, 0x60	;get waiting key
		;_DUP
		;call hdot
		cmp		al, 0xAA	;l.Shft up
		jne		.kb1
			mov	EDX,keys
			jmp .loop	
.kb1:	cmp		al,	0xB6	;r.shift up
		jne		.kb2
			mov EDX,keys
			jmp .loop
.kb2:	cmp		al, 0x2A	;l.Shft down
		jne		.kb3
			mov	EDX,shift
			jmp .loop	
.kb3:	cmp		al,	0x36	;r.shift down
		jne		.kb4
			mov EDX,shift
			jmp .loop
.kb4	cmp		al, 0x1d	;l.ctrl down
		jne		.kb5
			mov	byte [ctrl],0x1
			jmp	.loop
.kb5	cmp		al, 0x9D	;l.ctrl	up
		jne		.kbspecnd
			mov	byte [ctrl],0x0
			jmp	.loop
.kbspecnd	cmp		al,	0x3f		;ignore key ups and after f4
		jnc		.loop
		
		mov		al,[edx+eax]
		mov		[board],edx
		ret		;return traslated key on stack
clr:	mov ebx,0xB8000
		mov	ecx,0x7d0
.loop	mov	word [ebx-2+ecx*2],0x0b20
		next .loop
		ret
emit:	mov	ah,[colour]
		mov	[ebx],ax
		DROP
space:	add ebx,2
		ret
plus:	add [esi],eax	;add tos to nos
		DROP
		ret
semi:	mov	edx,[here]
		mov	byte [edx],0xC3	;ret opcode
		inc	dword [here]
		ret
		
hdigits	db	'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'
hdot:	mov	ecx,8		;loop over the 8 hex digits in a cell
.loop:	rol	eax, 4
		_DUP
		and	eax,0x0F
		mov	al,[hdigits + eax]
		call	emit
		next .loop
		;DROP
		mov	eax,' '
		call emit
		ret
numpack:	;packs a hex digit - ignores any keys that are not hex
		cmp	al,'0'
		jb	.end
		cmp	al,'9'
		ja	.let
		;'0'<=al<='9'
		sub	al,'0'
		jmp	.pree
.let	cmp	al,'a'
		jb	.end
		cmp	al,'f'
		ja	.end
		sub	al,('a'-0xa)
.pree	shl	dword [esi],4
		add	[esi],al
.end	ret		
dots:	push	ecx
		push	esi
		push	eax
		mov		ecx, 0xa0000
		sub		ecx, esi
		jz .end
		shr		ecx,2
.loop	push	ecx
		call	hdot
		pop		ecx
		next	.loop
.end	pop		eax
		pop		esi
		pop		ecx
		ret
execute: ;(n -- )
		;_DUP
		;mov	eax,[-4+edi*4]
		and	al,0xF0
		add al,0x01
		call find	;finding macros
		jnz	.fort
			jmp .gogo
.fort	and al,0xF0
		call find
		jnz	abort
.gogo	DROP
		jmp	[forth2+ecx*4]
ignore:	DROP ;(n -- )
		pop edi
		pop edi
nul2:	ret
load:	push edi
		shl	eax, 8 ; not 10 - as we are doing it in 32bit words
		mov	edi, eax
		DROP
inter:	mov	edx, [edi * 4]
		inc edi
		and edx,0xf
		_DUP
		mov	eax,[-4+edi*4]
		call [spaces + edx * 4]
		jmp inter
spaces:	dd	ignore, execute, imnum, def1
		dd comp1, nul2, nul2, compmacr
		dd nul2, nul2, nul2, nul2
		dd nul2, nul2, nul2, nul2
ex:		shl	eax,4
		and al,0xF0
		add al,0x01
		call find	;finding macros
		jnz	.fort
			jmp .gogo
.fort	and al,0xF0
		call find
		jnz	abort
.gogo	DROP
		jmp	[forth2+ecx*4]
find:	mov ecx,[forths]
		push edi		;save edi state
		lea	edi,[forth0-4+ecx*4]
		std				; set direction to search backward through the dictionary
		repne	scasd
		cld
		pop	edi
		ret
ibits:	db	0x28
pack:	and	al,0x7F		;this implementation is very fragile - do not type more than 4 characters
		shl	dword [ESI],7
		xor	[ESI],al
		sub byte [ibits],7
		ret
imnum:	and al,0xF0
		shr eax,4
		ret
; this is from typing
compile:shl	eax,4
comp1:	and al,0xF0
		add al,0x01
		call find	;finding macros
		jnz	.fort
			DROP
			jmp	[forth2+ecx*4]
.fort	and al,0xF0
		call find
		jnz	abort
comp2:	mov	eax,[forth2+ecx*4]
		mov	edx,[here]
		mov	byte [edx],0xE8	; call
		add	edx,5
		sub	eax,edx		;since 0xE8 is a relative call
		mov	[edx - 4], eax
		mov	[here],edx
		DROP
		ret
compmacr:	and al,0xF0
			add al,0x01
			call find
			jnz	abort
			jmp comp2
comma:	mov	edx,[here]
		mov	[edx],eax
		add	edx,4
		mov	[here],edx
		DROP
		ret
cdup:	mov edx,[here]
		mov	dword [edx],0x89fc768d
		mov	byte [edx+4],0x06
		add	edx,5
		mov	[here],edx
		ret
;;----editor--------------------
xy	dd	0x0
blk	dd	0x48
eleft:	dec	dword [xy]
		ret
eright:	inc	dword [xy]
		ret
eup:	sub dword [xy],0xc
		ret
edown:	add dword [xy],0xc
		ret
redw:	mov	eax,0x3
		jmp tins
grew:	mov eax,0x4
		jmp tins
whiw:	mov eax,0x9
		jmp tins
cyaw:	mov eax,0x7
		jmp tins
magw:	mov eax,0xc
		jmp tins
yelw:	mov	eax,0x1		
tins:	_DUP
		xor eax,eax
.loop	call	KEY
		cmp	al,0
		jz	.end
		call	pack
		DROP
		jmp	.loop
.end	;move stuff from stack and gogo dance
		DROP
		push	edi
		shl	eax,4
		add	eax,[esi]	;we will have the word type here at NOS
		mov	edi,[blk]
		shl	edi,8
		add edi,[xy]
		mov	[edi*4],eax
		pop	edi
		DROP
		inc	dword [xy]
		ret
numbnow: mov eax,0x2
		jmp numbs
numb:	mov	eax,0x5
numbs:	_DUP
		xor eax,eax
.loop	call	KEY
		cmp	al,0
		jz	.end
		call	numpack
		DROP
		jmp	.loop
.end	;move stuff from stack and gogo dance
		DROP
		push	edi
		shl	eax,4
		add	eax,[esi]	;we will have the word type here at NOS
		mov	edi,[blk]
		shl	edi,8
		add edi,[xy]
		mov	[edi*4],eax
		pop	edi
		DROP
		inc	dword [xy]
		ret
blkinc	call clr
		inc	dword [blk]
		ret
blkdec	call	clr
		dec dword [blk]
		ret
ekeys:	dd	blkinc,numbnow,whiw,nop0,nop0,nop0	;a,b,c,d,e,f
		dd	grew,eleft,nop0,edown,eup,eright	;g,h,i,j,k,l
		dd	cyaw,numb,nop0,nop0,nop0,redw	;m,n,o,p,q,r
		dd	nop0,nop0,nop0,magw,nop0,nop0	;s,t,u,v,w,x
		dd	yelw,blkdec						;y,z
edit:	push edi ;(blk -- )
		call clr
		mov edx,keys
		DROP
.loop	call	dispblock
		call	KEY
		_DUP
		call hdot
		cmp	al,0x1B	;was esc pressed?
		je .end		;yes
		cmp	eax,'a'
		jb	.ctrlend
		cmp	eax,'z'
		ja	.ctrlend
		sub	eax,'a'
		call	[ekeys + eax * 4]
.ctrlend:
		DROP
		jmp	.loop
.end	DROP
		call	clr
		pop	edi
		ret
dispblock:	mov	ebx,0xb8000;call clr
			push edi
			mov	edi,[blk]
			shl	edi,8 ;	eax now points to start of block (32bits)
			mov	ecx,0x15
.outloop	push ecx
			push ebx
			mov	ecx,0xc
.inloop		_DUP
			mov	eax,[edi*4]
			inc edi
			push ecx
			call dispword
			pop ecx
			next .inloop
			pop	ebx
			add ebx,0xa0	;advance one line
			pop ecx
			next	.outloop
			pop edi
			mov	byte [colour],0x1	;blue
			_DUP
			mov	eax,[xy]
			call	hdot
			ret
dispword:	mov	edx,eax
			and	edx,0xF
			test	edx,edx
			jz	.disp
			_DUP
			mov	al,[colours + edx]
			mov	[colour],al
			DROP
.disp		jmp [display + edx*4]
display	dd	dbtext, dtext, dno, dtext
		dd	dtext, dno, dno, dtext
		dd	dno, dtext, dtext, dtext
		dd	dtext, dtext, dtext, dtext
colours	db	0x0,0xe,0xe,0x4,0xa,0xa,0xa,0xb	; x,bright yellow * 2, bright red, bright green*3,cyan
		db	0xe,0xf,0xf,0xf,0x6,0x0,0x0,0x0 ; bright yellow, white * 3, magenta
dbtext:	dec ebx
		dec	ebx
dtext:	and	al,0xF0
.loop	test	eax,eax
			jz	.end
		rol	eax,7
		_DUP
		and	eax,0x7F
		call emit
		and al,0x80
		jmp	.loop
.end	DROP
		inc ebx
		inc ebx
		ret
dno:	
		shr	eax,4
		call hdot
		ret
;;----dictionary----------------
forth	mov	byte [dict],0x0
		ret
macro	mov	byte [dict],0x1
		ret
dict	db	0x0
define:	;inc	dword [forths]
		shl eax,4
def1:	and al,0xF0
		add	al,[dict]
		_DUP
		call hdot
		mov	ecx,[forths]
		mov	[forth0 + ecx*4],eax
		mov	eax,[here]
		mov	[forth2 + ecx*4],eax
		;DROP
		call hdot
		inc dword [forths]
		ret
;lables
forths	dd	0x0000000F	;number of entries in dictionary
forth0:	dd	0xC38B7F20		;abor(t)
		dd	0x1AF2F90		;key
		dd	0xCBB74F40	;emit
		dd	0xE7C30E30		;spac(e)
		dd	0x2B0	;+
		dd	0x2E0	;.
		dd	0x17730	;.s
		dd	0x18f6720 ;clr
		dd	0x3B1	;  ";" (macro)
		dd	0xD9BF0E40	; load
		dd	0xCB934F40	; edit
		dd	0x2C0	; ","
		dd	0xCDBF9740	; fort
		dd	0xDB871F20	; macr
		dd	0x193AF01	; dup (macro)
forth1:	times 512 dd 0x0		;space for user words
;addresses
forth2:	dd	abort
		dd	KEY
		dd	emit
		dd	space
		dd	plus
		dd	hdot
		dd	dots
		dd	clr
		dd	semi
		dd  load
		dd	edit
		dd	comma
		dd	forth
		dd	macro
		dd	cdup
		times 512 dd 0x0		;space for user words
		
;;---------------------GDT-----------------------------
gdt0	dw 0, 0, 0, 0
		dw 0FFFFh, 0, 0x9A00, 0xCF	;code
		dw 0FFFFh, 0, 0x9200, 0xCF	;data
gdt		dw gdt - gdt0 - 1			;size of gdt
		dd	gdt0					;address of gdt

times	0x2000 - ($ - $$) db 0
blocks:	;block 48
	dd	0x17731, 0x17731, 0x17731, 0x0 ; .s .s .s
times	0x2400 - ($ - $$) db 0 ;block 49
	dd	0x12346, 0x12126, 0x0 ; 1234 1212 
times	0x2800 - ($ - $$) db 0 ;block 4a
	dd	0x12789 
;; space for 10 blocks - this is temporary till we get the memory layout sorted.
times	0x4800 - ($ - $$) db 0
end:	;because we are a flat binary
edata:
dictionary:
