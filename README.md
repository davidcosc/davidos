# Davidos

This repository aims at showcasing how a computer works under the hood when you have no operating system to do all the heavy lifting for you. Our goal will be to create a minimal operating system with some basic I/O drivers that allows us to run different mini games like a custom pong implementation. It is by no means a complete explanation or tutorial on everything that goes on in detail. Rather, it focuses on a subset of concepts I found interesting and wanted to learn more about at the time of writing.  

Topics addressed will include different hardware components and how to interact with them, assembly basics and some information about the boot process and BIOS. We will look at how to display text by writing to the screen, take user input from a keyboard and how to read from a disk. Along the way we will learn about important concecpts like addressing, the memory map, device I/O and interrupts. 


## Interacting with the system

To interact with any part of the system, the CPU needs to know where this part of the system is located. A location is defined by an address. A part of the system i.e. a device might be assigned many addresses in order to interact with or refer to different parts of that device. A good example of this is the memory device. Each byte of memory that can be accessed is referenced by an individual, specific address.  


## The boot process

The very first program our computer runs after a reboot is the BIOS firmware. At this point in time we do not have an operating system available for us at all. The basic input/output software (BIOS) is a collection of software routines stored on a read only memory (ROM) chip. The CPU expects the BIOS to be located at a specific address. The BIOSes job is to:
- detect RAM chips and initialize main memory by setting up a stack and the interrupt vector table ivt, which we will cover later on in detail.
- detect and configure other hardware like buses, pic, disk, usb or display devices etc.
- indentify bootable devices and transfer control to the bootsector by loading it to the specific address 0x7c00. This is where our own code/program will start.

The bootsector is a 512 byte program stored at the very beginning of our bootable device i.e. disk drive. To identify a bootsector the BIOS checks, that the value of the last two bytes 511 and 512 matches the magic sequence 0xaa55. To see this in action, we can start by writing our first bootsector. Take a look at "./tutorials/basics.asm" for an example bootsector that prints the letter a to the screen using a routine that was setup for us by the BIOS. The code will be commented in detail to explain the basics of x86 nasm assembly and common commands we will use a lot throughout the repository.


## Hardware

When it comes to hardware, we will concern ourselves with:
- the x86 CPU
- the 8259 programmable interrupt controller (PIC)
- a cylinder head sector addressable (CHS) disk drive
- a video graphics array (VGA) compatible screen
- random access memory (RAM).

### CPU

When we first start up our computer, the x86 CPU will run in 16 bit real mode. This means, that we have 16 bits that can be used for addressing. This means we can address 2^16 bytes or 64kB of RAM.