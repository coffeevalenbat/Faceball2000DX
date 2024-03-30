DEF INDEX_BASE  EQU $C0  ;Palette register becomes this before loading in a new set
DEF NUM_INDICES EQU $40  ;Number of bytes per stack of palettes

_LoadPalettes:
    ldh a, [hCGB]
    cp a, IS_SGB
    jr z, .sgb
    cp a, IS_CDMG
    jr z, .fakeDMG
    ld hl, BGPalList
    jr .loadpals

.fakeDMG
    ld hl, DMGBGPalList
.loadpals
    ld a, INDEX_BASE
    ldh [rBGPI], a  ;Prepare BGP register to handle changes
    ld a, c
    add a, c
    ld c, a
    add hl, bc
    ld b, h
    ld c, l
    ld a, [bc]
    ld l, a
    inc bc
    ld a, [bc]
    ld h, a
    ld c, NUM_INDICES
.pal_load_stat_check
    ldh a, [rSTAT]
    and a, 3
    cp a, 2
    jr nc, .pal_load_stat_check
    ld a, [hli]
    ldh [rBGPD], a
    dec c
    ld a, c
    and a  ;Check if all palette indices have been cycled through
    jr nz, .pal_load_stat_check
    ret

.sgb
    ld a, [hCurrentLayout]
    ld b, a
    call GetSGBLayout
    call SGB_PushPacket
    ret

BGPalList::
    dw BGPal0
    dw BGPal1
    dw BGPal2
    dw BGPal3

DMGBGPalList::
    dw DMGBGPal0
    dw DMGBGPal1
    dw DMGBGPal2
    dw DMGBGPal3

_LoadTileAttrs:
    ldh a, [hCGB]
    and a ; IS_DMG
    ret z
    cp IS_SGB
    jr z, .sgb

    ld l, b
	ld h, 0
	add hl, hl
	ld de, CGBLayoutJumpTable
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
    ld de, _LoadCGBLayout_ReturnFromJumptable
    push de
    jp hl

.sgb
	ld a, b
    cp a, SCGB_BPS_LOGO
    jr z, .skip
	ld [hCurrentLayout], a
.skip
    call GetSGBLayout
    push de
    call SGB_PushPacket
	call SGB_Delay
    pop hl
    jp SGB_PushPacket

_LoadCGBLayout_ReturnFromJumptable:
    ld c, $14
    ld hl, _SCRN0
    ld a, 1
    ld [rVBK], a
;.tile_attr_stat_check
;    ldh a, [rSTAT]
;    and a, 3
;    cp a, 2
;    jr nc, .tile_attr_stat_check
    push bc
    call DisableLCD
    pop bc
.load_attrs
    ld a, [de]
    inc de
    ld [hli], a
    dec c
    jr nz, .load_attrs
.go_to_next_row
    push de
    ld d, 0
    ld e, $0C
    add hl, de
    pop de
    ld c, $14
    dec b
    jr nz, .load_attrs
.done_doing_attrs
    call EnableLCD
    xor a
    ld [rVBK], a
    ret

CGBLayoutJumpTable::
	dw .CGB_BPSLogo
	dw .CGB_BPSLogo
	dw .CGB_Copyright
	dw .CGB_TitleScreen
	dw .CGB_InterFace
	dw .CGB_TeamPlay
	dw .CGB_Gameplay
	dw .CGB_Gameplay ; but only above HUD
	dw .CGB_InterFace ; but only above HUD

.CGB_BPSLogo:
    ld de, TileAttrBPSLogo
    ld b, $12
    ret

.CGB_Copyright:
    ld de, TileAttrCopyright
    ld b, $12
    ret

.CGB_TitleScreen:
    ld de, TileAttrTitle
    ld b, $12
    ret

.CGB_InterFace:
    ld de, TileAttrInterFace
    ld b, $12
    ret

.CGB_TeamPlay:
    ld de, TileAttrTeamPlay
    ld b, $12
    ret

.CGB_Gameplay:
    ld de, TileAttrGameplay
    ld b, $12
    ret

DisableLCD::
; Turn the LCD off

; Don't need to do anything if the LCD is already off
	ldh a, [rLCDC]
	bit LCDCB_ON, a
	ret z

	xor a
	ldh [rIF], a
	ldh a, [rIE]
	ld b, a

; Disable VBlank
	res IEB_VBLANK, a
	ldh [rIE], a

.wait
; Wait until VBlank would normally happen
	ldh a, [rLY]
	cp SCRN_Y + 1
	jr nz, .wait

	ldh a, [rLCDC]
	and ~(1 << LCDCB_ON)
	ldh [rLCDC], a

	xor a
	ldh [rIF], a
	ld a, b
	ldh [rIE], a
	ret

EnableLCD::
	ldh a, [rLCDC]
	set LCDCB_ON, a
	ldh [rLCDC], a
	ret

BGPal0::
    RGB 31,31,31, 15,15,15, 07,07,07, 00,00,00 ; Grayscale
    RGB 00,11,31, 31,31,00, 00,31,10, 00,00,00 ; Main gameplay
    RGB 16,30,00, 00,20,00, 00,12,00, 00,00,00 ; Inter-Face
    RGB 31,31,31, 30,24,00, 24,00,00, 00,00,00 ; Title screen
    RGB 12,18,22, 08,12,18, 04,08,12, 00,00,00 ; HUD border
    RGB 16,20,22, 30,24,00, 30,00,00, 00,00,00 ; HUD text/smiley
    RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31 ; BPS wordmark
    RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31 ; BPS logo
BGPal1::
    RGB 31,31,31, 27,27,27, 19,19,19, 12,12,12 ; Grayscale
    RGB 12,23,31, 31,31,12, 12,31,22, 12,12,12 ; Main gameplay
    RGB 29,31,12, 12,31,12, 12,24,12, 12,12,12 ; Inter-Face
    RGB 31,31,31, 31,31,12, 31,12,12, 12,12,12 ; Title screen
    RGB 24,31,31, 20,24,31, 16,20,24, 12,12,12 ; HUD border
    RGB 29,31,31, 31,31,12, 31,12,12, 12,12,12 ; HUD text/smiley
    RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31 ; BPS wordmark
    RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31 ; BPS logo
BGPal2::
    RGB 31,31,31, 31,31,31, 31,31,31, 25,25,25 ; Grayscale
    RGB 25,31,31, 31,31,25, 25,31,31, 25,25,25 ; Main gameplay
    RGB 31,31,25, 25,31,25, 25,31,25, 25,25,25 ; Inter-Face
    RGB 31,31,31, 31,31,25, 31,25,25, 25,25,25 ; Title screen
    RGB 31,31,31, 31,31,31, 29,31,31, 25,25,25 ; HUD border
    RGB 31,31,31, 31,31,25, 31,25,25, 25,25,25 ; HUD text/smiley
    RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31 ; BPS wordmark
    RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31 ; BPS logo
BGPal3::
    RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31 ; Grayscale
    RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31 ; Main gameplay
    RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31 ; Inter-Face
    RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31 ; Title screen
    RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31 ; HUD border
    RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31 ; HUD text/smiley
    RGB 31,31,31, 00,03,14, 19,18,29, 10,12,28 ; BPS wordmark
    RGB 31,31,31, 00,00,00, 17,31,24, 08,21,13 ; BPS logo

DMGBGPal0::
    RGB 31,31,31, 15,15,15, 07,07,07, 00,00,00 ; Grayscale
    RGB 31,31,31, 15,15,15, 07,07,07, 00,00,00 ; Main gameplay
    RGB 31,31,31, 15,15,15, 07,07,07, 00,00,00 ; Inter-Face
    RGB 31,31,31, 15,15,15, 07,07,07, 00,00,00 ; Title screen
    RGB 31,31,31, 15,15,15, 07,07,07, 00,00,00 ; HUD border
    RGB 31,31,31, 15,15,15, 07,07,07, 00,00,00 ; HUD text/smiley
    RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31 ; BPS wordmark
    RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31 ; BPS logo
DMGBGPal1::
    RGB 31,31,31, 27,27,27, 19,19,19, 12,12,12 ; Grayscale
    RGB 31,31,31, 27,27,27, 19,19,19, 12,12,12 ; Main gameplay
    RGB 31,31,31, 27,27,27, 19,19,19, 12,12,12 ; Inter-Face
    RGB 31,31,31, 27,27,27, 19,19,19, 12,12,12 ; Title screen
    RGB 31,31,31, 27,27,27, 19,19,19, 12,12,12 ; HUD border
    RGB 31,31,31, 27,27,27, 19,19,19, 12,12,12 ; HUD text/smiley
    RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31 ; BPS wordmark
    RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31 ; BPS logo
DMGBGPal2::
    RGB 31,31,31, 31,31,31, 31,31,31, 25,25,25 ; Grayscale
    RGB 31,31,31, 31,31,31, 31,31,31, 25,25,25 ; Main gameplay
    RGB 31,31,31, 31,31,31, 31,31,31, 25,25,25 ; Inter-Face
    RGB 31,31,31, 31,31,31, 31,31,31, 25,25,25 ; Title screen
    RGB 31,31,31, 31,31,31, 31,31,31, 25,25,25 ; HUD border
    RGB 31,31,31, 31,31,31, 31,31,31, 25,25,25 ; HUD text/smiley
    RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31 ; BPS wordmark
    RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31 ; BPS logo
DMGBGPal3::
    RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31 ; Grayscale
    RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31 ; Main gameplay
    RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31 ; Inter-Face
    RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31 ; Title screen
    RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31 ; HUD border
    RGB 31,31,31, 31,31,31, 31,31,31, 31,31,31 ; HUD text/smiley
    RGB 31,31,31, 00,00,00, 15,15,15, 07,07,07 ; BPS wordmark
    RGB 31,31,31, 00,00,00, 15,15,15, 07,07,07 ; BPS logo

TileAttrBPSLogo::
    db $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06
    db $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06
    db $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06
    db $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06
    db $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06
    db $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06
    db $06, $06, $06, $06, $06, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07
    db $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07
    db $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07
    db $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07
    db $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07
    db $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07
    db $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07
    db $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07
    db $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07
    db $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07
    db $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07
    db $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07

TileAttrCopyright::
    db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
    db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
    db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
    db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
    db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
    db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
    db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
    db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
    db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
    db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
    db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
    db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
    db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
    db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
    db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
    db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
    db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
    db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05

TileAttrTitle::
    db $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
    db $04, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $04
    db $04, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $04
    db $04, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $04
    db $04, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $04
    db $04, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $04
    db $04, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $04
    db $04, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $04
    db $04, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $04
    db $04, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $04
    db $04, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $04
    db $04, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $04
    db $04, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $04
    db $04, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $04
    db $04, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $04
    db $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
    db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
    db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05

TileAttrInterFace::
    db $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
    db $04, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $04
    db $04, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $04
    db $04, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $04
    db $04, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $04
    db $04, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $04
    db $04, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $04
    db $04, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $04
    db $04, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $04
    db $04, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $04
    db $04, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $04
    db $04, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $04
    db $04, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $04
    db $04, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $04
    db $04, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $04
    db $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
    db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
    db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05

TileAttrTeamPlay::
    db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02
    db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02
    db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02
    db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02
    db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02
    db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02
    db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02
    db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02
    db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02
    db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02
    db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02
    db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02
    db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02
    db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02
    db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02
    db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02
    db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
    db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05

TileAttrGameplay::
    db $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
    db $04, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $04
    db $04, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $04
    db $04, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $04
    db $04, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $04
    db $04, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $04
    db $04, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $04
    db $04, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $04
    db $04, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $04
    db $04, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $04
    db $04, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $04
    db $04, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $04
    db $04, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $04
    db $04, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $04
    db $04, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $04
    db $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $05, $05, $05, $04
    db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $04, $05, $05, $05, $04
    db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $04, $05, $05, $05, $04
