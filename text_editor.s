PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
PCR = $600c
IFR = $600d
IER = $600e

letter = $0200 ; 1 bytes

UP = %00000010
DOWN = %00000100
LEFT = %00001000
RIGHT = %00010000
BUTTON_MASK = %00011110
LED = %00000001


E  = %10000000
RW = %01000000
RS = %00100000

  .org $8000

reset:
  ldx #$ff
  txs
  cli

  lda #$82
  sta IER
  lda #$00
  sta PCR

  lda #%11111111 ; Set all pins on port B to output
  sta DDRB
  lda #%11100001 ; Set top 3 pins + last pin on port A to output
  sta DDRA

  lda #%00111000 ; Set 8-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00001110 ; Display on; cursor on; blink off
  jsr lcd_instruction
  lda #%00000100 ; Increment and shift cursor; don't shift display
  jsr lcd_instruction
  lda #%00000001 ; Clear display
  jsr lcd_instruction

  lda #%00000010 ; Cursor to home
  jsr lcd_instruction

  lda #%01100000 ; Loads "a" into RAM
  sta letter

loop:
  
  jsr right_button
  jsr left_button
  jsr up_button
  jsr down_button
  jmp loop


right_button: ; Checks if right button was pressed.
  lda PORTA
  and #BUTTON_MASK
  cmp #RIGHT
  beq cursor_right
  rts

left_button: ; Checks if left button was pressed.
  lda PORTA
  and #BUTTON_MASK
  cmp #LEFT
  beq cursor_left
  rts

up_button:
  lda PORTA
  and #BUTTON_MASK
  cmp #UP
  beq up_char
  rts

down_button:
  lda PORTA
  and #BUTTON_MASK
  cmp #DOWN
  beq down_char
  rts

cursor_left: ; Moves cursor left
  lda #%00010000
  jsr lcd_instruction
  jsr delay
  rts

cursor_right: ; Moves cursor right
  lda #%00010100
  jsr lcd_instruction
  jsr delay
  rts

up_char:
  lda letter
  tax
  inx
  txa
  sta letter
  jsr print_char
  jsr cursor_left
  jsr delay
  rts

down_char:
  lda letter
  tax
  dex
  txa
  sta letter
  jsr print_char
  jsr cursor_left
  jsr delay
  rts

lcd_wait:
  pha
  lda #%00000000  ; Port B is input
  sta DDRB
lcdbusy:
  lda #RW
  sta PORTA
  lda #(RW | E)
  sta PORTA
  lda PORTB
  and #%10000000
  bne lcdbusy

  lda #RW
  sta PORTA
  lda #%11111111  ; Port B is output
  sta DDRB
  pla
  rts

lcd_instruction:
  jsr lcd_wait
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  lda #E         ; Set E bit to send instruction
  sta PORTA
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  rts

print_char:
  jsr lcd_wait
  sta PORTB
  lda #RS         ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | E)   ; Set E bit to send instruction
  sta PORTA
  lda #RS         ; Clear E bits
  sta PORTA
  rts

delay:
  ldy #$ff
  ldx #$ff
delay_loop:
  dex
  bne delay_loop
  dey
  bne delay_loop
  rts

nmi:
irq:

  .org $fffa
  .word nmi
  .word reset
  .word irq
