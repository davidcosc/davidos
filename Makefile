os:
	mkdir -p bin
	cd src/os/; nasm bootsector.asm -f bin -o bootsector.bin
	cd src/os/; nasm kernel.asm -f bin -o kernel.bin
	mv src/os/bootsector.bin bin/
	mv src/os/kernel.bin bin/
	cat bin/bootsector.bin bin/kernel.bin > bin/davidos.bin
	qemu-system-x86_64 bin/davidos.bin

tut1:
	mkdir -p bin
	cd src/tutorials/; nasm 01-basics.asm -f bin -o 01-basics.bin
	mv src/tutorials/01-basics.bin bin/
	od -t x1 -A n bin/01-basics.bin
	qemu-system-x86_64 bin/01-basics.bin

tut2:
	mkdir -p bin
	cd src/tutorials/; nasm 02-rm-addressing.asm -f bin -o 02-rm-addressing.bin
	mv src/tutorials/02-rm-addressing.bin bin/
	od -t x1 -A n bin/02-rm-addressing.bin
	qemu-system-x86_64 bin/02-rm-addressing.bin

tut3:
	mkdir -p bin
	cd src/tutorials/; nasm 03-stack.asm -f bin -o 03-stack.bin
	mv src/tutorials/03-stack.bin bin/
	od -t x1 -A n bin/03-stack.bin
	qemu-system-x86_64 bin/03-stack.bin

tut4:
	mkdir -p bin
	cd src/tutorials/; nasm 04-display-text-vga.asm -f bin -o 04-display-text-vga.bin
	mv src/tutorials/04-display-text-vga.bin bin/
	od -t x1 -A n bin/04-display-text-vga.bin
	qemu-system-x86_64 bin/04-display-text-vga.bin

tut5:
	mkdir -p bin
	cd src/tutorials/; nasm 05-capture-pressed-keys.asm -f bin -o 05-capture-pressed-keys.bin
	mv src/tutorials/05-capture-pressed-keys.bin bin/
	od -t x1 -A n bin/05-capture-pressed-keys.bin
	qemu-system-x86_64 bin/05-capture-pressed-keys.bin

tut6:
	mkdir -p bin
	cd src/tutorials/; nasm 06-read-disk.asm -f bin -o 06-read-disk.bin
	mv src/tutorials/06-read-disk.bin bin/
	od -t x1 -A n bin/06-read-disk.bin
	qemu-system-x86_64 bin/06-read-disk.bin

tut7:
	mkdir -p bin
	cd src/tutorials/; nasm 07-file-menu.asm -f bin -o 07-file-menu.bin
	mv src/tutorials/07-file-menu.bin bin/
	od -t x1 -A n bin/07-file-menu.bin
	qemu-system-x86_64 bin/07-file-menu.bin