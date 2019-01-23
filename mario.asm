; allows for moving all player sprites at onces
UpdateMario:
	LDA marioRAM	; vertical updates
	STA marioRAM+4
	CLC
	ADC #$08
	STA marioRAM+8
	STA marioRAM+12

	LDA marioRAM+3 ; horizontal updates
	STA marioRAM+11
	CLC
	ADC #$08
	STA marioRAM+7
	STA marioRAM+15
	RTS

SetDirection:
	LDA marioState
	CMP #$00
	BEQ FaceRight
	CMP #$01
	BEQ FaceLeft
	RTS

FaceRight:
	LDA $33
	STA marioRAM+2
	 
