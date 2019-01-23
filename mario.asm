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

SetDirection:
	LDA marioDirection
	CMP #$00
	BEQ StandRight
	CMP #$01
	BEQ StandLeft

DirectionFinished:
	RTS

StandRight:
	LDA #$32
	STA marioRAM+1
	LDA #$33
	STA marioRAM+5
	LDA #$02
	STA marioRAM+2
	STA marioRAM+6
	LDA #$4F
	STA marioRAM+9
	STA marioRAM+13
	JMP DirectionFinished

StandLeft:
	LDA #$33
	STA marioRAM+1
	LDA #$32
	STA marioRAM+5
	LDA #$42
	STA marioRAM+2
	STA marioRAM+6
	LDA #$4F
	STA marioRAM+9
	STA marioRAM+13
	JMP DirectionFinished
