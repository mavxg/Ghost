[BITS 16]
[ORG 0x7C00]
	cli
	xor ax,	ax
	mov ds,	ax
	lgdt	[gdt]			;setup gdt
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax			;set protected mode

	jmp 0x8:protected		;clear pipeline
[BITS 32]
protected:
	mov	al, 0x10			;dirty - 10h equ datasegment
	mov ds, eax
	mov	es, eax
	mov ss, eax
	mov esi, 0xa0000		;set data stack
	mov esp, 0x9f800		;set return stack
	;A20
	mov al,	0xD1
	out	0x64,al
	mov	al,	0x3
	out	0x60, al
	
	mov ebx,0xB8000
myloop
	call KEY
	mov [ebx],al
	add ebx,2
	DROP
	jmp myloop
	jmp	$					;loop forever (v.important)

;;BASIC FORTH LIKE MACROS------------------------------
%macro _DUP 0
	lea	ESI, [ESI-4]		;stack pointer down one cell
	mov [ESI], EAX			;Copy TOS to NOS
%endmacro

%macro DROP 0
	lodsd	;Why not just add ESI,4 (is this speed?)
%endmacro
;;---------------------Basic Words---------------------
keys	db 'q','w','e','r','t','y','u','i','o','p','[',']',13,0
		db	'a','s','d','f','g','h','j','k','l',';',' ',0,'`','#'
		db	'z','x','c','v','b','n','m',',','.','/',0 ,0,' ',0,0
KEY:	_DUP	;make interupt driven in next version
		xor		eax,eax		;clear eax
	 .loop:		;call pause - switch to other stuff while we
							;wait for a key press
			in		al, 0x64	;check if key press waiting
			test	al, 1
			jz		.loop
		in		al, 0x60	;get waiting key
		test	al, 360o	;0xF0 (11110000)
		jz		.loop
		cmp		al,	72o		;0x3A (00111010)
		jnc		.loop
		mov		al,[keys-0x10+eax]
		ret		;return traslated key on stack
		
;;---------------------GDT-----------------------------
gdt0	dw 0, 0, 0, 0
		dw 0FFFFh, 0, 0x9A00, 0xCF	;code
		dw 0FFFFh, 0, 0x9200, 0xCF	;data
gdt		dw gdt - gdt0 - 1			;size of gdt
		dd	gdt0					;address of gdt
	

;;------------------The END----------------------------	
	times	510 - ($ - $$) DB 0
	dw	0xAA55				;magic number
