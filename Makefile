os:
	mkdir -p bin
	cd src/os/; nasm bootsector.asm -f bin -o bootsector.bin
	cd src/os/; nasm kernel.asm -f bin -o kernel.bin
	mv src/os/bootsector.bin bin/
	mv src/os/kernel.bin bin/
	cat bin/bootsector.bin bin/kernel.bin > bin/davidos.bin
	qemu-system-x86_64 -drive format=raw,file=bin/davidos.bin,index=0,if=ide

tut1:
	mkdir -p bin
	cd src/tutorials/; nasm 01-basics.asm -f bin -o 01-basics.bin
	mv src/tutorials/01-basics.bin bin/
	od -t x1 -A n bin/01-basics.bin
	qemu-system-x86_64 -drive format=raw,file=bin/01-basics.bin,index=0,if=ide

tut2:
	mkdir -p bin
	cd src/tutorials/; nasm 02-rm-addressing.asm -f bin -o 02-rm-addressing.bin
	mv src/tutorials/02-rm-addressing.bin bin/
	od -t x1 -A n bin/02-rm-addressing.bin
	qemu-system-x86_64 -drive format=raw,file=bin/02-rm-addressing.bin,index=0,if=ide

tut3:
	mkdir -p bin
	cd src/tutorials/; nasm 03-stack.asm -f bin -o 03-stack.bin
	mv src/tutorials/03-stack.bin bin/
	od -t x1 -A n bin/03-stack.bin
	qemu-system-x86_64 -drive format=raw,file=bin/03-stack.bin,index=0,if=ide

tut4:
	mkdir -p bin
	cd src/tutorials/; nasm 04-display-text-and-numbers-vga.asm -f bin -o 04-display-text-and-numbers-vga.bin
	mv src/tutorials/04-display-text-and-numbers-vga.bin bin/
	od -t x1 -A n bin/04-display-text-and-numbers-vga.bin
	qemu-system-x86_64 -drive format=raw,file=bin/04-display-text-and-numbers-vga.bin,index=0,if=ide

tut5:
	mkdir -p bin
	cd src/tutorials/; nasm 05-cursor-vga.asm -f bin -o 05-cursor-vga.bin
	mv src/tutorials/05-cursor-vga.bin bin/
	od -t x1 -A n bin/05-cursor-vga.bin
	qemu-system-x86_64 -drive format=raw,file=bin/05-cursor-vga.bin,index=0,if=ide

tut6:
	mkdir -p bin
	cd src/tutorials/; nasm 06-read-disk.asm -f bin -o 06-read-disk.bin
	mv src/tutorials/06-read-disk.bin bin/
	od -t x1 -A n bin/06-read-disk.bin
	qemu-system-x86_64 -drive format=raw,file=bin/06-read-disk.bin,index=0,if=ide

tut7:
	mkdir -p bin
	cd src/tutorials/; nasm 07-capture-pressed-keys.asm -f bin -o 07-capture-pressed-keys.bin
	mv src/tutorials/07-capture-pressed-keys.bin bin/
	od -t x1 -A n bin/07-capture-pressed-keys.bin
	qemu-system-x86_64 -drive format=raw,file=bin/07-capture-pressed-keys.bin,index=0,if=ide

tut8:
	mkdir -p bin
	cd src/tutorials/; nasm 08-memory-manager.asm -f bin -o 08-memory-manager.bin
	mv src/tutorials/08-memory-manager.bin bin/
	od -t x1 -A n bin/08-memory-manager.bin
	qemu-system-x86_64 -drive format=raw,file=bin/08-memory-manager.bin,index=0,if=ide

tut9:
	mkdir -p bin
	cd src/tutorials/; nasm 09-task-manager.asm -f bin -o 09-task-manager.bin
	mv src/tutorials/09-task-manager.bin bin/
	od -t x1 -A n bin/09-task-manager.bin
	qemu-system-x86_64 -drive format=raw,file=bin/09-task-manager.bin,index=0,if=ide

tut10:
	mkdir -p bin
	cd src/tutorials/; nasm 10-file-menu.asm -f bin -o 10-file-menu.bin
	mv src/tutorials/10-file-menu.bin bin/
	od -t x1 -A n bin/10-file-menu.bin
	qemu-system-x86_64 -drive format=raw,file=bin/10-file-menu.bin,index=0,if=ide

tut11:
	mkdir -p bin
	cd src/tutorials/; nasm 11-driver-syscalls.asm -f bin -o 11-driver-syscalls.bin
	mv src/tutorials/11-driver-syscalls.bin bin/
	od -t x1 -A n bin/11-driver-syscalls.bin
	qemu-system-x86_64 -drive format=raw,file=bin/11-driver-syscalls.bin,index=0,if=ide