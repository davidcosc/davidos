os:
	mkdir -p bin
	cd src/os/; nasm mbr.asm -f bin -o davidos.bin
	mv src/os/davidos.bin bin/
	qemu-system-x86_64 bin/davidos.bin

tut1:
	mkdir -p bin
	cd src/tutorials/; nasm 01-basics.asm -f bin -o 01-basics.bin
	mv src/tutorials/01-basics.bin bin/
	qemu-system-x86_64 bin/01-basics.bin

tut2:
	mkdir -p bin
	cd src/tutorials/; nasm 02-rm-addressing.asm -f bin -o 02-rm-addressing.bin
	mv src/tutorials/02-rm-addressing.bin bin/
	qemu-system-x86_64 bin/02-rm-addressing.bin

tut3:
	mkdir -p bin
	cd src/tutorials/; nasm 03-stack.asm -f bin -o 03-stack.bin
	mv src/tutorials/03-stack.bin bin/
	qemu-system-x86_64 bin/03-stack.bin

tut4:
	mkdir -p bin
	cd src/tutorials/; nasm 04-io-devices.asm -f bin -o 04-io-devices.bin
	mv src/tutorials/04-io-devices.bin bin/
	qemu-system-x86_64 bin/04-io-devices.bin