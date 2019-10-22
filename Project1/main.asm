;
; Project1.asm
;
; Created: 10/16/2019 12:34:45 PM
; Author : Team 1
;

.dseg
; Button data
lastButtonState: .byte 1
currentButtonState: .byte 1
buttonJustPressed: .byte 1
buttonJustReleased: .byte 1

; Counter
counter: .byte 1

.cseg
; Stack setup
ldi r16, high(RAMEND)
out SPH, r16
ldi r16, low(RAMEND)
out SPL, r16

; I/O setup
ldi r16, 0b00000000
out DDRA, r16

start:
	rcall loadButtonState
	rcall handleCounter
	rjmp start

loadButtonState:
	; Move currentButtonState to lastButtonState (as r0)
	lds r0, currentButtonState
	sts lastButtonState, r0
	; Get new currentButtonState (as r1)
	in r1, PINA
	sts currentButtonState, r1
	
	; Duplicate last and current to r2, r3
	movw r2, r0

	; Just pressed: r2 = !last & current
	com r2
	and r2, r1
	sts buttonJustPressed, r2

	; Just released: r3 = last & !current
	com r3
	and r3, r0
	sts buttonJustReleased, r3

	ret

handleCounter:
	lds r0, buttonJustPressed
	lds r16, counter

	sbrc r0, 0 ; Increment if button 0 is just pressed
	inc r16
	sbrc r0, 1 ; Decrement if button 1 is just pressed
	dec r16

	andi r16, 0b00001111 ; Clear 4 MSB so value stays in 0x00-0x0F

	sts counter, r16
	ret