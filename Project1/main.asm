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
ldi r16, 0b00010000
out DDRE, r17

; Variable initialization
ldi r16, 0x00
sts lastButtonState, r16
sts currentButtonState, r16
sts buttonJustPressed, r16
sts buttonJustReleased, r16
sts counter, r16

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
	rcall increment
	sbrc r0, 1 ; Decrement if button 1 is just pressed
	rcall decrement

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

increment:
	inc r16
	ldi r17, 16
	cpse r16, r17
	ret
	rcall overflowAlarm
	ret

decrement:
	dec r16
	ldi r17, 255
	cpse r16, r17
	ret 
	rcall overflowAlarm
	ret


overflowAlarm:
	ldi r21, 8
	loopb: ldi r18, 0xFF
	loopa: sbi PORTE, 4
	rcall alarmDelay
	cbi PORTE, 4
	rcall alarmDelay
	dec r18
	brne loopa
	dec r21
	brne loopb
	rcall overflowLights
	ret

alarmDelay:
	ldi r20, 10
	loop3: ldi r19, 0
	loop4: inc r19
	brne loop4
	dec r20
	brne loop3
	ret

overflowLights:
	ldi r18, 0b00001111
	out PORTD, r18
	ret