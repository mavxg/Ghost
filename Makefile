a.img : boot.bin
	dd if=boot.bin of=a.img conv=notrunc

boot.bin : boot.asm
	nasm -o boot.bin boot.asm

run:
	/Applications/Bochs-2.1-Carbon/bochs.app/Contents/MacOS/bochs -q
