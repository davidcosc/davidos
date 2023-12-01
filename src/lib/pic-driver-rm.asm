; This module contains a routine for configuring the 8259 programmable interrupt controller for usage in 16 bit real mode.
; For details about the control words used during the configuration process, see "../images/8259_pic_cw.png".

[bits 16]
configure_pics_rm:
  ; Fully configures the pic. This can only
  ; be done by reinitializing it. To do so
  ; we first need to send a special control
  ; word called ICW1 to the command port.
  ; This starts the configuration process
  ; which requires 2 or 3 additional control
  ; words called ICW2, ICW3 and ICW4 to be
  ; send to the data port.
  ;
  ; ICW2 specifies the interrupt offset for
  ; all interrupts handled by the respective
  ; pic. Offsets must be divisible by 8.
  ; Each pic has 8 interrupt lines. I.e. an
  ; offset of 0x10 on the master pic results
  ; in IRQ0 being mapped to INT 0x10, IRQ1
  ; being mapped to INT 0x11 and so on. In
  ; real mode each interrupt vector has a
  ; size of 4 bytes. To get the starting
  ; address in memory where the vector
  ; begins for a specific interrupt,
  ; multiply the interrupt number by 4.
  ; I.e. for INT 0x11 this results in
  ; address 0x44.
  ;
  ; Arguments:
  ;   BH = ICW2 for master pic.
  ;   BL = ICW2 offset for slave pic.
  cli
  push ax
  ; ICW1
  mov al, 00010101b                        ; We want an ICW1 that starts the setup process for 2 (default for x86) cascading, edge triggered PICs, using 4 byte interrupt vectors since we are in rm. ICW4 is required in x86.
  out 0x20, al                             ; Send ICW1 to command port of master pic.
  out 0xA0, al                             ; Send ICW1 to command port of slave pic.
  ; ICW2
  mov al, bh
  out 0x21, al                             ; Send ICW2 to data port of master pic.
  mov al, bl
  out 0xA1, al                             ; Send ICW2 to data port of slave pic.
  ; ICW3
  mov al, 00000100b                        ; We expect the slave pic to be connected to the master on IRQ2 pin.
  out 0x21, al                             ; Send ICW3 to data port of master pic.
  mov al, 0x02                             ; We expect the slave pic to have a cascade identity of 2. It triggers IRQ2 on master.
  out 0xA1, al                             ; Send ICW3 to data port of slave pic.
  ; ICW4
  mov al, 00000001b                        ; We want ICW4 to set x86 mode environment.
  out 0x21, al                             ; Send ICW4 to data port of master pic.
  out 0xA1, al                             ; Send ICW4 to data port of slave pic.
  pop ax
  sti
  ret

mask_interrupts:
  ; Enables or disables specific interrupt
  ; lines on the master and slave pic by
  ; providing operational control world OCW1
  ; to the data port of the respective pic.
  ; OCW1 is an 8 bit binary value. The least
  ; significant bit refers to the lowest
  ; interrupt line. To disable the
  ; respective interrupt line set the bit 
  ; value to 1. I.e. to disable all
  ; interrupts on the master pic apart from
  ; IRQ1, provide a OCW1 of 11111101b.
  ;
  ; Arguments:
  ;   BH = OCW1 for the master pic.
  ;   BL = OCW1 for the slave pic.
  cli
  mov al, bh
  out 0x21, al                             ; Send OCW1 to data port of master pic.
  mov al, bl
  out 0xA1, al                             ; Send OCW1 to data port of slave pic.
  sti
  ret