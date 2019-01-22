CheckGoomaFrameCounter:
	LDA counter
	CMP #$02
	BEQ UpdateGoombas
	INC counter
	RTS

UpdateGoombas:
	LDX #$00
	STX counter
	STX goombaNumber
.Loop:
	JSR UpdateGoombaPosition
	JSR AnimationCheck
	INC goombaNumber
	LDA goombaNumber
	CMP #$02
	BNE .Loop
UpdateGoombasDone:
	JSR updateAnimationCount
	JSR updateAnimationFrameCount
	RTS

UpdateGoombaPosition:
	LDX goombaNumber
	LDA updateGoombaConstants, x
	TAX
	LDA goombaARAM+3, x
	SEC
	SBC #$01
	STA goombaARAM+3, x
	STA goombaARAM+11, x
	CLC
	ADC #$08
	STA goombaARAM+7, x
	STA goombaARAM+15, x
	RTS

updateAnimationCount:
	LDA animationCount
	CMP #$08
	BEQ resetAnimationCount
	INC animationCount
	RTS

resetAnimationCount:
	LDA #$00
	STA animationCount
	RTS

updateAnimationFrameCount
	LDA goombaAnimationFrameCount
	CMP #$00
	BNE resetAnimationFrameCount
	INC goombaAnimationFrameCount
	RTS

resetAnimationFrameCount
	LDA #$00
	STA goombaAnimationFrameCount
	RTS

AnimationCheck:
	LDA animationCount
	CMP #$08
	BNE .AnimationCheckDone

	LDA goombaAnimationFrameCount
	CMP #$00
	BEQ .GoombaAnimation0
	CMP #$01
	BEQ .GoombaAnimation1

	LDA #$00
	STA animationCount

.GoombaAnimation0:
	LDX goombaNumber
	LDA updateGoombaConstants, x
	TAX
	LDA #$72
	STA goombaARAM+9, x
	LDA #$73
	STA goombaARAM+13, x
	LDA #$02
	STA goombaARAM+10, x
	STA goombaARAM+14,x
	JMP .AnimationCheckDone

.GoombaAnimation1:
	LDX goombaNumber
	LDA updateGoombaConstants, x
	TAX
	LDA #$73
	STA goombaARAM+9, x
	LDA #$72
	STA goombaARAM+13, x
	LDA #%01000010
	STA goombaARAM+10, x
	STA goombaARAM+14, x
	JMP .AnimationCheckDone

.AnimationCheckDone:
	RTS
