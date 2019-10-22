;
; Project1.asm
;
; Created: 10/16/2019 12:34:45 PM
; Author : Team 1
;

; Stack setup
ldi r16, high(RAMEND)
out SPH, r16
ldi r16, low(RAMEND)
out SPL, r16

; I/O setup
ldi r16, 0b00000000
out DDRA, r16

start:
	rjmp start