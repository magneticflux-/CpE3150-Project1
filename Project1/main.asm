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

; Tone Generator
toneGenFreq: .byte 1

.cseg
; Stack setup
ldi r16, high(RAMEND)
out SPH, r16
ldi r16, low(RAMEND)
out SPL, r16

; I/O setup
; PINA input
ldi r16, 0b00000000
out DDRA, r16
ldi r16, 0b11111111
out PORTA, r16
; PORTD output
ldi r16, 0b11111111
out DDRD, r16
; PORTE.4 output
ldi r16, 0b00010000
out DDRE, r16

; Variable initialization
ldi r16, 0x00
sts lastButtonState, r16
sts currentButtonState, r16
sts buttonJustPressed, r16
sts buttonJustReleased, r16
sts counter, r16
ldi r16, 0b00000100
sts toneGenFreq, r16

start:
	rcall loadButtonState
	rcall handleCounter
	rcall handleToneGenerator
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
	cpse r16, r17 ;check if counter is at 16
	ret
	rcall overflowAlarm ;sound overflow alarm if so
	ret

decrement:
	dec r16
	ldi r17, 255
	cpse r16, r17 ; check if counter is at 255
	ret 
	rcall overflowAlarm; sound overflow alarm if so
	ret


overflowAlarm:
	ldi r21, 2
	loopb: ldi r18, 0xFF
	loopa: sbi PORTE, 4 ;set PORTE4 bit
	rcall alarmDelay ;call .5 ms delay
	cbi PORTE, 4 ;clear PORTE4 bit
	rcall alarmDelay ;call .5 ms delay
	dec r18
	brne loopa
	dec r21
	brne loopb
	rcall overflowLights
	ret

alarmDelay:
	ldi r20, 10 ;loop of about .5 miliseconds for about 1000Hz wave 
	loop3: ldi r19, 0
	loop4: inc r19
	brne loop4
	dec r20
	brne loop3
	ret

overflowLights:
	ldi r18, 0b00001111
	out PORTD, r18 ;clear 4 MSB to light top LEDs
	ldi r21, 2 ;begin loop to keep LEDs on
	loopc: ldi r18, 0xFF
	loopd: dec r18
	brne loopd
	dec r21
	brne loopc
	ldi r18, 0xFF
	out PORTD, r18 ;set all bits to shut LEDs off
	ret

handleToneGenerator:
	lds r0, buttonJustPressed
	lds r16, toneGenFreq

	sbrc r0, 3 ; Play tone
	rcall playTone
	sbrc r0, 2 ; Increase frequency
	;inc r16
	lsl r16
	sbrc r0, 4 ; Decrease frequency
	;dec r16
	lsr r16

	; Reset delay to 1 if it is 0
	cpi r16, 0
	brne noReset
	ldi r16, 1
	noReset:

	sts toneGenFreq, r16

	ret

playTone:
	; r0, r16 used
	ldi r17, 0x00
	toneLoop1: ldi r18, 0x00
	toneLoop2: inc r18
	rcall playPeriod
	brne toneLoop2
	inc r17
	brne toneLoop1
	ret

playPeriod:
	; r0, r16, r17, r18 used

	mov r19, r16
	sbi PORTE, 4
	toneLoopOn1: ldi r20, 0x00
	toneLoopOn2: dec r20
	brne toneLoopOn2
	dec r19
	brne toneLoopOn1
	
	mov r19, r16
	cbi PORTE, 4
	toneLoopOff1: ldi r20, 0x00
	toneLoopOff2: dec r20
	brne toneLoopOff2
	dec r19
	brne toneLoopOff1
	
	ret