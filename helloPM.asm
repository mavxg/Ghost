[BITS 16]
[ORG 0x7C00]
	cli
	xor ax,	ax
	mov ds,	ax
	lgdt	[gdt]
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax

	jmp 08h:protected
[BITS 32]
protected:
	mov	al, 10h
	mov ds, eax
	mov	es, eax
	mov ss, eax
	mov esp, 090000h
	mov byte [ds:0B8000h],'P'
	mov byte [ds:0B8001h],1Bh
	
	mov ecx,string_len
	mov esi,string			;source string
	mov edi,0B8000h			;dest video mem
outchar:
	movsw
	loop outchar

	jmp	$					;loop forever (v.important)

gdt0	dw 0, 0, 0, 0
		dw 0FFFFh, 0, 9A00h, 0CFh	;code
		dw 0FFFFh, 0, 9200h, 0CFh	;data
gdt		dw gdt - gdt0 - 1				;size of gdt
		dd	gdt0					;address of gdt
	string db 'H',0Fh,'E',1Fh,'L',0Fh,'L',1Fh,'O',0Fh
	string_len equ 5
	times	510 - ($ - $$) DB 0
	dw	0xAA55				;magic number
