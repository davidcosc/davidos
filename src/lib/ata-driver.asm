; This module contains a routine for reading from an ATA disk using PIO data in.

NUM_SECTORS_READ equ 1
SECTOR_WORD_SIZE equ 256
LBA_MODE_AND_DRIVE_ZERO equ 0b11100000
READ_RETRY_COMMAND equ 0x20
STATUS_REGISTER_DRQ_SET equ 0b00001000
COMMAND_BLOCK_BASE_IO_PORT equ 0x01f0
COMMAND_BLOCK_DATA_IO_PORT equ COMMAND_BLOCK_BASE_IO_PORT
COMMAND_BLOCK_SECTOR_COUNT_IO_PORT equ COMMAND_BLOCK_BASE_IO_PORT + 0x2
COMMAND_BLOCK_SECTOR_NUMBER_IO_PORT equ COMMAND_BLOCK_BASE_IO_PORT + 0x3
COMMAND_BLOCK_CYLINDER_LOW_IO_PORT equ COMMAND_BLOCK_BASE_IO_PORT + 0x4
COMMAND_BLOCK_CYLINDER_HIGH_IO_PORT equ COMMAND_BLOCK_BASE_IO_PORT + 0x5
COMMAND_BLOCK_DRIVE_HEAD_IO_PORT equ COMMAND_BLOCK_BASE_IO_PORT + 0x6
COMMAND_BLOCK_COMMAND_IO_PORT equ COMMAND_BLOCK_BASE_IO_PORT + 0x7
COMMAND_BLOCK_STATUS_IO_PORT equ COMMAND_BLOCK_COMMAND_IO_PORT

read_sector:
  ; Read a single sector from disk to memory
  ; using using ATA PIO data in. The sector
  ; is specified by its LBA.
  ;
  ; Arguments:
  ;   AL = Selected sectors LBA.
  ;   DI = Target memory address.
  push es
  push dx
  push ax
  push di
  ; Setup ES for disk data read.
  mov dx, 0x0000
  mov es, dx
  ; Set up LBA bits 0-7.
  mov dx, COMMAND_BLOCK_SECTOR_NUMBER_IO_PORT
  out dx, al
  ; Set up LBA bits 8-15.
  mov dx, COMMAND_BLOCK_CYLINDER_LOW_IO_PORT
  shr ax, 0x8
  out dx, al
  ; Set up LBA bits 16-23.
  mov dx, COMMAND_BLOCK_CYLINDER_HIGH_IO_PORT
  xor ax, ax
  out dx, al
  ; Set up LBA mode and LBA bits 24-27.
  mov dx, COMMAND_BLOCK_DRIVE_HEAD_IO_PORT
  or al, LBA_MODE_AND_DRIVE_ZERO
  out dx, al
  ; Set numbers of sectors to read to one.
  mov dx, COMMAND_BLOCK_SECTOR_COUNT_IO_PORT
  mov al, NUM_SECTORS_READ
  out dx, al
  ; Send read command to drive.
  mov dx, COMMAND_BLOCK_COMMAND_IO_PORT
  mov al, READ_RETRY_COMMAND
  out dx, al
  .loop:
    mov dx, COMMAND_BLOCK_STATUS_IO_PORT
    in al, dx
    test al, STATUS_REGISTER_DRQ_SET       ; Once DRQ is set to zero, the sector was loaded.
    jz .loop
  mov cx, SECTOR_WORD_SIZE
  mov dx, COMMAND_BLOCK_DATA_IO_PORT
  rep insw
  pop di
  pop ax
  pop dx
  pop es
  ret