	.inesprg 1 ; Defines the number of 16kb PRG banks
	.ineschr 1 ; Defines the number of 8kb CHR banks
	.inesmap 0 ; Defines the NES mapper
	.inesmir 1 ; Defines the VRAM mirroring

; Variable declarations
	.rsset $0000

marioMetaSpriteRAM = $0200


	.bank 0 ; first 8kb of PRG-ROM
	.org $C000 ; Begin bank 0 code a Memory Address $C000

RESET:
	SEI	; Disable interup request
	CLD	; Disable decimal mode
	LDX #$40
	STX $4017	; this disables APU

	LDX #$FF
	TXS ; Transfer x value ($FF) to stack
	INX
	STX $2000 ; Disable NMI
	STX $2001	; Disable rendering
	STX $4010 ; DIsavle APU Data Modulation Channel

vblankwait1:
	BIT $2002 ; bit test to check if one or more bits are set at mem location $2002
	BPL vblankwait1 ; brank if negative flag is 0

clearmem:
	LDA #$00
	STA $0000, x
	STA $0100, x
	STA $0200, x
	STA $0400, x
	STA $0500, x
	STA $0600, x
	STA $0700, x

	LDA #$FE
	STA $0300, x
	INX
	BNE clearmem

vblankwait2:
	BIT $2002 ; bit test to check if one or more bits are set at mem location $2002
	BPL vblankwait2 ; brank if negative flag is 0

loadPalettes:
	LDA $2002 ; read/clear ppu status
	LDA #$3F
	STA $2006 ; tell the ppu to write incoming bits to
	LDA #$10	; ppu starting at address $3F10
	STA $2006
	LDX #$00

.loop
	LDA palette, x
	STA $2007
	INX
	CPX #$20
	BNE .loop

	LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
	STA $2000
	LDA #%00010110
	STA $2001

loadMarioMetaSprite:
	LDX #$00

.loop
	LDA marioMetaSprite, x
	STA marioMetaSpriteRAM, x
	INX
	CPX #$10
	BNE .loop
	RTS


Forever: ; infinite loop that keeps our program running
	JMP Forever

NMI:
	LDA #$00
	STA $2003
	LDA #$02
	STA $4014

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
