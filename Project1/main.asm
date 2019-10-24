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
ldi r16, 0b11111111
out PORTA, r16
ldi r16, 0b11111111
out DDRD, r16

; Variable initialization
ldi r16, 0x00
sts lastButtonState, r16
sts currentButtonState, r16
sts buttonJustPressed, r16
sts buttonJustReleased, r16
sts counter, r16
sts toneGenFreq, r16

start:
	rcall loadButtonState
	rcall handleCounter
	rcall jingleFeature
	rjmp start

loadButtonState:
	; Move currentButtonState to lastButtonState (as r0)
	lds r0, currentButtonState
	sts lastButtonState, r0
	; Get new currentButtonState (as r1)
	in r1, PINA
	com r1
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

	mov r16, r3
	cpi r16, 0
	breq return ; If no buttons are just pressed, return immediately
	rcall delay1 ; Delay for debounce
	return: ret

handleCounter:
	lds r0, buttonJustPressed
	lds r16, counter

	sbrc r0, 0 ; Increment if button 0 is just pressed
	inc r16
	sbrc r0, 1 ; Decrement if button 1 is just pressed
	dec r16

	andi r16, 0b00001111 ; Clear 4 MSB so value stays in 0x00-0x0F

	com r16
	out PORTD, r16 ; 1 = light off
	com r16

	sts counter, r16
	ret

delay1:
	ldi r16, 0
	loop1: ldi r17, 0
	loop2: inc r17
	brne loop2
	inc r16
	brne loop1
	ret

jingleFeature:
	lds r0, buttonJustPressed
	lds r16, toneGenFreq

	ldi r21, 0b00010000 ; registers are loaded with binary values to trigger lights for jingle
	ldi r22, 0b00100000
	ldi r23, 0b01000000

	sbrc r0, 5 ; play jingle if button 5 is pressed
	out PORTD, r21
	rcall playJingle
	lsl r16 ; increase the frequency
	out PORTD, r22
	rcall playJingle
	lsr r16 ; increase the frequency again
	out PORTD, r23
	rcall playJingle

	ret

playJingle:
	ldi r17, 0x00
	jingleLoop1: ldi r18, 0x00
	jingleLoop2: inc r18
	rcall jinglePeriod
	brne jingleLoop2
	inc r17
	brne jingleLoop1
	ret

jinglePeriod:
	mov r19, r16
	sbi PORTE, 4
	jingleLoopON1: ldi r20, 0x00
	jingleLoopON2: dec r20
	brne jingleLoopON2
	dec r19
	brne jingleLoopON1

	mov r19, r16
	cbi PORTE, 4
	jingleLoopOFF1: ldi r20, 0x00
	jingleLoopOFF2: dec r20
	brne jingleLoopOFF2
	dec r19
	brne jingleLoopOFF1

	ret