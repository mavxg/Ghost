run : a.img
	qemu -nics 0 -fda a.img

a.img : boot.bin 
	dd if=boot.bin of=a.img conv=notrunc

boot.bin : boot.asm kernel.bin
	nasm -o boot.bin boot.asm

kernel.bin : kernel.asm
	nasm -o kernel.bin kernel.asm
