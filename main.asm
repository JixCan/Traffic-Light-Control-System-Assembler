.include "m328pdef.inc"

; Register for temporary tasks
.def temp = r16

; Registers for every possible color combination
.def RedColor = r17
.def YellowColor = r18
.def RedAndYellowColor = r19
.def GreenColor = r20
.def NoColor = r21

; Register for current mode value
.def CurrentMode = r22

; Regisster for counting ticks
.def TickCounter = r23

; Interrupt table initialization
.cseg
.org 0x0000 jmp Reset      
.org 0x001A jmp TIMER1_OVF 
.org INT_VECTORS_SIZE      

Reset:
	; Stack initialization
	ldi temp, High(RAMEND)
	out SPH,temp             
    ldi temp,Low(RAMEND)    
    out SPL,temp

	; Enable TIMER1 interrupts, OVERFLOW mode
	ldi temp, 0b00000001
	sts 0x006f, temp
	sei

	; TIMER1 counter start value: 0x85EE (34286 ticks)
	ldi r30, 0x85      
	ldi r31, 0xEE
    sts 0x085, r30    
    sts 0x084, r31

	; Predivider: Clk/256
	ldi temp, 0b00000100
    sts 0x081, temp 

	; Port initialization
	clr temp
	out DDRC, temp
	ldi temp, 0b00000001
	out PORTC, temp
	ldi temp, 0b00000111
	out DDRB, temp

	ldi RedColor, 0b00000100
	ldi YellowColor, 0b00000010
	ldi GreenColor, 0b00000001
	ldi RedAndYellowColor, 0b00000110
	ldi NoColor, 0b00000000

Main:
	; Listen to the mode selection button
	in CurrentMode, PINC
	cpi CurrentMode, 0x01
	breq NightMode
	rjmp DayMode

NightMode:
	sts 0x0200, TickCounter
	; Depending on the counter value, go to the specified label
	; Every 0.5 seconds TickCounter increases by 1
	cpi TickCounter, 0x00
	breq NightMode_YellowOn

	cpi TickCounter, 0x02
	breq NightMode_YellowOff

	cpi TickCounter, 0x04
	brsh NightMode_ClearCounter

	rjmp Main

NightMode_YellowOn:
	out PORTB, YellowColor
	rjmp NightMode

NightMode_YellowOff:
	out PORTB, NoColor
	rjmp NightMode

NightMode_ClearCounter:
	clr TickCounter
	rjmp NightMode

DayMode:
	sts 0x0200, TickCounter
	; Depending on the counter value, go to the specified label
	; Every 0.5 seconds TickCounter increases by 1
	cpi TickCounter, 0x00
	breq DayMode_RedOn

	cpi TickCounter, 0x0A
	breq DayMode_RedAndYellowOn
		
	cpi TickCounter, 0x10
	breq DayMode_GreenOn

	cpi TickCounter, 0x14
	breq DayMode_GreenOff

	cpi TickCounter, 0x15
	breq DayMode_GreenOn

	cpi TickCounter, 0x16
	breq DayMode_GreenOff

	cpi TickCounter, 0x17
	breq DayMode_GreenOn

	cpi TickCounter, 0x18
	breq DayMode_GreenOff

	cpi TickCounter, 0x19
	breq DayMode_GreenOn

	cpi TickCounter, 0x1A
	breq DayMode_YellowOn

	cpi TickCounter, 0x20
	brsh DayMode_ClearCounter 

	rjmp Main

DayMode_RedOn:
	out PORTB, RedColor
	rjmp DayMode

DayMode_RedAndYellowOn:
	out PORTB, RedAndYellowColor
	rjmp DayMode

DayMode_GreenOn:
	out PORTB, GreenColor
	rjmp DayMode

DayMode_GreenOff:
	out PORTB, NoColor
	rjmp DayMode

DayMode_YellowOn:
	out PORTB, YellowColor
	rjmp DayMode

DayMode_ClearCounter:
	clr TickCounter
	rjmp DayMode

; TIMER1 OVERFLOW
TIMER1_OVF:            
	inc TickCounter

	; TIMER1 counter start value: 0x85EE (34286 ticks)
	sts 0x085, r30
	sts 0x084, r31

    reti     