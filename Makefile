run : a.img
	qemu -nics 0 -fda a.img
	dd if=a.img of=blocks.bin skip=17 count=10

a.img : boot.bin 
	dd if=boot.bin of=a.img conv=notrunc

boot.bin : boot.asm kernel.bin
	nasm -o boot.bin boot.asm

kernel.bin : kernel.asm
	nasm -l kernel.lst -o kernel.bin kernel.asm
