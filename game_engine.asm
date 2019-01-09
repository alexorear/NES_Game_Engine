	.inesprg 1 ; Defines the number of 16kb PRG banks
	.ineschr 1 ; Defines the number of 8kb CHR banks
	.inesmap 0 ; Defines the NES mapper
	.inesmir 1 ; Defines the VRAM mirroring

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

	paletteLoop:
		LDA palette, x
		STA $2007
		INX
		CPX #$20
		BNE paletteLoop

		LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
		STA $2000
		LDA #%00011110
		STA $2001

Forever: ; infinite loop that keeps our program running
	JMP Forever

NMI:
	RTI

	.bank 1 ; second prgramming block of code
	.org $E000

palette:
	.db $22,$29,$1A,$0F,  $22,$36,$17,$0F,  $22,$30,$21,$0F,  $22,$27,$17,$0F   ;background palette
	.db $22,$1C,$15,$14,  $22,$02,$38,$3C,  $22,$1C,$15,$14,  $22,$02,$38,$3C   ;sprite palette

	.org $FFFA ; defines thee 3 interups
	.dw NMI ; jumps to NMI once perframe during vblank
	.dw RESET ; jumps to RESET when processor first turns on or is reset
	.dw 0 ; external interrupt for IRQ not currently used

	.bank 2 ; first CHR-ROM page
	.org $0000 ; begin storing code at mem location $0000
	.incbin "mario.chr" ; 8KB graphics file
