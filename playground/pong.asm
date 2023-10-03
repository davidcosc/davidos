; Prerequisites: "basics.asm", "rm-addressing.asm", "stack.asm".

SCREEN_LEFT equ 0
SCREEN_RIGHT equ 0x4f
LAST_ROW equ 0x50 * 0x2 * 0x17
PLAYER_SIZE equ 0xa

[org 0x7c00]
[bits 16]
main:
  mov ax, 0xb800                           ; The video memory for the text buffer for VGA text mode starts at 0xb8000. It consists of 80x25 words.
  mov es, ax                               ; Each word is encoded in 2 bytes. The first byte is used for color (first 4 bit background), the second for the character to be displayed.
  game_loop:
    call clear_screen
    mov di, 0x0
    call draw_player
    hlt
    jmp game_loop

;------------------------------------------
; Clears the screen. Only works in 80x25
; video text mode.
;
[bits 16]
clear_screen:
  pusha
  xor ax, ax                               ; Clear ax.
  xor di, di                               ; Clear di.
  mov cx, 80*25                            ; Set counter register to total screen character size. Using this with rep will repeat the following instruction cx times.
  rep stosw                                ; Stosw is equivalent to mov [es:di], ax and then inc ax by 2. We write zero to all 80*25 words in video memory for a black screen.
  popa
  ret

;------------------------------------------
; Draw a player bar to the screen.
;
; Arguments:
;   DI = Player left side position.
;
[bits 16]
draw_player:
  pusha
  imul di, 0x2
  add di, LAST_ROW
  mov ax, 0x2000
  mov cx, PLAYER_SIZE
  .loop:
    stosw
    loop .loop
  popa
  ret


player_x_pos:
  db 0x27

padding:
  times 510-(padding-main) db 0x0
  dw 0xaa55