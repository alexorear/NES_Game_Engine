; Read input controls to set x/y position of player
; sprite 1. Other sprite positions will be updated based
; on this sprite
ReadPlayerOneControls:
	LDA #$01
	STA $4016
	LDA #$00
	STA $4016

	LDA $4016 ; player 1 - A
	LDA $4016	; player 1 - B
	LDA $4016	; player 1 - Select
	LDA $4016	; player 1 - Start

ReadUp:
	LDA $4016
	AND #%00000001
	BEQ EndReadUp

	LDA marioRAM
	SEC
	SBC #$01
	STA marioRAM
EndReadUp:

ReadDown:
	LDA $4016
	AND #%00000001
	BEQ EndReadDown

	LDA marioRAM
	CLC
	ADC #$01
	STA marioRAM
EndReadDown:

ReadLeft:
	LDA $4016
	AND #%00000001
	BEQ EndReadLeft

	LDA #$01
	STA marioDirection
	LDA marioRAM+3
	SEC
	SBC #$01
	STA marioRAM+3
EndReadLeft:

ReadRight:
	LDA $4016
	AND #%00000001
	BEQ EndReadRight

	LDA #$00
	STA marioDirection
	LDA marioRAM+3
	CLC
	ADC #$01
	STA marioRAM+3
EndReadRight:
	RTS
