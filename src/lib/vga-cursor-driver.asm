; Requires "vga-base-driver.asm".
; This module contains extended base routines with automatic cursor repositioning as well as standalone cursor positioning.

CRT_CONTROLLER_INDEX_PORT equ 0x03d4
CRT_CONTROLLER_DATA_PORT equ 0x03d5
CRT_CONTROLLER_TEXT_CURSOR_LOCATION_LOW_INDEX equ 0x0f
CRT_CONTROLLER_TEXT_CURSOR_LOCATION_HIGH_INDEX equ 0x0e

[bits 16]
print_string_cursor:
  ; Same as print_string but with cursor
  ; placed at the returned offset position.
  ;
  ; Arguments:
  ;   String pointer as word.
  ;   Color and nil char to print as word.
  ;   Text buffer offset word. 2 per char.
  ;
  ; Returns:
  ;   AX = Offset after the
  ;        number was printed.
  ;
  ; Function prologue. Set up stack frame.
  push bp
  mov bp, sp
  ; Get args.
  mov word bx, [bp+4]
  mov word ax, [bp+6]
  mov word di, [bp+8]
  push di
  push ax
  push bx
  call print_string
  add sp, 0x6
  ; Store text buffer offset for return.
  push ax
  ; Position cursor
  shr ax, 1                                ; Divide text buffer offset by 2 to get cursor offset.
  push ax                                  ; Pass offset arg.
  call position_cursor
  add sp, 0x2                              ; Clean up stack.
  ; Set return.
  pop ax
  ; Function epilogue. Tear down stack frame.
  pop bp
  ret

[bits 16]
print_hex_word_cursor:
  ; Same as print_hex_word but with cursor
  ; placed at the returned offset position.
  ;
  ; Arguments:
  ;   Hex word to print.
  ;   Color and nil char to print as word.
  ;   Text buffer offset word. 2 per char.
  ;
  ; Returns:
  ;   AX = Offset after the
  ;        number was printed.
  ;
  ; Function prologue. Set up stack frame.
  push bp
  mov bp, sp
  ; Get args.
  mov word bx, [bp+4]
  mov word ax, [bp+6]
  mov word di, [bp+8]
  push di
  push ax
  push bx
  call print_hex_word
  add sp, 0x6
  ; Store text buffer offset for return.
  push ax
  ; Position cursor
  shr ax, 1                                ; Divide text buffer offset by 2 to get cursor offset.
  push ax                                  ; Pass offset arg.
  call position_cursor
  add sp, 0x2                              ; Clean up stack.
  ; Set return.
  pop ax
  ; Function epilogue. Tear down stack frame.
  pop bp
  ret

[bits 16]
print_char_cursor:
  ; Same as print_char but with the cursor
  ; placed at the returned offset position.
  ;
  ; Arguments:
  ;   Color and ASCII character as word.
  ;   Text buffer offset word. 2 per char.
  ;
  ; Returns:
  ;   AX = Offset incremented by two.
  ;
  ; Function prologue. Set up stack frame.
  push bp
  mov bp, sp
  ; Get arguments.
  mov word ax, [bp+4]
  mov word di, [bp+6]
  push di
  push ax
  call print_char
  add sp, 0x4
  ; Store text buffer offset for return.
  push ax
  ; Position cursor
  shr ax, 1                                ; Divide text buffer offset by 2 to get cursor offset.
  push ax                                  ; Pass offset arg.
  call position_cursor
  add sp, 0x2                              ; Clean up stack.
  ; Set return.
  pop ax
  ; Function epilogue. Tear down stack frame.
  pop bp
  ret

[bits 16]
set_new_line_cursor:
  ; Same as set_new_line but with the cursor
  ; placed at the returned offset position.
  ;
  ; Arguments:
  ;   Text buffer offset word. 2 per char.
  ;
  ; Returns:
  ;   AX = New line offset.
  ;
  ; Function prologue. Set up stack frame.
  push bp
  mov bp, sp
  ; Get arg.
  mov word ax, [bp+4]
  ; Calculate new line offset.
  push ax                                  ; Pass offset arg.
  call set_new_line
  add sp, 0x2                              ; Clean up stack.
  ; Store text buffer offset for return.
  push ax
  ; Position cursor
  shr ax, 1                                ; Divide text buffer offset by 2 to get cursor offset.
  push ax                                  ; Pass offset arg.
  call position_cursor
  add sp, 0x2                              ; Clean up stack.
  ; Set return.
  pop ax
  ; Function epilogue. Tear down stack frame.
  pop bp
  ret

[bits 16]
position_cursor:
  ; Positions the cursor at the passed char
  ; offset based on 80x25 chars text mode.
  ;
  ; Arguments:
  ;   Cursor location char offset as word.
  ;
  ; Function prologue. Set up stack frame.
  push bp
  mov bp, sp
  ; Set the cursor location low index.
  mov word dx, CRT_CONTROLLER_INDEX_PORT
  mov byte al, CRT_CONTROLLER_TEXT_CURSOR_LOCATION_LOW_INDEX
  out dx, al
  ; Set the cursor location low value.
  mov word dx, CRT_CONTROLLER_DATA_PORT
  mov word ax, [bp+4]                      ; Get arg value. Locations is split in two VGA registers. We send both parts separately.
  out dx, al                               ; Send lower part first.
  ; Set the cursor location high index.
  mov word dx, CRT_CONTROLLER_INDEX_PORT
  mov byte al, CRT_CONTROLLER_TEXT_CURSOR_LOCATION_HIGH_INDEX
  out dx, al
  ; Set the cursor location high value.
  mov word dx, CRT_CONTROLLER_DATA_PORT
  shr ax, 0x8                              ; High part of the new cursor location to AL.
  out dx, al                               ; Send high part second.
  ; Function epilogue. Tear down stack frame.
  pop bp
  ret