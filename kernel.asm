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
	mov dword [forths],0x11
	call clr
	mov edx,keys
	mov	[board],edx
	_DUP
	mov	eax,0x48;forth0
	;call	hdot
	call	load
	jmp abort
	;_DUP
preaccept:
	_DUP
	xor	eax,eax
	mov	dword [chars],0x0
accept:
	push edx
	call KEY
	pop edx
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
semi:	mov	edx,[here]
		mov	byte [edx],0xC3	;ret opcode
		inc	dword [here]
		ret
		
hdigits	db	'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'
hdot:	
		mov	ecx,8		;loop over the 8 hex digits in a cell
		test eax,eax
		jnz .preloop
			mov ecx,1 ; only print the one 0
			jmp .loop
.preloop rol eax,4
		;_DUP
		test ax,0x0f
		jnz .inloop
		next .preloop
.loop:	rol	eax, 4
.inloop	_DUP
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
ignore:	DROP ;(n -- ) ; note this seems to actually exit the load loop
		pop edi
		pop edi
		ret
nul2:	DROP	; need to DROP or the comment gets left on the stack
		ret
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
		dd comp1, compnum, nul2, compmacr
		dd nul2, nul2, nul2, nul2
		dd variable, stringlit, nul2, nul2
ex:		shl	eax,4
		and al,0xF0
		;add al,0x01
		;call find	;finding macros
		;jnz	.fort
		;	jmp .gogo
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
dma:	;(buffer -- )
		_DUP
		mov	word [command+1],0x2a1
		mov al,3
		mov cl,3
		call cmd
		mov	word [command+1],0
		DROP ;mov	eax,0x4800
		shl	eax, 2
		out 4, al
		mov	al, ah
		out 4, al
		shr	eax, 16
		out 0x81, al
		mov	eax, 512*18*2-1
		out 5, al
		mov al, ah
		out 5, al
		mov	al, 0x0b
		out	0x0f, al
		DROP
		ret
command:	
		db	0
		db	0
cylinder:
		db	0	;cylinder
		db	0 ;head 
		db	2;1	; sector
		db	2	; b/s
		db	18
		db	0x1b
		db	0xFF
cmd:	push	esi
		mov	esi,command
		mov	[esi], al
cmd1:	call	ready
		jns	.out
			in	al,dx
			out 0xe1,al
			jmp cmd1
.out	lodsb
		out	dx,al
		push	ecx
ol:		mov	ecx,0x1e
			out	0xe1,al
;			loop ol
		pop	ecx
		next cmd1
		pop esi
		ret
ms equ	1000*1000/4
onoff:	mov	edx,0x3f2
		out	dx,al
		mov	cx, 0xe
.loop	out	0xe1,al
		loop .loop
		ret
ready:	mov	edx,0x3f4
.loop		in al,dx
			out	0xe1,al
			shl	al,1
			jnc .loop
		inc edx
		test	al,al
		ret
sense_:	mov al, 8
		mov	cl, 1
		call cmd
		call ready
		in al, dx
		out 0xe1,al
		cmp al,0x80
		ret
spin:	
		;push ecx
		xor ecx,ecx
		mov	al, 0x1c
		call onoff
.loop	;mov	ecx, 400*ms
		;loop .loop
		mov	byte [cylinder],0
		mov	al,7
		mov cl,2
		jmp cmdi
		
seek:
		;push ecx
		call sense_
			jz	seek
		mov al, 0xf
		mov cl,3
cmdi:	call cmd
.loop	call sense_
			jz	.loop
		;pop ecx	
		ret
transfer:	mov cl,9
			call cmd
			;inc byte [cylinder]
.loop		call	ready
			jns	.loop
		DROP
		ret	
read:	;_DUP
		;xor	eax,eax
		;mov	al,[cylinder]
		;call hdot
		mov	[cylinder],al
		mov al, 0x16
		out	0xb, al
		call seek
		mov al, 0xe6 ; read data +mt + mfm +sk
		jmp transfer
write:
		mov	[cylinder],al
		mov al, 0x1a
		out 0xb, al
		call seek
		mov al, 0xc5
		jmp transfer
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
comma1:	mov	ecx,1
		jmp commas
comma2:	mov ecx,2
		jmp commas
comma3:	mov ecx,3
		jmp commas
comma:	mov	ecx,4
commas:	mov	edx,[here]
		mov	[edx],eax
		add	edx,ecx
		mov	[here],edx
		DROP
		ret
cdup:	mov edx,[here]
		mov	dword [edx],0x89fc768d
		mov	byte [edx+4],0x06
		add	edx,5
		mov	[here],edx
		ret
variable:
		;_DUP
		;call hdot
		mov ecx,[forths]
		and al,0xf0
		mov [forth0 + ecx*4],eax
		mov dword [forth2 + ecx*4],var1
		inc ecx
		inc eax ;macro
		mov [forth0 + ecx*4],eax
		mov dword [forth2 + ecx*4],var2
		inc ecx
		mov eax,[here]
		mov [forth2 + ecx*4],eax
		add dword [forths],3
		DROP
		;_DUP
		;call hdot
		ret
stringlit:
		and	al,0xF0
.loop	test	eax,eax
			jz	.end
		rol	eax,7
		_DUP
		and	eax,0x7F
		jnz .emit
			DROP
			jmp .postemit
.emit	call comma1
.postemit	and al,0x80
		jmp	.loop
.end	DROP
		ret

var1:	;use side effect that ecx contains word number in dictionary
		_DUP
		mov eax,[8+forth2+ecx*4]
		ret
var2: ;macro
		_DUP
		mov eax,[4+forth2+ecx*4]
		jmp litral
compnum: and al,0xF0
		 shr eax,4
litral:	call cdup
		mov	edx,[here]
		mov	byte [edx],0xb8	;mov eax,lit
		mov	dword [edx+1],eax
		add edx,5
		mov [here],edx
		DROP
		ret
;;----dictionary----------------
gethere	_DUP
		mov	eax,[here]
		ret
plushere
		add [here],eax
		DROP
		ret
forth	mov	byte [dict],0x0
		ret
macro	mov	byte [dict],0x1
		ret
dict	db	0x0
define:	;inc	dword [forths]
		shl eax,4
def1:	and al,0xF0
		;_DUP
		;call hdot
		add	al,[dict]
		mov	ecx,[forths]
		mov	[forth0 + ecx*4],eax
		mov	eax,[here]
		mov	[forth2 + ecx*4],eax
		DROP
		;call hdot
		inc dword [forths]
		ret
;lables
forths	dd	0x0
forth0:	dd	0xC38B7F20		;abor(t)
		;dd	0x1AF2F90		;key
		;dd	0xCBB74F40	;emit
		;dd	0xE7C30E30		;spac(e)
		;dd	0x2E0	;.
		dd	0x17730	;.s
		dd	0x32f80 ;ex
		dd	0x3B1	;  ";" (macro)
		dd	0xD9BF0E40	; load
		dd	0x2C0	; ","
		dd	0x18AC0	; 1,
		dd	0x192C0	; 2,
		dd	0x19AC0	; 3,
		dd	0xCDBF9740	; fort
		dd	0xDB871F20	; macr
		dd	0xD1979650	; here
		dd	0x1936e10	; dma
		dd	0xa5160c40	; READ
		dd	0xaf4a4d40	; WRIT(E)
		dd	0xa7424ce0	; SPIN
		;dd	0xe1871eb0	; pack
		;dd	0xddd76f00	; nump
		dd 	0x57a32f20	; +her (e)
forth1:	times 512 dd 0x0		;space for user words
;addresses
forth2:	dd	abort
		;dd	KEY
		;dd	emit
		;dd	space
		;dd	hdot
		dd	dots
		dd	ex
		dd	semi
		dd  load
		dd	comma
		dd	comma1
		dd	comma2
		dd	comma3
		dd	forth
		dd	macro
		dd	gethere
		dd	dma
		dd	read
		dd 	write
		dd	spin
		;dd  pack
		;dd	numpack
		dd	plushere
		times 512 dd 0x0		;space for user words
		
;;---------------------GDT-----------------------------
gdt0	dw 0, 0, 0, 0
		dw 0FFFFh, 0, 0x9A00, 0xCF	;code
		dw 0FFFFh, 0, 0x9200, 0xCF	;data
gdt		dw gdt - gdt0 - 1			;size of gdt
		dd	gdt0					;address of gdt

times	0x2000 - ($ - $$) db 0
incbin "blocks.bin"
end:	;because we are a flat binary
edata:
dictionary:
