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

%macro	SWAP 0
	push dword [esi]
	mov	[esi],eax
	pop	eax
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
	mov ebx,0xB8000
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
ex_s		dd	ex, nop0,	nop0, nop0
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
KEY:	_DUP	
		mov		edx,[board]
		xor		eax,eax		;clear eax
	 .loop:		;call pause - switch to other stuff while we
							;wait for a key press
			in		al, 0x64	;check if key press waiting
			test	al, 1
			jz		.loop
		in		al, 0x60	;get waiting key
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
		jne		.kbspecnd
			mov EDX,shift
			jmp .loop
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
		shr		ecx,2
.loop	push	ecx
		call	hdot
		pop		ecx
		next	.loop
		pop		eax
		pop		esi
		pop		ecx
		ret
ex:		call find
		jnz	abort
		DROP
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
;;----dictionary----------------
define:	inc	dword [forths]
		mov	ecx,[forths]
		mov	[forth0 + ecx*4],eax
		mov	eax,[here]
		mov	[forth2 + ecx*4],eax
		DROP
		ret
;lables
forths	dd	0x00000009		;number of entries in dictionary
forth0:	dd	0xC38B7F2		;abor(t)
		dd	0x1AF2F9		;key
		dd	0xCBB74F4	;emit
		dd	0xE7C30E3		;spac(e)
		dd	0x2B	;+
		dd	0x2E	;.
		dd	0x1773	;.s
		dd	0x18f672 ;clr
		dd	0x3B	;  ";"
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
		times 512 dd 0x0		;space for user words
		
;;---------------------GDT-----------------------------
gdt0	dw 0, 0, 0, 0
		dw 0FFFFh, 0, 0x9A00, 0xCF	;code
		dw 0FFFFh, 0, 0x9200, 0xCF	;data
gdt		dw gdt - gdt0 - 1			;size of gdt
		dd	gdt0					;address of gdt
end:	;because we are a flat binary
edata:
dictionary:
