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
	
	mov ebx,0xB8000
;---test code----	
	_DUP
	mov	eax,0x12345678
	_DUP
	mov eax,0x6
	call ex
;---test code----	
accept:
	call KEY
	call emit
	jmp accept
	jmp	$					;loop forever (v.important)

;;---------------------Basic Words---------------------
keys	db	0x0, 0x1B,'1','2','3','4','5','6','7','8','9','0','-','=',0 	; null,ESC,BKSP
		db	0x0,'q','w','e','r','t','y','u','i','o','p','[',']',0			; tab,cr 
		db	0x0,'a','s','d','f','g','h','j','k','l',0,0,0
		db	0x0,' ','z','x','c','v','b','n','m',',','.','/',0				; lshft,rshft
		db	'*',0x0,' '													; alt,space
		
KEY:	_DUP	;make interupt driven in next version
		xor		eax,eax		;clear eax
	 .loop:		;call pause - switch to other stuff while we
							;wait for a key press
			in		al, 0x64	;check if key press waiting
			test	al, 1
			jz		.loop
		in		al, 0x60	;get waiting key
		cmp		al,	72o		;0x3A (00111010)	;ignore key ups
		jnc		.loop
		mov		al,[keys+eax]
		ret		;return traslated key on stack

emit:	mov	[ebx],al
		DROP
space:	add	ebx,2
		ret
plus:	add [esi],eax	;add tos to nos
		DROP
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
;;----dictionary----------------
;lables
forths	dd	0x00000006		;number of entries in dictionary
forth0:	dd	0x1		;abort
		dd	0x2		;key
		dd	0x3		;emit
		dd	0x4		;space
		dd	0x5		;+
		dd	0x6		;.
forth1:	times 512 dd 0x0		;space for user words
;addresses
forth2:	dd	abort
		dd	KEY
		dd	emit
		dd	space
		dd	plus
		dd	hdot
		times 512 dd 0x0		;space for user words
		
;;---------------------GDT-----------------------------
gdt0	dw 0, 0, 0, 0
		dw 0FFFFh, 0, 0x9A00, 0xCF	;code
		dw 0FFFFh, 0, 0x9200, 0xCF	;data
gdt		dw gdt - gdt0 - 1			;size of gdt
		dd	gdt0					;address of gdt
end:	;because we are a flat binary
edata:

