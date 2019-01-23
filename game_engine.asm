	.inesprg 1 ; Defines the number of 16kb PRG banks
	.ineschr 1 ; Defines the number of 8kb CHR banks
	.inesmap 0 ; Defines the NES mapper
	.inesmir 1 ; Defines the VRAM mirroring

; Variable declarations
	.rsset $0000
goombaNumber .rs 1
goombaAnimationFrameCount .rs 1
animationCount .rs 1
marioDirection .rs 1

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
	STA goombaAnimationFrameCount
	STA marioDirection

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

	.include "read_controllers.asm"
	.include "mario.asm"
	.include "goombas.asm"

NMI:
	LDA #$00
	STA $2003
	LDA #$02
	STA $4014

	JSR CheckGoomaFrameCounter
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

backgroundSolid:
	.include "background_solid.asm"

pipeColision:
	.db %00000000, %00000011, %11000000, %00000000

attributes:
	.include "attributes.asm"

palette:
	.db $21,$05,$26,$17, $21,$02,$1c,$31, $21,$07,$27,$17, $21,$09,$19,$29 ;sprite palette
	.db $21,$20,$0c,$19, $21,$07,$17,$27, $21,$2d,$30,$0f, $21,$09,$19,$29 ;background palette


marioMetaSprite:
	; walking 1
	; .db $C0, $32, $02, $10
	; .db $00, $33, $02, $18
  ; .db $C8, $34, $02, $10
	; .db $C8, $35, $02, $18

	; walking 2
	; .db $C0, $3a, $02, $10
	; .db $00, $37, $02, $18
  ; .db $C8, $3b, $02, $10
	; .db $C8, $3c, $02, $18

	; walking 3
	; .db $C0, $36, $02, $10
	; .db $C0, $37, $02, $18
	; .db $C8, $38, $02, $10
	; .db $C8, $39, $02, $18

	; standing
	.db $A0, $32, $02, $78
	.db $A0, $33, $02, $80
	.db $A8, $4f, $02, $78
	.db $A8 ,$4f, $42, $80


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
