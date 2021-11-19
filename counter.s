PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
PCR = $600c
IFR = $600d
IER = $600e

value = $0200 ; 2 bytes
mod10 = $0202 ; 2 bytes
message = $0204 ; 6 bytes
counter = $020a ; 2 bytes

E  = %10000001 ; LCD Enable
RW = %01000000 ; LCD R/W
RS = %00100000 ; Register Select

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
  lda #%00000110 ; Increment and shift cursor; don't shift display
  jsr lcd_instruction
  lda #%00000001 ; Clear display
  jsr lcd_instruction

  lda #0
  sta counter
  sta counter + 1

loop:
  lda #%00000010 ; Cursor to home
  jsr lcd_instruction

  lda #0
  sta message

  ; Initialise value to be number to convert
  sei
  lda counter
  sta value
  lda counter + 1
  sta value + 1
  cli

divide: 
  ; Initialise the remainder to be zero
  lda #0
  sta mod10
  sta mod10 + 1
  clc

  ldx #16
  
divloop:
  ; Rotate quotient and remainder
  rol value
  rol value + 1
  rol mod10
  rol mod10 + 1

  ; a, y = dividend - divisor
  sec
  lda mod10
  sbc #10
  tay ; save low byte in Y
  lda mod10 + 1
  sbc #0
  bcc ignore_result ; branching if dividend is less than divisor
  sty mod10
  sta mod10 + 1

ignore_result:
  dex
  bne divloop
  rol value ; shift the last bit of the quotient
  rol value + 1

  lda mod10
  clc
  adc #"0"
  jsr push_char

  ; if value != 0, then continue dividing
  lda value
  ora value + 1
  bne divide ; branch if value not zero

  ldx #0
print:
  lda message,x
  beq loop
  jsr print_char
  inx
  jmp print

number: .word 1729

; Add the character in the A register to the beginning of the null-terminated string 'message'
push_char:
  pha ; Push new first char onto the stack
  ldy #0

char_loop:
  lda message,y ; Get char on string and push into X register
  tax
  pla
  sta message,y ; Pul char off stack and add it to string
  iny
  txa
  pha ; Push char from string onto stack
  bne char_loop
  
  pla
  sta message,y ; Pull the null off the stack and add to the end of the string

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

nmi:
irq:
  pha
  txa
  pha
  tya
  pha

  inc counter
  bne exit_irq
  inc counter + 1
exit_irq:

  ldy #$ff
  ldx #$ff
delay:
  dex
  bne delay
  dey
  bne delay

  bit PORTA
  
  pla
  tay
  pla
  tax
  pla

  rti

  .org $fffa
  .word nmi
  .word reset
  .word irq
