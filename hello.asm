[BITS 16]
[ORG 0x7C00]
mov	ah,13h				;teletype mode
mov bh,0				;video page 0
mov	al,2				;write mode
mov cx,5				;string length 11dec
mov bp,string			;set string start location
int	10h					;applaus!!
jmp	$					;loop forever (v.important)
string db 'H',1Fh,'E',1Fh,'L',1Fh,'L',1Fh,'O',1Fh
times	510 - ($ - $$) DB 0
dw	0xAA55				;magic number
