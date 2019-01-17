	.inesprg 1 ; Defines the number of 16kb PRG banks
	.ineschr 1 ; Defines the number of 8kb CHR banks
	.inesmap 0 ; Defines the NES mapper
	.inesmir 1 ; Defines the VRAM mirroring

; Variable declarations
	.rsset $0000
goombaNumber .rs 1
animationFrameCount .rs 1
animationCount .rs 1

counter .rs 1
pointerBackgroundLowByte .rs 1
pointerBackgroundHighByte .rs 1

marioRAM = $0200
goombaARAM = $0210
goombaBRAM = $0220

	.bank 0 ; first 8kb of PRG-ROM
	.org $C000 ; Begin bank 0 code a Memory Address $C000

RESET:
	SEI	; Disable interup request
	CLD	; Disable decimal mode
	LDX #$40
	STX $4017	; this disables APU

	; TXS ; Transfer x value ($FF) to stack
	; LDX #$FF
	LDX #$00
	STX $2000 ; Disable NMI
	STX $2001	; Disable rendering
	STX $4010 ; DIsavle APU Data Modulation Channel

vblankwait1:
	BIT $2002 ; bit test to check if one or more bits are set at mem location $2002
	BPL vblankwait1 ; brank if negative flag is 0

Clearmem:
	LDA #$00
	STA $0000, x
	STA $0100, x
	STA $0300, x
	STA $0400, x
	STA $0500, x
	STA $0600, x
	STA $0700, x
	LDA #$FE
	STA $0200, x
	INX
	BNE Clearmem
	STA counter
	STA animationCount
	STA animationFrameCount

vblankwait2:
	BIT $2002 ; bit test to check if one or more bits are set at mem location $2002
	BPL vblankwait2 ; brank if negative flag is 0

; GAME SETUP - Background w/ attributes, palettes, sprites
Loadbackground:
	LDA $2002
	LDA #$20
	STA $2006
	LDA #$00
	STA $2006

	LDA #LOW(background)
	STA pointerBackgroundLowByte
	LDA #HIGH(background)
	STA pointerBackgroundHighByte

	LDX #$00
	LDY #$00
.Loop:
	LDA [pointerBackgroundLowByte], y
	STA $2007
	INY
	CPY #$00
	BNE .Loop

	INC pointerBackgroundHighByte
	INX
	CPX #$04
	BNE .Loop

LoadAttributes:
	LDA $2002
	LDA #$23
	STA $2006
	LDA #$C0
	STA $2006
	LDX #$00
.Loop:
	LDA attributes, x
	STA $2007
	INX
	CPX #$40
	BNE .Loop

	LDA $2002
	LDA #$27
	STA $2006
	LDA #$C0
	STA $2006
	LDX #$00
.LoopA:
	LDA attributes, x
	STA $2007
	INX
	CPX #$40
	BNE .LoopA

LoadPalettes:
	LDA $2002 ; read/clear ppu status
	LDA #$3F
	STA $2006 ; tell the ppu to write incoming bits to
	LDA #$10	; ppu starting at address $3F10
	STA $2006
	LDX #$00

.Loop:
	LDA palette, x
	STA $2007
	INX
	CPX #$20
	BNE .Loop


LoadMetaSprites:
	LDX #$00
.Loop:
	LDA marioMetaSprite, x
	STA marioRAM, x
	LDA goombaMetaASprite, x
	STA goombaARAM, x
	LDA goombaMetaBSprite, x
	STA goombaBRAM, x
	INX
	CPX #$10
	BNE .Loop

	LDA #%10000000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
	STA $2000
	LDA #%00011110
	STA $2001


Forever: ; infinite loop that keeps our program running
	JMP Forever

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

	LDA marioRAM+3
	SEC
	SBC #$01
	STA marioRAM+3
EndReadLeft:

ReadRight:
	LDA $4016
	AND #%00000001
	BEQ EndReadRight

	LDA marioRAM+3
	CLC
	ADC #$01
	STA marioRAM+3
EndReadRight:
	RTS

CheckFrameCounter:
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
	LDA animationFrameCount
	CMP #$00
	BNE resetAnimationFrameCount
	INC animationFrameCount
	RTS

resetAnimationFrameCount
	LDA #$00
	STA animationFrameCount
	RTS

AnimationCheck:
	LDA animationCount
	CMP #$08
	BNE .AnimationCheckDone

	LDA animationFrameCount
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


NMI:
	LDA #$00
	STA $2003
	LDA #$02
	STA $4014

	JSR CheckFrameCounter
	JSR ReadPlayerOneControls
	JSR UpdateMario
	;JSR AnimationCheck


	LDA #%10010000
	STA $2000
	LDA #%00011110
	STA $2001
	LDA #$00        ;;tell the ppu there is no background scrolling
  STA $2005
  STA $2005
	RTI

	.bank 1 ; second prgramming block of code
	.org $E000

background:
	.include "background.asm"
attributes:
	.include "attributes.asm"

palette:
	.db $21,$05,$26,$17, $21,$02,$1c,$31, $21,$07,$27,$17, $21,$09,$19,$29 ;sprite palette
	.db $21,$20,$0c,$19, $21,$07,$17,$27, $21,$2d,$30,$0f, $21,$09,$19,$29 ;background palette


marioMetaSprite:
	.db $C0, $36, $02, $10
	.db $C0, $37, $02, $18
	.db $C8, $38, $02, $10
	.db $C8, $39, $02, $18

goombaMetaASprite:
	.db $C0, $70, $02, $80
	.db $C0, $71, $02, $88
	.db $C8, $72, $02, $80
	.db $C8, $73, $02, $88

goombaMetaBSprite:
	.db $C0, $70, $02, $A0
	.db $C0, $71, $02, $A8
	.db $C8, $73, %01000010, $A0
	.db $C8, $72, %01000010, $A8

updateGoombaConstants: ; gooba meta sprites
	.db $00,$10 ; we start at $10 because the mario sprite is at address $00

	.org $FFFA ; defines thee 3 interups
	.dw NMI ; jumps to NMI once perframe during vblank
	.dw RESET ; jumps to RESET when processor first turns on or is reset
	.dw 0 ; external interrupt for IRQ not currently used

	.bank 2 ; first CHR-ROM page
	.org $0000 ; begin storing code at mem location $0000
	.incbin "mario.chr" ; 8KB graphics file
