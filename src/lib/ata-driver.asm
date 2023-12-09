; This module contains a routine for reading from an ATA disk using PIO data in.

NUM_SECTORS_READ equ 1
SECTOR_WORD_SIZE equ 256
LBA_MODE_AND_DRIVE_ZERO equ 0b11100000
READ_RETRY_COMMAND equ 0x20
STATUS_REGISTER_DRQ_SET equ 0b00001000
COMMAND_BLOCK_BASE_IO_PORT equ 0x01f0
COMMAND_BLOCK_DATA_IO_PORT equ COMMAND_BLOCK_BASE_IO_PORT
COMMAND_BLOCK_SECTOR_COUNT_IO_PORT equ COMMAND_BLOCK_BASE_IO_PORT + 0x0002
COMMAND_BLOCK_SECTOR_NUMBER_IO_PORT equ COMMAND_BLOCK_BASE_IO_PORT + 0x0003
COMMAND_BLOCK_CYLINDER_LOW_IO_PORT equ COMMAND_BLOCK_BASE_IO_PORT + 0x0004
COMMAND_BLOCK_CYLINDER_HIGH_IO_PORT equ COMMAND_BLOCK_BASE_IO_PORT + 0x0005
COMMAND_BLOCK_DRIVE_HEAD_IO_PORT equ COMMAND_BLOCK_BASE_IO_PORT + 0x0006
COMMAND_BLOCK_COMMAND_IO_PORT equ COMMAND_BLOCK_BASE_IO_PORT + 0x0007
COMMAND_BLOCK_STATUS_IO_PORT equ COMMAND_BLOCK_COMMAND_IO_PORT

read_sector:
  ; Read a single sector from disk to memory
  ; using using ATA PIO data in. The sector
  ; is specified by its LBA.
  ;
  ; Arguments:
  ;   AX = Selected sectors LBA.
  ;   DI = Target memory address.
  push es
  push dx
  push ax
  push di
  ; Setup ES for disk data read.
  mov word dx, 0x0000
  mov es, dx
  ; Set up LBA bits 0-7.
  mov word dx, COMMAND_BLOCK_SECTOR_NUMBER_IO_PORT
  out byte dx, al
  ; Set up LBA bits 8-15.
  mov word dx, COMMAND_BLOCK_CYLINDER_LOW_IO_PORT
  shr ax, 0x8
  out byte dx, al
  ; Set up LBA bits 16-23.
  mov word dx, COMMAND_BLOCK_CYLINDER_HIGH_IO_PORT
  xor ax, ax
  out byte dx, al
  ; Set up LBA mode and LBA bits 24-27.
  mov word dx, COMMAND_BLOCK_DRIVE_HEAD_IO_PORT
  or al, LBA_MODE_AND_DRIVE_ZERO
  out byte dx, al
  ; Set numbers of sectors to read to one.
  mov word dx, COMMAND_BLOCK_SECTOR_COUNT_IO_PORT
  mov byte al, NUM_SECTORS_READ
  out byte dx, al
  ; Send read command to drive.
  mov word dx, COMMAND_BLOCK_COMMAND_IO_PORT
  mov byte al, READ_RETRY_COMMAND
  out byte dx, al
  .loop:
    mov word dx, COMMAND_BLOCK_STATUS_IO_PORT
    in byte al, dx
    test al, STATUS_REGISTER_DRQ_SET       ; Once DRQ is set to zero, the sector was loaded.
    jz .loop
  mov word cx, SECTOR_WORD_SIZE
  mov word dx, COMMAND_BLOCK_DATA_IO_PORT
  rep insw
  pop di
  pop ax
  pop dx
  pop es
  ret