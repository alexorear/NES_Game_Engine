	.inesprg 1 ; Defines the number of 16kb PRG banks
	.ineschr 1 ; Defines the number of 8kb CHR banks
	.inesmap 0 ; Defines the NES mapper
	.inesmir 1 ; Defines the VRAM mirroring

; Variable declarations
	.rsset $0000

marioRAM = $0200


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

vblankwait2:
	BIT $2002 ; bit test to check if one or more bits are set at mem location $2002
	BPL vblankwait2 ; brank if negative flag is 0

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

LoadMarioMetaSprite:
	LDX #$00

.Loop:
	LDA marioMetaSprite, x
	STA marioRAM, x
	INX
	CPX #$10
	BNE .Loop

	LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
	STA $2000
	LDA #%00011110
	STA $2001

Forever: ; infinite loop that keeps our program running
	JMP Forever

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

NMI:
	LDA #$00
	STA $2003
	LDA #$02
	STA $4014

	JSR ReadPlayerOneControls
	JSR UpdateMario

	LDA #%10000000
	STA $2000
	LDA #%00010110
	STA $2001
	LDA #$00        ;;tell the ppu there is no background scrolling
  STA $2005
  STA $2005
	RTI

	.bank 1 ; second prgramming block of code
	.org $E000

palette:
	.db $21,$05,$26,$17, $21,$02,$1c,$31, $21,$07,$17,$27, $21,$09,$19,$29 ;sprite palette
	.db $21,$20,$0c,$19, $21,$07,$17,$27, $21,$2d,$0f,$30, $21,$09,$19,$29 ;background palette


marioMetaSprite:
	.db $80, $36, $00, $80
	.db $80, $37, $00, $88
	.db $88, $38, $00, $80
	.db $88, $39, $00, $88

	.org $FFFA ; defines thee 3 interups
	.dw NMI ; jumps to NMI once perframe during vblank
	.dw RESET ; jumps to RESET when processor first turns on or is reset
	.dw 0 ; external interrupt for IRQ not currently used

	.bank 2 ; first CHR-ROM page
	.org $0000 ; begin storing code at mem location $0000
	.incbin "mario.chr" ; 8KB graphics file
