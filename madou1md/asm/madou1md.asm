*********************************************************************
*                                                                   *
*********************************************************************

* Position of replacement script data table.
* Consists of a pointer table to each new script by ID number.
newScriptDataPos equ $210000

* Location of newly added code
newCodePos equ $300000

* Start of script processing loop
scriptHandlerLoop equ $48D32

opcodeHandlerTable equ $48D96
opD0HandlerPointerAddr equ opcodeHandlerTable+$D0
opD0Id equ $FFD0
opF8HandlerPointerAddr equ opcodeHandlerTable+$F8
opF8Id equ $FFF8
opBrId equ $FF30

* offsets to script object data within object slot
scriptObj_linePos equ $2C
scriptObj_baseVdpPatternDst equ $38
scriptObj_srcAddr equ $40
scriptObj_currentNametableAddr equ $4C
scriptObj_modeLow equ $50

* enemy name ID for cait siths
caitSithsIdNum equ $11

* ID of enemy in a-capsule (byte)
capsuleMonsterId equ $FFFFF9D5
* ID of monster being encountered (byte)
encounteredMonsterId equ $FFFF8003
* ID of item being picked up (byte)
pickedUpItemId equ $FFFF84D8

dynamicLoadStatus equ $FFFF9616

scriptActiveFlags equ $FFFF86FE
  
itemId_hungryElephant equ $14
itemId_fireExtinguisher equ $24

* object properties
obj_flags0           equ $00
obj_updateRoutine    equ $02
obj_flags6           equ $06
obj_flags7           equ $07
obj_type             equ $08
obj_subtype          equ $09

obj_flags6_drawFlag  equ $80
  
*********************************************************************
* old routines
*********************************************************************

* set up VDP for write to address in D5
* interrupts should be off
setUpVramWrite equ $49992

queueDynamicLoad equ $A72
addSpritesToBuffer equ $1856
mult8x16 equ $1230C
clearNametableArea equ $14618

spawnObj equ $1122
spawnChildObj equ $1196
killObj equ $11D4
objSetResumePointAndYield equ $122C
objSetResumePoint equ $1236

sendTilemap_karaoke equ $8FFB0

runCutsceneScript equ $48CFA

*********************************************************************
* Mega Drive defines
*********************************************************************

patternSize equ $20
patternW equ 8
patternH equ 8
patternRowByteSize equ 4

vdpDataPort equ $00C00000
vdpControlPort equ $00C00004
  
*********************************************************************
* Font defines
*********************************************************************

numKernableChars equ $80

spaceCharIndex equ $4A

nullchar equ $00
space1px equ $70
space2px equ $71
space3px equ $72
space4px equ $73
space5px equ $74
space6px equ $75
space7px equ $76
space8px equ $77
space16px equ $78
space0px equ $7F
  
*********************************************************************
* VWF buffer struct
*********************************************************************


vwfPatBufSize equ patternSize*2
vwfPatBufHalfSize equ vwfPatBufSize/2
vwfActiveArraySize equ 4

vwfBufferStruct_start equ 0
* 4 bytes corresponding to each pattern buffer
vwfBufferStruct_activeArray equ vwfBufferStruct_start+0
* 1 byte each
vwfBufferStruct_penPos equ vwfBufferStruct_activeArray+vwfActiveArraySize
vwfBufferStruct_transStart equ vwfBufferStruct_penPos+1
vwfBufferStruct_transWidth equ vwfBufferStruct_transStart+1
vwfBufferStruct_penStart equ vwfBufferStruct_transWidth+1
* 2 bytes
vwfBufferStruct_lastChar equ vwfBufferStruct_penStart+1
* 2 bytes
vwfBufferStruct_lastNonSpaceChar equ vwfBufferStruct_lastChar+2
* 4 bytes
vwfBufferStruct_transAdvanceWidth equ vwfBufferStruct_lastNonSpaceChar+2
vwfBufferStruct_lineOverhang equ vwfBufferStruct_transAdvanceWidth+1
*vwfBufferStruct_lineOverhang equ vwfBufferStruct_linePos+1
*vwfBufferStruct_kerningOffset equ vwfBufferStruct_lineOverhang+1
vwfBufferStruct_putPos equ vwfBufferStruct_lineOverhang+1
* pattern composition buffers, 8x16 pixels each
vwfBufferStruct_patbuf0 equ vwfBufferStruct_putPos+2
vwfBufferStruct_patbuf1 equ vwfBufferStruct_patbuf0+vwfPatBufSize
vwfBufferStruct_patbuf2 equ vwfBufferStruct_patbuf1+vwfPatBufSize
vwfBufferStruct_patbuf3 equ vwfBufferStruct_patbuf2+vwfPatBufSize
vwfBufferStruct_end equ vwfBufferStruct_patbuf3+vwfPatBufSize
vwfBufferStruct_size equ vwfBufferStruct_end-vwfBufferStruct_start

vwfGlyphData_glyphWidth equ 0
vwfGlyphData_advanceWidth equ 1
  
*********************************************************************
* Memory layout
*********************************************************************

* VWF buffers for each of the possible target boxes
*vwfBuffersStart equ $FFFF2D00
* 9C00-9E00 is used for stuff related to hscroll table effects
* (on e.g. monster capsule animations).
*vwfBuffersStart equ $FFFF9C00
vwfBuffersStart equ $FFFFC080
*vwfBuffer0Pos equ vwfBuffersStart+(vwfBufferStruct_size*0)
*vwfBuffer1Pos equ vwfBuffersStart+(vwfBufferStruct_size*1)
*vwfBuffer2Pos equ vwfBuffersStart+(vwfBufferStruct_size*2)
vwfBuffer0Pos equ $FFFF9E00
* this is stack memory... safe?
vwfBuffer1Pos equ $FFFFFC00
* conflicts with hscroll table, but shouldn't ever be used
* simultaneously with it
vwfBuffer2Pos equ $FFFF9C00
* NOTE: buffer 3 should never get written to. the game only uses
* IDs 0-2.
* but in case there's a surprise somewhere, it's supported here.
vwfBuffer3Pos equ vwfBuffersStart+(vwfBufferStruct_size*3)

* looks like buffer 3 won't be used, so here's our extra memory
freeMemoryStart equ vwfBuffer3Pos

*capsuleReleaseEnemyId equ freeMemoryStart+0

*********************************************************************
* DEBUG
*********************************************************************

**********************************
* uncomment for no random encounters
**********************************

*   org $390C
*   jmp $283E

**********************************
* random momomo puyoman sale
* event on 11F (3,6) always
* trigers
**********************************

*   org $4426E
*   nop
*   nop

* **********************************
* * lipemco effect 15 (santa dragon horn)
* * force on even if inventory full
* * (don't do this)
* **********************************
* 
*   org $381F0
*   nop
*   nop
* 
* **********************************
* * lipemco effect 16 (santa golden apple)
* * force on even if inventory full
* * (don't do this)
* **********************************
* 
*   org $38258
*   nop
*   nop

* **********************************
* * enemies always drop unused oxygen gummy item
* **********************************
* 
*   org $410A
*   move.b #$23,$FFFF84D8

* **********************************
* * enemies always drop unused sorcery memo item
* **********************************
*   
*   org $410A
*   move.b #$27,$FFFF84D8

*   * 100% a-capsule success
*   org $8B3C
*   nop
*   nop
*   
*   * cait siths always use rocket
*   org $2446E
*   jmp $248f0
*   
*   * scorpion-man always uses ?
*   org $23574
*   jmp $23884

    * some stuff to force green puyos
    * to always stack to 3 and then use
    * their special attack
*   org $29DC0
*   jmp puyoSpecialStuff
  
  * use hardcoded lipemco effect number
*   org $36902
*   move.w #12,d0
*   nop
*   nop
*   nop
  

*********************************************************************
* New routines for safe SRAM access
*********************************************************************

* the original game has SRAM always enabled.
* all the available documentation on Mega Drive SRAM is a
* horrible conflicting mess, but basically, sources agree
* that:
* - writing 0x00 to 0xA130F1 will disable SRAM
* - writing 0x01 to 0xA130F1 will enable SRAM
* with various other helpful advice such as "having SRAM enabled may
* or may not disable access to ROM at 0x200000-0x3FFFFF depending on
* how the cart is wired" and "writing 0x03 to 0xA130F1 is supposed
* to enable read/write mode but probably doesn't".
* well, we've expanded the ROM into this possibly-disabled-depending-
* on-hardware space, so let's attempt to make everyone happy by
* having SRAM disabled when not in use.
* this also improves the experience on emulators such as Fusion,
* where SRAM is disabled by default every time a savestate is loaded.

* what this game actually does is write 0x03 to 0xA130F1, except
* for when it's reading or writing a save file (usually), when it
* (usually) writes 0x01 to 0xA130F1 for the duration of the read/write.
* it also blindly reads and writes specific bytes in SRAM
* to determine which save file was most recently used, and to
* determine whether the "present" menu on the title screen is unlocked,
* and it expects such reads and writes to succeed regardless of
* the 0xA130F1 register state.

* 0x201029 (access as byte) = most recently used save file index?
* 0x20102A (access as word) = nonzero if "present" unlocked

sramReg equ $A130F1
sramOff equ $00
sramOn  equ $01
  
  * some unused space at the end of a graphic bank (this code must be
  * in 0-1fffff so it will not be mapped out when sram is enabled)
  org $14FEB0
  
  ********************************************************************
  * fetch 0x201029
  ********************************************************************
  
  fetch201029:
    move.b #sramOn,sramReg
    move.b $201029,d0
    move.b #sramOff,sramReg
    rts
  
  ********************************************************************
  * fetch 0x20102A
  ********************************************************************
  
  fetch20102A:
    move.b #sramOn,sramReg
    move.w $20102A,d0
    move.b #sramOff,sramReg
    rts
  
  ********************************************************************
  * set 0x20102A to 1
  ********************************************************************
  
  enable20102A:
    move.b #sramOn,sramReg
    move.w #$01,$20102A
    move.b #sramOff,sramReg
    rts
  
  ********************************************************************
  * blind sram access patches
  ********************************************************************

  **********************************
  * choosing default save file
  * at save prompt
  **********************************
  
  org $370C
  jsr fetch201029

  **********************************
  * unlocking "present" at
  * title screen
  **********************************
  
  org $91F4C
  jsr fetch20102A

  **********************************
  * choosing default save file
  * on title screen
  **********************************
  
  org $920F0
  jsr fetch201029

  **********************************
  * setting "present" to unlocked
  * in perfect ending (1)
  **********************************
  
  org $93E02
  jsr enable20102A
  nop

  **********************************
  * setting "present" to unlocked
  * in perfect ending (2)
  * yes the game does this twice
  * for no reason
  **********************************
  
  org $93E86
  jsr enable20102A
  nop
  
  ********************************************************************
  * disable SRAM after read/write operations
  * (it's already set to the expected 0x01 before these operations)
  ********************************************************************
  
  org $4B9D0
  move.b #sramOff,sramReg
  
  org $4B9FC
  move.b #sramOff,sramReg
  
  org $4BA4C
  move.b #sramOff,sramReg
  
  org $4BA72
  move.b #sramOff,sramReg
  
  org $4BA80
  move.b #sramOff,sramReg
  
  org $4BAAC
  move.b #sramOff,sramReg
  
  org $4BAD4
  move.b #sramOff,sramReg
  
  org $4BAFC
  move.b #sramOff,sramReg
  
  org $4BB2A
  move.b #sramOff,sramReg
  
  org $4BB58
  move.b #sramOff,sramReg

*********************************************************************
* Old code changes
*********************************************************************
  
  ********************************************************************
  * Point old opcodes to new
  ********************************************************************

*  org opcodeHandlerTable+$30
*  dc.l opLinebreak

  org opcodeHandlerTable+$D0
  dc.l opJumpToAddr

  org opcodeHandlerTable+$F8
  dc.l opJumpToScript

  org opcodeHandlerTable+$FC
  dc.l opClearCenter
  
  **********************************
  * Character literal handler
  **********************************
  
  org $491D6
  jmp newCharLiteralHandler
  
  **********************************
  * Linebreak handler
  **********************************
  
  org $49316
  jmp newLinebreakHandler
  
  **********************************
  * Target left box handler
  **********************************
  
  org $49368
  jmp newTargetLeftBoxHandler
  
  **********************************
  * Target right box handler
  **********************************
  
  org $493AE
  jmp newTargetRightBoxHandler
  
  **********************************
  * Target map label handler
  **********************************
  
  org $49438
  jmp newTargetMapLabelHandler
  
  **********************************
  * Target center box
  **********************************
  
  org $4947E
  jmp newTargetCenterBoxHandler
  
  **********************************
  * Wait for key
  **********************************
  
  org $4956A
  jmp newWaitForKeyHandler
  
  **********************************
  * op20
  **********************************
  
  org $493EC
  jmp newOp20Handler
  
  **********************************
  * op24
  **********************************
  
  org $493F6
  jmp newOp24Handler
  
  **********************************
  * script kill
  **********************************
  
  org $49972
  jmp newScriptKillHandler
  
  ********************************************************************
  * Jumps to extra code
  ********************************************************************
  
  **********************************
  * Script object init
  **********************************
  
  org $48C74
  jmp newScriptObjInit
  
  **********************************
  * Alt script object init
  **********************************
  
  org $48CF4
  jmp newAltScriptObjInit
  
  **********************************
  * Dynamic buffer print
  **********************************
  
  org $490BC
  jmp newDynamicBufferPrint
  
  **********************************
  * capsule release prompt
  **********************************
  
  org $81DA
  jmp newCapsuleReleasePrompt
  
  **********************************
  * capsule released
  **********************************
  
  org $8214
  jmp newCapsuleReleased
  
  **********************************
  * monster encountered
  **********************************
  
  org $397E
  jmp newMonsterEncounter
  
  **********************************
  * amigo defeat
  **********************************
  
  org $469A
  jmp newAmigoDefeat
  
*   org $4BE2E
*   capsuleScriptWaitLoc:
*   * delay destroying the capsule monster until the script
*   * indicating its defeat has run, so that the script runner
*   * can check for the cait sith id and special-case it accordingly
*   org $4BF26
*   jsr $122C
*   jsr $122C
*   tst.b $FFFF8520
*   bne capsuleScriptWaitLoc
*   * destroy capsule monster
*   clr.b capsuleMonsterId
*   * the two jsr commands we moved were called as long even though
*   * the location could be reached with a word.
*   * we've made them words, so add nops to pad to correct size.
*   nop
*   nop
  
  org $4BF26
  jmp newAmigoDefeat_internal
  
  **********************************
  * item combining
  **********************************
  
  * first name
  org $3A41A
  jsr shortItemNameToBuffer
  
  * second name
  org $3A4DC
  jsr shortItemNameToBuffer
  
  * produced item
  org $3A53C
  jsr itemNameWithIndefiniteArticleToBuffer
  
  **********************************
  * item obtained message
  * (actually, most of the messages
  * are hardcoded anyway, so why
  * bother)
  **********************************
  
*  org $39D14
*  jsr itemNameWithIndefiniteArticleToBuffer
  
  **********************************
  * dropping item that couldn't
  * be picked up due to full
  * inventory
  **********************************
  
  org $39DA2
  jsr doNewItemDroppedFromFullInventoryScript
  
  **********************************
  * intro/ending script runner
  **********************************
  
*   org $48CFA
*   jmp newIntroEndingScript
  
  **********************************
  * map label change
  **********************************
  
*   org $35FE
*   jmp newMapLabelChange
  
  **********************************
  * map label print buffer fill
  **********************************
  
  org $45DA
  jmp newMapLabelPrintBufferFill
  
  **********************************
  * momomo deposit
  **********************************
  
  org $43C92
  jmp newMomomoDeposit
  
  **********************************
  * momomo withdraw
  **********************************
  
  org $43EB8
  jmp newMomomoWithdraw
  
  **********************************
  * karaoke
  **********************************
  
  org $8FC9E
  jmp newKaraokeLyricSend
  
  * do not clear out the very end of vram (FC00-FFFF) before the karaoke
  * sequence. this allows us to store additional patterns there.
  org $8EC76
  * value is number of bytes at VRAM C000 to clear out divided by 2
  move.w #$1FFF-$200,d1
  
*   org $8FECA
*   move.w #2,d7
*   
*   org $8FEE8
*   move.w #2,d7
  
  * allow second line to be displayed on final page of lyrics.
  * this is a new "line" added for the hack, which is blank
  * and used to cover up the previous line.
  org $8FE80
  nop
  nop
  
  org $8FEA8
  jmp karaokeHideFinalLine
  
  org $8EE02
  jmp karaokeFixScrollModeInit
  
  * keep the translated lyrics out of the overscan area
  
  * move the lyric background bars up a tile
  org $8ECAE
  move.w #$F600-$100,d0
  
  * move lyric background whitespace up a tile
  org $8ECC4
  move.w #$F64E-$100,d0
  
  * target one line higher in hscroll table
  
  org $8FEC4
  lea $00FF8D7E-$20,a2
  
  org $8FEE2
  lea $00FF8DDE-$20,a2
  
  **********************************
  * bugged a-capsule capture fix
  **********************************
  
  org $BFEA
  jmp aCapsuleHitDoubleCheck
  
  **********************************
  * satan despawn fix 1
  **********************************
  
  org $2303E
  jmp satanDespawnFix1
  
  **********************************
  * satan despawn fix 2
  **********************************
  
  org $2304E
  jmp satanDespawnFix2
  
  ********************************************************************
  * Graphics packs
  ********************************************************************
  
  **********************************
  * title
  **********************************
  
  org $91C9E
  jmp titleGrpPackLoad
  
  * after viewing madou ondo
  org $9240A
  jmp titleGrpPackLoad_reload
  
  ********************************************************************
  * Title sprite text
  ********************************************************************
  
  * redirect old routine
  org $92580
  jmp newSendBouncyMessage
  
  * this drops through into the original routine
  org $9257A
  lea newPressStartMessageStructure,a2
  * xpos
  org $92560
  move.w #80+8,$12(a0)
  
  * these originally called the bouncy routine multiple times,
  * but we only need them to do it once now
  org $925D0
  lea newOptionPromptStructure,a2
  jsr newSendBouncyMessage
  bra $925EA
  * xpos
  org $925B6
*  move.w #93+8,$12(a0)
  move.w #62+8,$12(a0)
  
  org $926B2
  lea newLoadPromptStructure,a2
  jsr newSendBouncyMessage
  bra $926D2
  * xpos
  org $92698
*  move.w #89+8,$12(a0)
  move.w #82+8,$12(a0)
  
  org $92746
  lea newPresentPromptStructure,a2
  jsr newSendBouncyMessage
  bra $92766
  * xpos
  org $9272C
*  move.w #81+8,$12(a0)
  move.w #65+8,$12(a0)
  
  ********************************************************************
  * Title static sprite text
  ********************************************************************
  
mainMenuCharW equ 5
loadMenuCharW equ 5
presentMenuCharW equ 7
  
  **********************************
  * length of strings in main menu
  * when highlighted
  **********************************
  
  org $91F8E
  move.w #mainMenuCharW,$28(a0)
  
  * when eaten
  org $92042
  move.w #mainMenuCharW*2,$26(a1)
  
  **********************************
  * length of strings in load menu
  * when highlighted
  **********************************
  
  org $92110
  move.w #loadMenuCharW,$28(a0)
  
  * when eaten
  org $921AE
  move.w #loadMenuCharW*2,$26(a1)
  
  **********************************
  * length of strings in present
  * menu when highlighted
  **********************************
  
  org $9223E
  move.w #presentMenuCharW,$28(a0)
  
  * when eaten
  org $92398
  move.w #presentMenuCharW*2,$26(a1)
  
  **********************************
  * new game
  **********************************
  
  org $925EA
  * length in 16-pixel-wide sprites
  move.w #mainMenuCharW,$2C(a0)
  
  org $925FE
  lea newNewGameTextStructure,a2
  
  * xpos
  org $92604
  move.w #$70+$10,$12(a0)
  
  **********************************
  * continue
  **********************************
  
  org $92614
  * length in 16-pixel-wide sprites
  move.w #mainMenuCharW,$2C(a0)
  
  org $9262C
  lea newContinueTextStructure,a2
  
  * xpos
  org $92632
  move.w #$70+$10,$12(a0)
  
  **********************************
  * present
  **********************************
  
  org $9264E
  * length in 16-pixel-wide sprites
  move.w #mainMenuCharW,$2C(a0)
  
  org $92668
  lea newPresentTextStructure,a2
  
  * xpos
  org $9266E
  move.w #$70+$10,$12(a0)
  
  * also shift carbuncle
  org $91F76
  move.w #$58+$10,$A(a1)
  
  **********************************
  * journal 1
  **********************************
  
  org $926D2
  * length in 16-pixel-wide sprites
  move.w #loadMenuCharW,$2C(a0)
  
  org $926E6
  lea newJournal1TextStructure,a2
  
  **********************************
  * journal 2
  **********************************
  
  org $926FC
  * length in 16-pixel-wide sprites
  move.w #loadMenuCharW,$2C(a0)
  
  org $92714
  lea newJournal2TextStructure,a2
  
  **********************************
  * sorcery song
  **********************************
  
  org $92766
  * length in 16-pixel-wide sprites
  move.w #presentMenuCharW,$2C(a0)
  
  org $9277A
  lea newSorcerySongTextStructure,a2
  
  **********************************
  * sound test
  **********************************
  
  org $92790
  lea newSoundTestTextStructure,a2
  
  **********************************
  * samples
  **********************************
  
  org $927BE
  lea newSamplesTextStructure,a2
  
  ********************************************************************
  * Graphics pack overwrites
  ********************************************************************
  
  **********************************
  * intro pokan
  **********************************
  
  org $8d33a
  include out/packs/pack250000-0.inc
  include out/packs/pack250000-1.inc
  
  **********************************
  * intro doki
  **********************************
  
  org $8d3e8
  include out/packs/pack250000-2.inc
  
  **********************************
  * intro final ("bechi")
  **********************************
  
  org $8D43E
  include out/packs/pack250000-3.inc
  
  **********************************
  * bayoen cast graphics
  **********************************

  org $77ED2
  include out/packs/pack250000-4.inc
  
  **********************************
  * panotty main
  **********************************

  org $7610E
  include out/packs/pack250000-5.inc
  
  **********************************
  * panotty wah attack
  **********************************

  org $76116
  include out/packs/pack250000-6.inc
  
  **********************************
  * compile slogan
  **********************************

  org $92BA0
  include out/packs/pack250000-7.inc
  
  **********************************
  * battle main
  **********************************

  org $780AC
  include out/packs/pack250000-8.inc

  org $780C0
  include out/packs/pack250000-8.inc

  org $780D4
  include out/packs/pack250000-8.inc

  org $780E8
  include out/packs/pack250000-8.inc

  org $780FC
  include out/packs/pack250000-8.inc
  
  **********************************
  * mr flea graphics
  **********************************

  org $7608E
  include out/packs/pack250000-9.inc
  
  **********************************
  * panotty amigo main
  **********************************

  org $788B8
  include out/packs/pack250000-10.inc
  
  **********************************
  * panotty amigo wah attack
  **********************************

  * initial
  org $788B0
  include out/packs/pack250000-11.inc

  * reload
  org $788C0
  include out/packs/pack250000-11.inc
  
  **********************************
  * mr flea amigo graphics
  **********************************

  org $78838
  include out/packs/pack250000-12.inc
  
  **********************************
  * timer graphics
  **********************************

  org $7857C
  include out/packs/pack250000-13.inc

  org $78276
  include out/packs/pack250000-13.inc

  org $786FA
  include out/packs/pack250000-13.inc

  org $7852C
  include out/packs/pack250000-13.inc
  
  **********************************
  * cockadoodle
  **********************************

  org $2710C
  include out/packs/pack250000-14.inc
  
  **********************************
  * demon escape
  **********************************

  org $75FEE
  include out/packs/pack250000-15.inc
  
  **********************************
  * escape doors
  **********************************

  org $78534
  include out/packs/pack250000-16.inc
  
  **********************************
  * karaoke
  **********************************
  
  org $8A12C
  include out/packs/pack260000-0.inc
  
  **********************************
  * exam score bg
  **********************************
  
  org $961A6
  include out/packs/pack240000-4.inc
  
  org $961B2
  include out/packs/pack240000-5.inc
  
  org $961AC
  include out/packs/pack240000-6.inc
  
  **********************************
  * bad ending
  **********************************
  
  org $961C6
  include out/packs/pack270000-0.inc
  
  **********************************
  * skeleton t
  **********************************
  
  org $7601E
  include out/packs/pack260000-1.inc
  
  org $76024
  include out/packs/pack260000-2.inc
  
  ********************************************************************
  * bayoen cast animation
  ********************************************************************
  
  * initial character pointer (drawn immediately in init routine
  * instead of going through the usual lookup)
  org $F76E
  lea bayoenNameMap0,a2
  
  * use new ID->pointer table instead of old
  org $F7E2
  move.l #newBayoenIdTable,$40(a1)
  
  **********************************
  * new structure definitions
  * 0 = ba1
  * 1 = yo
  * 2 = ee1
  * 3 = ee2
  * 4 = en
  * 5 = [blank]
  * 6 = ba2 (for diacute)
  * FF = terminator
  **********************************
  org $F994
  * standard animation = bayoen
  dc.b $01,$02,$03,$04,$05,$05,$05,$FF
  * diacute*1 = bababayoen
  dc.b $06,$00,$01,$02,$03,$04,$05,$05,$05,$FF
  * diacute*2 = bababababayoen
  dc.b $06,$00,$06,$00,$01,$02,$03,$04,$05,$05,$05,$FF
  * diacute*3 = bababababababayoen
  dc.b $06,$00,$06,$00,$06,$00,$01,$02,$03,$04,$05,$05,$05,$FF
  * diacute*4 = bababababababababayoen
  dc.b $06,$00,$06,$00,$06,$00,$06,$00,$01,$02,$03,$04,$05,$05,$05,$FF
  
  ********************************************************************
  * cockadoodle animation
  ********************************************************************
  
  * initial character pointer (drawn immediately in init routine
  * instead of going through the usual lookup)
  org $26F40
  lea cockadoodleMap0,a2
  
  * use new ID->pointer table instead of old
  org $26FC4
  move.l #newCockadoodleIdTable,$40(a1)
  
  * structure
  org $2711A
*  dc.b $01,$00,$02,$00,$03,$04,$04,$04,$FF
  dc.b $01,$02,$03,$04,$05,$06,$06,$06,$FF
  
  ********************************************************************
  * mr flea "here" tag structure
  ********************************************************************
  
mrFleaHereTag_numChars equ 4
mrFleaDefendingTag_baseTile equ $45
  
  **********************************
  * use 4 characters instead of 5.
  * the last entry in the arrays below will be ignored.
  **********************************
  
  org $322FE
  move.w #mrFleaHereTag_numChars,$26(a0)
  
  **********************************
  * create new sprite definitions for new graphics.
  * these are in standard sprite attribute table format;
  * the first value is the number of subsprites (i.e. 1).
  **********************************
  
  org $7473E
  
  * "h"
  dc.w $0001,$0078,$0508,$62B4,$0078
  * "e"
  dc.w $0001,$0078,$0508,$62B8,$0078
  * "r"
  dc.w $0001,$0078,$0508,$62BC,$0078
  * "e"
  dc.w $0001,$0078,$0508,$62C0,$0078
  
  **********************************
  * array of each character's signed offset along arc
  **********************************
  
  org $32600
*  dc.b $F6,$D6,$E6,$F6,$06,$16
  * this gives the same arc width as original, but the spacing
  * looks too loose to me
*  dc.b $F6,$D6,$EB,$00,$16,$00
*  dc.b $F6,$E0,$F0,$00,$10,$00
  dc.b $F6,$DC,$EE,$FE,$10,$00
  
  **********************************
  * array of substate IDs for each child object.
  * original:
  *   0A = "ko"
  *   0B = "ni"
  *   0C = "i"
  *   0D = "ru"
  * new:
  *   0A = "h"
  *   0B = "e"
  *   0C = "r"
  *   0D = "e"
  * the second E is redundant in the hack, but it's more general
  * and there's no reason not to.
  **********************************
  
  org $32606
*  dc.b $04,$0A,$0A,$0B,$0C,$0D
  dc.b $04,$0A,$0B,$0C,$0D,$00
  
  **********************************
  * ? don't know, hopefully doesn't matter
  **********************************
  
  org $3260C
*  dc.b $10,$20,$20,$20,$20,$20
  dc.b $10,$20,$20,$20,$20,$00
  
  ********************************************************************
  * repeat of above for amigo mr flea
  ********************************************************************
  
  **********************************
  * use 4 characters instead of 5.
  * the last entry in the arrays below will be ignored.
  **********************************
  
  org $4EC0E
  move.w #mrFleaHereTag_numChars,$26(a0)
  
  **********************************
  * array of each character's signed offset along arc
  **********************************
  
  org $4EEC6
  dc.b $F6,$10,$FE,$EE,$DC,$00
  
  **********************************
  * array of substate IDs for each child object
  **********************************
  
  org $4EECC
*  dc.b $04,$0A,$0A,$0B,$0C,$0D
  dc.b $04,$0A,$0B,$0C,$0D,$00
  
  **********************************
  * ? don't know, hopefully doesn't matter
  **********************************
  
  org $4EED2
  dc.b $10,$20,$20,$20,$20,$00
  
  ********************************************************************
  * mr flea "defending" tag structure
  ********************************************************************
  
  org $74766
  * number of subsprites
  dc.w $0006
  * subsprite definitions
*  dc.w $0078,$0508,$62C4,$0050
  dc.w $0078,$0508,$62B0+mrFleaDefendingTag_baseTile+0,$0050
  dc.w $0078,$0508,$62B0+mrFleaDefendingTag_baseTile+4,$0060
  dc.w $0078,$0508,$62B0+mrFleaDefendingTag_baseTile+8,$0070
  dc.w $0078,$0508,$62B0+mrFleaDefendingTag_baseTile+12,$0080
  dc.w $0078,$0508,$62B0+mrFleaDefendingTag_baseTile+16,$0090
  dc.w $0078,$0508,$62B0+mrFleaDefendingTag_baseTile+20,$00A0
  
  ********************************************************************
  * mr flea "batankyu" tag structure
  ********************************************************************
  
mrFleaBatankyu_baseX equ $FFE8
  
  * ?
*  org $330C4
*  dc.w $0000,$0010,$0020,$0030,$0040,$0050
  
  * x-offsets
  org $330B8
*  dc.w $FFD0,$FFE0,$FFF0,$0000,$0010,$0020
  dc.w (mrFleaBatankyu_baseX+0)&$FFFF
  dc.w (mrFleaBatankyu_baseX+10)&$FFFF
  dc.w (mrFleaBatankyu_baseX+21)&$FFFF
  dc.w (mrFleaBatankyu_baseX+31)&$FFFF
  dc.w (mrFleaBatankyu_baseX+43)&$FFFF
  dc.w (mrFleaBatankyu_baseX+55)&$FFFF
  * total width = 64, what a coincidence
  * original was 96
  
  ********************************************************************
  * layout of on-screen timers
  ********************************************************************
  
  **********************************
  * "secs. left" sprite definitions
  **********************************
  
  * escape
  org $673B2
  * original
*   dc.w $0002
*   dc.w $0000,$0D0C,$82B0,$0000
*   dc.w $0000,$050C,$82B8,$0050
  * full-width digits
*   dc.w $0002
*   dc.w $0000,$0D0C,$82B0,$0030
*   dc.w $0000,$050C,$82B8,$0050
  * half-width digits
  dc.w $0002
  dc.w $0000,$0D0C,$82B0,$0018
  dc.w $0000,$0D0C,$82B8,$0038
  
  * treasure hunt
  org $673C4
  * original
*   dc.w $0002
*   dc.w $0000,$0D0C,$82B0,$0000
*   dc.w $0000,$050C,$82B8,$0040
  * full-width digits
*   dc.w $0002
*   dc.w $0000,$0D0C,$82B0,$0020
*   dc.w $0000,$050C,$82B8,$0040
  * half-width digits
  dc.w $0002
  dc.w $0000,$0D0C,$82B0,$0010
  dc.w $0000,$0D0C,$82B8,$0030
  
  **********************************
  * escape digit x-offsets
  **********************************
  
  * full-width digits
  
*   * hundreds digit
*   org $47948
* *  addi.w #$20,d2
*   addi.w #$00,d2
*   
*   * tens digit
*   org $4797A
* *  addi.w #$30,d2
*   addi.w #$10,d2
*   
*   * ones digit
*   org $479AC
* *  addi.w #$40,d2
*   addi.w #$20,d2
  
  * half-width digits
  
  * hundreds digit
  org $47948
  addi.w #$00,d2
  
  * tens digit
  org $4797A
*  addi.w #$08,d2
  addq.w #$0008,d2
  nop
  
  * ones digit
  org $479AC
  addi.w #$10,d2
  
  **********************************
  * treasure hunt digit x-offsets
  **********************************
  
  * full-width digits
  
*   * tens digit
*   org $4829E
* *  addi.w #$20,d2
*   addi.w #$00,d2
*   
*   * ones digit
*   org $482D0
* *  addi.w #$30,d2
*   addi.w #$10,d2
  
  * half-width digits
  
  * tens digit
  org $4829E
  addi.w #$00,d2
  
  * ones digit
  org $482D0
*  addi.w #$0008,d2
  * smart assembler problem: even if we write addi,
  * the assembler will "helpfully" optimize it to addq.w
  * because the constant is in the quick range.
  * normally this would be fine, but here we have to
  * fit exactly on top of the original code.
  addq.w #$0008,d2
  nop
  
  **********************************
  * digit sprite definitions
  **********************************
  
  org $673D6
  * 0
  dc.w $0001
  dc.w $0000,$010C,$82C0+$00,$0000
  * 1
  dc.w $0001
  dc.w $0000,$010C,$82C0+$02,$0000
  * 2
  dc.w $0001
  dc.w $0000,$010C,$82C0+$04,$0000
  * 3
  dc.w $0001
  dc.w $0000,$010C,$82C0+$06,$0000
  * 4
  dc.w $0001
  dc.w $0000,$010C,$82C0+$08,$0000
  * 5
  dc.w $0001
  dc.w $0000,$010C,$82C0+$0A,$0000
  * 6
  dc.w $0001
  dc.w $0000,$010C,$82C0+$0C,$0000
  * 7
  dc.w $0001
  dc.w $0000,$010C,$82C0+$0E,$0000
  * 8
  dc.w $0001
  dc.w $0000,$010C,$82C0+$10,$0000
  * 9
  dc.w $0001
  dc.w $0000,$010C,$82C0+$12,$0000
  
  ********************************************************************
  * exam score
  ********************************************************************
  
  **********************************
  * positioning
  **********************************
  
examScoreBaseX equ $7D
examScoreBaseY equ $64
  
  * hundreds digit
  
  org $95D2A
*  move.w #examScoreBaseX+$0,d2
  moveq #examScoreBaseX+$0,d2
  nop
  moveq #examScoreBaseY,d3
  
  * tens digit
  
  org $95CFA
  move.w #examScoreBaseX+$8,d2
  moveq #examScoreBaseY,d3
  
  * score = 100
  org $95D3E
  move.w #examScoreBaseX+$8,d2
  moveq #examScoreBaseY,d3
  
  * ones digit
  
  org $95D14
  move.w #examScoreBaseX+$10,d2
  moveq #examScoreBaseY,d3
  
  * score = 100
  org $95D52
  move.w #examScoreBaseX+$10,d2
  moveq #examScoreBaseY,d3
  
  **********************************
  * no "ten" at end of score
  **********************************
  
  org $95D5E
  rts
  
  **********************************
  * digit sprite definitions
  **********************************
  
  org $976A8
  * 0
  dc.w $0001
  dc.w $0080,$0100,$A24A+$00,$0080
  * 1
  dc.w $0001
  dc.w $0080,$0100,$A24A+$02,$0080
  * 2
  dc.w $0001
  dc.w $0080,$0100,$A24A+$04,$0080
  * 3
  dc.w $0001
  dc.w $0080,$0100,$A24A+$06,$0080
  * 4
  dc.w $0001
  dc.w $0080,$0100,$A24A+$08,$0080
  * 5
  dc.w $0001
  dc.w $0080,$0100,$A24A+$0A,$0080
  * 6
  dc.w $0001
  dc.w $0080,$0100,$A24A+$0C,$0080
  * 7
  dc.w $0001
  dc.w $0080,$0100,$A24A+$0E,$0080
  * 8
  dc.w $0001
  dc.w $0080,$0100,$A24A+$10,$0080
  * 9
  dc.w $0001
  dc.w $0080,$0100,$A24A+$12,$0080
  
  ********************************************************************
  * bad ending "gan" sprite definition
  ********************************************************************
  
badEndGan_numSprites equ 5
badEndGan_baseTile equ $4495
badEndGan_baseX equ $00D0
badEndGan_baseY equ $00C0
  
  org $977E6
  dc.w badEndGan_numSprites
  dc.w badEndGan_baseY,$0F00,badEndGan_baseTile+$00,badEndGan_baseX+$00
  dc.w badEndGan_baseY,$0F00,badEndGan_baseTile+$10,badEndGan_baseX+$20
  dc.w badEndGan_baseY,$0F00,badEndGan_baseTile+$20,badEndGan_baseX+$40
  dc.w badEndGan_baseY,$0F00,badEndGan_baseTile+$30,badEndGan_baseX+$60
  dc.w badEndGan_baseY,$0F00,badEndGan_baseTile+$40,badEndGan_baseX+$80
  
  ********************************************************************
  * longer lines in ending
  ********************************************************************
  
  * "but what could have triggered"
  org $9356E
*  jmp extendEnding_B1B18
  jsr extendEnding_doubleOneHalf
  
  * "that was certainly the most unique"
  org $93C34
  jsr extendEnding_double
  
  * "and so, arle managed to get out" failure
  org $9455A
*  jsr extendEnding_generic
  jsr extendEnding_oneHalf
  
  * "passed with a perfect score"
  org $93F66
  jsr extendEnding_double
  
  * "and so" good ending
  org $94320
  jsr extendEnding_oneHalf
  
  ********************************************************************
  * credits
  ********************************************************************
  
  **********************************
  * load new graphics
  **********************************
  
  org $97C1E
  lea newCredits0GrpPack,a2
  
  org $97CEC
  lea newCredits1GrpPack,a2
  
  org $97D84
  lea newCredits2GrpPack,a2
  
*  org $97E1A
*  lea newCredits3aGrpPack,a2
  
  org $97F74
  lea newCredits3GrpPack,a2
  
  org $980FC
  lea newCredits4GrpPack,a2
  
  org $98222
  lea newCredits5GrpPack,a2
  
  org $98382
  lea newCredits6GrpPack,a2
  
  org $9841A
  lea newCredits7GrpPack,a2
  
  org $985D0
  lea newCredits8GrpPack,a2
  
  org $98678
  lea newCredits9GrpPack,a2
  
  * the game lazily copies over the entire tilemap when
  * removing the priority effects from certain credits effects.
  * shift these down so they no longer affect the upper area
  * with the header text. (the overflow will spill harmlessly into
  * plane b)
  org $9E018
  dc.w $8000,$140E,$C000+$480
  
  **********************************
  * spawn credits runners
  **********************************
  
  org $97C90
  jsr spawnCreditsRunner0
  
  org $97D2E
  jsr spawnCreditsRunner1
  
  org $97DDC
  jsr spawnCreditsRunner2a
  
  org $97E5A
  jsr spawnCreditsRunner2b
  
  org $97FB6
  jsr spawnCreditsRunner3a
  
  org $9802A
  jsr spawnCreditsRunner3b
  
  org $980A2
  jsr spawnCreditsRunner3c
  
  org $98152
  jsr spawnCreditsRunner4a
  
  org $981CC
  jsr spawnCreditsRunner4b
  
  org $98262
  jsr spawnCreditsRunner5a
  
  org $982EE
  jsr spawnCreditsRunner5b
  
  org $983C4
  jsr spawnCreditsRunner6
  
  org $98468
  jsr spawnCreditsRunner7a
  
  org $984B4
  jsr spawnCreditsRunner7b
  
  org $98570
  jsr spawnCreditsRunner7c
  
*  org $9861E
*  jsr spawnCreditsRunner7d
  
  org $9861E
  jsr spawnCreditsRunner8
  
*  org $986FE
  org $986C8
  jsr spawnCreditsRunner9a
  
*  org $98766
*  jsr spawnCreditsRunner9b
  
*   org $988AA
  org $98854
  jmp spawnCreditsRunner9b
  
*   org $98866
*   jsr spawnCreditsRunner9c
  
*   org $988fa
*   org $989b6
  org $9897C
  jsr spawnCreditsRunner9c
  
  org $98AAC
  jmp doExtendedCredits
  
  ********************************************************************
  * intro voice clip subtitle script
  ********************************************************************
  
  org $8A2FE
  jmp startIntroWakeUpScript
  
*   org $8A3A0
*   org $8A3B4
  org $8A47E
  jmp clearIntroWakeUpScript
  
  *********************************************************************
  * fix bugged problem 4 clear message
  *********************************************************************

  * in the original game, the code that checks if the conditions
  * for completing problem 4 ("turn right") have been fulfilled
  * is bugged.
  * it's called as a subroutine, but was intended to be executed
  * from its associated object's "main thread" -- it uses the
  * yield/resume routines, which do not function correctly when
  * called from a subroutine.
  * as a result, when problem 4 is completed, the game does not
  * block execution while the message is displayed and instead
  * goes back to the regular dungeon logic right away.
  * by luck, this does not usually cause any major issues;
  * most players will immediately press C to clear the message,
  * which will cause the map to open (since the dungeon logic is
  * being executed) but otherwise close the box as normal.
  * but if the C button is pressed fast enough, the map screen's
  * printing will conflict with the "problem solved" message's,
  * resulting in garbage text.
  * much nastier things can happen if the player opens the inventory
  * or starts casting a spell at the right timing.
  * 
  * the solution is simple: jump to the problem 4 check instead of
  * calling it as a subroutine. the instruction immediately
  * following the call is a branch to the same place that the problem 4
  * check code jumps to when complete, so everything will still
  * function as normal.
  * apparently, this was meant to be a jump all along, but the
  * programmer messed up and no one ever caught the issue.
  
  org $3312
  jmp $3366(pc)
  
  *********************************************************************
  * fix possible text glitch when leaving combine items screen
  *********************************************************************
  
  * the game does not wait for currently running scripts to
  * finish executing when leaving the combine items screen.
  * (or pressing B after choosing the first item, but there is
  * enough of a delay after that that the bug can't manifest.)
  * it will clear the left window, but if a script is still
  * printing text, it will overwrite the cleared area, resulting
  * in a partial string appearing in the left box.
  * we need to wait on current scripts before doing the box clear.

  org $3A28E
  jmp combineItems_clearWindowsFix






  
  
  
  
  
  
*********************************************************************
* New code
*********************************************************************

  org newCodePos

  *********************************************************************
  * Table of pointers to VWF struct for each box type.
  *********************************************************************
  
  boxVwfBufferTable:
    dc.l vwfBuffer0Pos,vwfBuffer1Pos,vwfBuffer2Pos,vwfBuffer3Pos
  
  *********************************************************************
  * Returns in A2 a pointer to a script object's VWF struct.
  *
  * a0 = pointer to script object slot
  *********************************************************************
  
  getObjVwfStruct:
    move.l d1,-(a7)
    
      * get box type
      moveq.l #0,d1
      move.b scriptObj_modeLow(a0),d1
      
      * get pointer to corresponding buffer
      move.l #boxVwfBufferTable,a1
      lsl.w #2,d1
      move.l (a1,d1),a2
    
    move.l (a7)+,d1
    rts
  
  *********************************************************************
  * New script op D0 (replacing old, unused kill command):
  * Read a word ID, then jump to the corresponding new script from
  * the new script table.
  *
  * a0 = pointer to script object slot
  * a1 = pointer to source script data
  *********************************************************************
  
  opJumpToAddr:
    * read param long: new target address
    move.l (a1),a1
    
    * save new script srcaddr
    move.l a1,scriptObj_srcAddr(a0)
    
    * continue script processing
    jmp scriptHandlerLoop
  
  *********************************************************************
  * New script op F8 (replacing old, unused nop command):
  * Read a word ID, then jump to the corresponding new script from
  * the new script table.
  *
  * a0 = pointer to script object slot
  * a1 = pointer to source script data
  *********************************************************************
  
  opJumpToScript:
*     * read param word: target script ID
*     moveq #0,d0
*     move.w (a1)+,d0
*     
*     * look up corresponding pointer
*     lsl.w #2,d0
*     move.l #newScriptDataPos,a1
*     * a1 = pointer to new script srcaddr
*     move.l (a1,d0.w),a1
    
    bsr getReplacementScriptPointer
    
    * save new script srcaddr
    move.l a1,scriptObj_srcAddr(a0)
    
    * continue script processing
    jmp scriptHandlerLoop
  
  * a1 = pointer to source script data
  getReplacementScriptPointer:
    
    * read param word: target script ID
    moveq #0,d0
    move.w (a1)+,d0
    
    * look up corresponding pointer
    lsl.w #2,d0
    move.l #newScriptDataPos,a1
    * a1 = pointer to new script srcaddr
    move.l (a1,d0.w),a1
    
    rts
  
  *********************************************************************
  * New script op F8 (replacing old, unused script end command):
  * Clear the center box.
  *
  * a0 = pointer to script object slot
  * a1 = pointer to source script data
  *********************************************************************
  
  opClearCenter:
    * nametable base
    move.w $28(a0),d0
    * width - 1
    move.w #$1F,d1
    * height - 1
    move.w #$5,d2
    * tile to fill with
    move.w #$8001,d5
    
    jmp clearNametableArea

  *********************************************************************
  * New script object init.
  *
  * a1 = pointer to object slot
  *********************************************************************
    
  newScriptObjInit:
    * make up work
    move.b (a2)+,$51(a1)
    bset d0,$FFFF86FE
    
    * reset vwf struct
    
    movem.l a0/a2,-(a7)
      move.l a1,a0
      jsr resetThisObjVwfStruct
    movem.l (a7)+,a0/a2
    
    rts

  *********************************************************************
  * New alt script object init.
  *
  * a1 = pointer to object slot
  *********************************************************************
    
  newAltScriptObjInit:
    * make up work
    bset d0,$FFFF86FE
    
    * reset vwf struct
    
    movem.l a0/a2,-(a7)
      move.l a1,a0
      jsr resetThisObjVwfStruct
    movem.l (a7)+,a0/a2
    
    rts

  *********************************************************************
  * New dynamic buffer print handler.
  *
  * a0 = pointer to script object slot
  * a1 = pointer to source script data
  * d7 = number of characters to handle
  *********************************************************************
    
  newDynamicBufferPrint:
    * make up work
    move.l a1,$40(a0)
    lea $FFFF86AA,a3
    
*     * check for opF8 = jump, which may occur
*     * for item names
*     move.w (a3),d0
*     cmp.w #opF8Id,d0
*     bne newDynamicBufferPrint_notOpF8
* *      jsr getReplacementScriptPointer
*       * read param word: target script ID
*       adda #2,a3
*       moveq #0,d0
*       move.w (a3)+,d0
*       
*       * look up corresponding pointer
*       lsl.w #2,d0
*       move.l #newScriptDataPos,a3
*       * a3 = pointer to new script srcaddr
*       move.l (a3,d0.w),a3
*       
*       * if this happens, we are dealing with a script rather than a
*       * fixed-length string, so set length to "infinity"
*       moveq #-1,d7
*     newDynamicBufferPrint_notOpF8:
  
*    jmp $490C4
    
*     cmp.w #6,d7
*     bne newDynamicBufferPrint_not7
*       moveq #-1,d7
*     newDynamicBufferPrint_not7:
    
    newDynamicBufferPrint_loop:
      * do next character
      move.w (a3)+,d0
      
      * check for opF8 = jump, which may occur
      * for item names
      cmp.w #opF8Id,d0
      bne newDynamicBufferPrint_notOpF8
  *      jsr getReplacementScriptPointer
        * read param word: target script ID
        moveq #0,d0
        move.w (a3)+,d0
        
        * look up corresponding pointer
        lsl.w #2,d0
        move.l #newScriptDataPos,a3
        * a3 = pointer to new script srcaddr
        move.l (a3,d0.w),a3
        * fetch next character
        move.w (a3)+,d0
        
        * if this happens, we are dealing with a script rather than a
        * fixed-length string, so set length to "infinity"
        moveq #-1,d7
      newDynamicBufferPrint_notOpF8:
      cmp.w #opD0Id,d0
      bne newDynamicBufferPrint_notOpD0
        * read param long: new target address
        move.l (a3),a3
        * fetch next character
        move.w (a3)+,d0
        
        * if this happens, we are dealing with a script rather than a
        * fixed-length string, so set length to "infinity"
        moveq #-1,d7
      newDynamicBufferPrint_notOpD0:
      cmp.w #opBrId,d0
      bne newDynamicBufferPrint_notOpBr
        * do normal linebreak procedure
        jsr $49316
        bra newDynamicBufferPrint_loop
      newDynamicBufferPrint_notOpBr:
      
      * check for terminators
      * (only one we need to worry about is kill?)
      cmp.w #$FFFF,d0
      beq newDynamicBufferPrint_done
      
      jsr newCharLiteralHandler
      
      * see if frame wait needed?
      move.b $52(a0),d0
      beq newDynamicBufferPrint_nowait
        jsr $63470
      newDynamicBufferPrint_nowait:
      
      * reset delay counter?
      move.w $2A(a0),$26(a0)
      
      dbf d7,newDynamicBufferPrint_loop
      
    newDynamicBufferPrint_done:
    jmp $48D32

  *********************************************************************
  * New char literal handler.
  *
  * a0 = pointer to script object slot
  * a1 = (unreliable) pointer to source script data
  *      may be garbage for e.g. buffer print
  * d0 = word: char ID
  *********************************************************************
  
  newCharLiteralHandler:
*     * as a special case, we may encounter a jump command here
*     * if the game is printing from the dynamic-content buffer
*     * and encountered one of our replaced names.
*     * if so, handle it appropriately
*     cmp.w #opF8Id,d0
*     bne newCharLiteralHandler_notOpF8
*       jsr getReplacementScriptPointer
*       
*       * fetch next actual character, which had better not be a jump
*       move.w (a1)+,d0
*     newCharLiteralHandler_notOpF8:
    
    * ignore null characters
    cmp.w #nullchar,d0
    beq newCharLiteralHandler_done
  
    movem.l a1/a3/d7,-(a7)
      
      movem.l a0,-(a7)
      
  *       * get box type
  *       moveq.l #0,d1
  *       move.b scriptObj_modeLow(a0),d1
  *       
  *       * get pointer to corresponding buffer
  *       move.l #boxVwfBufferTable,a1
  *       lsl.w #2,d1
  *       move.l (a1,d1),a0
        
        * look up vwf struct
        jsr getObjVwfStruct
        move.l a2,a1
      
        * check kerning and subtract from advanceWidth/penPos
        * if present
        jsr applyKerning
      
    ***** SAFE OVERHANG CODE START ****
*         * transfer pending overhang to VDP
*         movem.l d0,-(a7)
*           jsr sendOverhangToVdp
*         movem.l (a7)+,d0
    ***** SAFE OVERHANG CODE END ****
        
        * compose to VWF buffer
        move.l a1,a0
        jsr writeToVwfPatternBuffer
        
        * save VWF struct pointer to a1
        move.l a0,a1
      
      * restore object slot pointer
      movem.l (a7)+,a0
      
      * transfer char to VDP
      jsr sendLastVwfWriteToVdp
      
    * restore script pointer (which probably doesn't actually matter)
    movem.l (a7)+,a1/a3/d7
    
    newCharLiteralHandler_done:
    rts

  *********************************************************************
  * Applies kerning between new character and previous.
  *
  * a0 = pointer to script object slot
  * a1 = pointer to VWF struct
  * d0 = word: new character ID
  *********************************************************************
  
  applyKerning:
    * do nothing if second character is out of kernable range
    tst.w d0
    beq applyKerning_done
    cmpi.w #numKernableChars,d0
    bhs applyKerning_done
    
    * do nothing if second character is a space
    * (this could probably be rolled into the previous check with
    * some cleverness)
    cmpi.w #spaceCharIndex,d0
    beq applyKerning_done
    
    * d1 = previous character index
    move.w vwfBufferStruct_lastChar(a1),d1
    
    * if the last character was a space, apply kerning as if
    * the previous character was the last non-space character
    cmpi.w #spaceCharIndex,d1
    bne applyKerning_lastCharWasNotSpace
      move.w vwfBufferStruct_lastNonSpaceChar(a1),d1
    applyKerning_lastCharWasNotSpace:
    
    * do nothing if first character is out of kernable range
    tst.w d1
    beq applyKerning_done
    cmpi.w #numKernableChars,d1
    bhs applyKerning_done
    
    * multiply first character index by 128 = numKernableChars
    ext.l d1
    lsl.l #7,d1
    
    * a2 = pointer to row of kerning matrix for first character
    move.l #kerningTable,a2
    add.l d1,a2
    
    * d1 = kerning offset
    move.b (a2,d0),d1
    
    * done if kerning offset == 0
    tst.b d1
    beq applyKerning_done
    
    * add kerning to advance width
    add.b d1,vwfBufferStruct_transAdvanceWidth(a1)
    
    * add kerning to penPos
    move.b vwfBufferStruct_penPos(a1),d2
    add.b d1,d2
    * wrap to valid buffer range
    andi.b #$1F,d2
    move.b d2,vwfBufferStruct_penPos(a1)
    * (re-)activate the pattern buffer containing the new penPos
    lsr.b #3,d2
    andi.w #$0003,d2
    move.b #$FF,vwfBufferStruct_activeArray(a1,d2)
    
    applyKerning_done:
    rts

  *********************************************************************
  * Sends the "overhang" (any advanceWidth beyond the transWidth of
  * the previous character transfer) to the VDP.
  *
  * a0 = pointer to script object slot
  * a1 = pointer to VWF struct
  *********************************************************************
  
  sendOverhangToVdp:
    
    ***** SAFE OVERHANG CODE START ****
    * d0 = putPos 
    move.w vwfBufferStruct_putPos(a1),d0
    
    * d1 = lineOverhang
*    move.b vwfBufferStruct_lineOverhang(a1),d1
    move.b vwfBufferStruct_transAdvanceWidth(a1),d1
    move.b vwfBufferStruct_transWidth(a1),d2
    sub.b d2,d1
    ext.w d1
    
    * update putPos
    * d2 = current putPos
    move.w d0,d2
    * add offset from overhang
    add.w d1,d2
    * save
    move.w d2,vwfBufferStruct_putPos(a1)
    
    * if lineOverhang is zero, we're done
    cmpi.w #0,d1
    beq sendOverhangToVdp_done
    bge sendOverhangToVdp_overhangPositive
    sendOverhangToVdp_overhangNegative:
      
      **********************************
      * negative overhang:
      * move back putpos
      **********************************
      
      * d3 = oldPutPos / 8
      move.w d0,d3
      lsr.w #3,d3
      
      * add lineOverhang
      add.w d1,d0
      
      * d4 = newPutPos / 8
      move.w d0,d4
      lsr.w #3,d4
      
      * if we passed a pattern boundary,
      * back up VDP position.
      * NOTE: maximum back-up of -8 pixels!
      * for more than that, this has to be turned into a loop
      cmp d3,d4
      beq sendOverhangToVdp_overhangNegative_noBackUp
*         * re-activate pattern buffer containing new pos
*         andi.w #$0003,d4
*         move.b #$FF,vwfBufferStruct_activeArray(a1,d4)
        
        * d3 = target pattern index in VDP
        move.w scriptObj_linePos(a0),d3
        subq.w #2,d3
        move.w d3,scriptObj_linePos(a0)
        
        * d3 = current nametable addr
        move.w scriptObj_currentNametableAddr(a0),d3
        subq.w #2,d3
        move.w d3,scriptObj_currentNametableAddr(a0)
      sendOverhangToVdp_overhangNegative_noBackUp:
      
      * save new putpos
      move.w d0,vwfBufferStruct_putPos(a1)
      
      * done
      bra sendOverhangToVdp_done
      
    sendOverhangToVdp_overhangPositive:
      
      **********************************
      * positive overhang:
      * transfer overhang to VDP
      **********************************
    
      * d5 = penPos (not startPos -- the next character hasn't
      * been processed yet, so penPos still identifies the start
      * position of the "next" character)
      move.b vwfBufferStruct_penPos(a1),d5
      ext.w d5
      
      * d2 = transfer width = overhang
      move.w d1,d2
    
      * d5 = startPos = (penStart - lineOverhang)
      sub.w d1,d5
      andi.w #$001F,d5
      
      jsr copyPatBufsToVdp
    ***** SAFE OVERHANG CODE END ****
      
    sendOverhangToVdp_done:
    rts

  *********************************************************************
  * Sends the most recently written VWF character from the VWF buffer
  * to the VDP.
  *
  * a0 = pointer to script object slot
  * a1 = pointer to VWF struct
  *********************************************************************
  
  sendLastVwfWriteToVdp:
  
    * TODO: if kerningOffset is nonzero, alter VDP putpos accordingly
    * ...
    
    * a2 = 
    
    * add lineOverhang from previous transfer, regardless of sign, to base
    * destination offset. if positive, transfer the corresponding pattern(s).
    * destination offset is now equivalent to penStart.
    * now transfer patterns covered by transWidth, updating dstpos to
    * the end of the transfer afterwards.
    * this means the final position will be off by size of the advanceWidth,
    * but this will be corrected via the lineOverhang if another character
    * follows.
    * special kerning can probably be achieved by adjusting lineOverhang.
    
    **********************************
    * account for line overhang
    **********************************
    
    ********** UNCOMMENT FOR UNSAFE BUT FASTER OVERHANG HANDLING *******
    ***** UNSAFE OVERHANG CODE START ****
    * d0 = putPos 
    move.w vwfBufferStruct_putPos(a1),d0
    
    * d1 = lineOverhang
    move.b vwfBufferStruct_lineOverhang(a1),d1
    ext.w d1
    
    * d2 = transWidth
    move.b vwfBufferStruct_transWidth(a1),d2
    ext.w d2
    
    * d5 = penStart
    move.b vwfBufferStruct_penStart(a1),d5
    ext.w d5
    
    * if lineOverhang is positive, transfer the patterns it covers
    cmp.w #0,d1
    beq sendLastVwfWriteToVdp_overhangCalcDone
    ble sendLastVwfWriteToVdp_noOverhangTransfer
      * add lineOverhang to transWidth if positive
      add.w d1,d2
      
      * move back penStart by overhang
      sub.w d1,d5
      andi.w #$001F,d5
      
      bra sendLastVwfWriteToVdp_overhangCalcDone
    sendLastVwfWriteToVdp_noOverhangTransfer:
      * if negative, add to putPos
      
      * d3 = oldPutPos / 8
      move.w d0,d3
      lsr.w #3,d3
      
      * add lineOverhang
      add.w d1,d0
      
      * d4 = newPutPos / 8
      move.w d0,d4
      lsr.w #3,d4
      
      * if we passed a pattern boundary,
      * back up VDP position.
      * NOTE: maximum back-up of -8 pixels!
      * for more than that, this has to be turned into a loop
      cmp d3,d4
      beq sendLastVwfWriteToVdp_noOverhangTransfer_noBackUp
      * no back-up if at pattern boundary
*       move.w vwfBufferStruct_putPos(a1),d4
*       andi.b #$7,d4
*       beq sendLastVwfWriteToVdp_noOverhangTransfer_noBackUp
        * d3 = target pattern index in VDP
        move.w scriptObj_linePos(a0),d3
        subq.w #2,d3
        move.w d3,scriptObj_linePos(a0)
        
        * d3 = current nametable addr
        move.w scriptObj_currentNametableAddr(a0),d3
        subq.w #2,d3
        move.w d3,scriptObj_currentNametableAddr(a0)
      sendLastVwfWriteToVdp_noOverhangTransfer_noBackUp:
      
    ***** UNSAFE OVERHANG CODE END ****
    
    
    ***** SAFE OVERHANG CODE START ****
*     * d0 = putPos 
*     move.w vwfBufferStruct_putPos(a1),d0
*     
*     * d2 = transWidth
*     move.b vwfBufferStruct_transWidth(a1),d2
*     ext.w d2
*     
*     * d5 = penStart
*     move.b vwfBufferStruct_penStart(a1),d5
*     ext.w d5
    ***** SAFE OVERHANG CODE END ****
    
    sendLastVwfWriteToVdp_overhangCalcDone:
    
    **********************************
    * write updated values
    **********************************
    
    * d1 = current putPos
    move.w d0,d1
    * add transfer width
    add.w d2,d1
    * save
    move.w d1,vwfBufferStruct_putPos(a1)
    
    **********************************
    * transfer patterns
    *
    * d0 = putPos
    * d2 = transWidth
    * d5 = startPos
    **********************************
    
    jsr copyPatBufsToVdp
    
    rts

  *********************************************************************
  * Copies material to VDP.
  *
  * a0 = pointer to script object slot
  * a1 = pointer to VWF struct
  * d0 = putPos
  * d2 = transWidth
  * d5 = startPos
  *********************************************************************
  
  copyPatBufsToVdp:
    
    * d3 = startBufIndex = startPos / 8
    move.b d5,d3
    lsr.b #3,d3
    
    * d1 = (startPos + transWidth)
    move.b d5,d1
    add.b d2,d1
    
    * d4 = endBufIndex = (startPos + transWidth) / 8
    move.b d1,d4
    lsr.b #3,d4
    
    * d1 = endPos
    andi.b #$1F,d1
    
    * ensure values are valid pattern buffer indices
    andi.b #$03,d3
    andi.b #$03,d4
    
    * a2 = base buffer pointer
    move.l a1,a2
    move.l #vwfBufferStruct_patbuf0,d6
    add.l d6,a2
    
    * save endPos
    move.l d1,-(a7)
    
      copyPatBufsToVdp_transferLoop:
        
        * done if final source pattern reached
        cmp.b d3,d4
        beq copyPatBufsToVdp_transferLoop_done
        
        * a3 = source buffer pointer
        moveq.l #0,d6
        move.b d3,d6
        lsl.l #6,d6
        move.l a2,a3
        add.l d6,a3
        
        * set d1 nonzero so fields are updated
        moveq.l #1,d1
        
        jsr copyPatBufToVdp
        
        * loop over next pattern
        addq.b #1,d3
        andi.b #$03,d3
        bra copyPatBufsToVdp_transferLoop
        
      copyPatBufsToVdp_transferLoop_done:
      
    * restore endPos
    move.l (a7)+,d1
    
    * final transfer needed if not at pattern boundary (endPos % 8 != 0),
    * but do not advance VDP putpos in this case
    andi.b #$07,d1
    beq copyPatBufsToVdp_noFinalTransfer
      * a3 = source buffer pointer
      moveq.l #0,d6
      move.b d3,d6
      lsl.l #6,d6
      move.l a2,a3
      add.l d6,a3
      
      * set d1 nonzero so fields are not updated
      moveq.l #0,d1
      
      jsr copyPatBufToVdp
    copyPatBufsToVdp_noFinalTransfer:
    
    rts

  *********************************************************************
  * Copies a pattern buffer to an object's current VDP position.
  *
  * a0 = pointer to script object slot
  * a1 = pointer to VWF struct
  * a3 = pointer to source data
  * d1 = if nonzero, increment putpos
  *********************************************************************
    
  copyPatBufToVdp:
    
    * d5 = target VDP pattern offset
    move.w scriptObj_linePos(a0),d5
    move.l d5,-(a7)
      * update
      tst.b d1
      beq copyPatBufToVdp_noPutposUpdate1
        move.w d5,d0
        addq.w #2,d0
        move.w d0,scriptObj_linePos(a0)
      copyPatBufToVdp_noPutposUpdate1:
      
      * d0 = base pattern data VDP dst
      move.w scriptObj_baseVdpPatternDst(a0),d0
      
      * d5 = vdp dstaddr
      add.w d0,d5
      andi.w #$07FF,d5
      lsl.w #5,d5
      
      * d6 = current nametable addr
      move.w scriptObj_currentNametableAddr(a0),d6
      * update
      tst.b d1
      beq copyPatBufToVdp_noPutposUpdate2
        move.w d6,d0
        addq.w #$0002,d0
        move.w d0,scriptObj_currentNametableAddr(a0)
      copyPatBufToVdp_noPutposUpdate2:
      
      **********************************
      * do pattern data transfer
      **********************************
      
*       * interrupts off
*   *    ori #$0700,sr
*   *      jsr setUpVramWrite
*   *    * interrupts on
*   *    andi #$F8FF,sr
*       
*       move.w #(vwfPatBufSize/4)-1,d0
*       copyPatBufToVdp_patTransferLoop:
*         * d2 = next long of pattern data
*         move.l (a3)+,d2
*         
*         * interrupts off
*         ori #$0700,sr
*           jsr setUpVramWrite
*           move.l d2,vdpDataPort
*         * interrupts on
*         andi #$F8FF,sr
*         
*         * to next dst
*         addq.l #4,d5
*         
*         dbf.w d0,copyPatBufToVdp_patTransferLoop
      
      * not calling setUpVramWrite multiple times seems to reduce
      * lag compared to having interrupts enabled more often.
      * though not always...?
      * opening map lags 4 frames instead of 8, but intro text
      * lags the same...
      * am i misunderstanding something here?
      
*       * interrupts off
*       ori #$0700,sr
*       jsr setUpVramWrite

    * inline setUpVramWrite
    asl.l #2,d5
    lsr.w #2,d5
    ori.w #$4000,d5
    swap d5
    andi.w #$3,d5
    
    * interrupts off
    ori #$0700,sr
  
      move.l d5,vdpControlPort
    
*       move.w #(vwfPatBufSize/4)-1,d0
*       copyPatBufToVdp_patTransferLoop:
*         * d2 = next long of pattern data
*         move.l (a3)+,vdpDataPort
*         
*         dbf.w d0,copyPatBufToVdp_patTransferLoop
    
      * unroll loop
      move.l (a3)+,vdpDataPort
      move.l (a3)+,vdpDataPort
      move.l (a3)+,vdpDataPort
      move.l (a3)+,vdpDataPort
      move.l (a3)+,vdpDataPort
      move.l (a3)+,vdpDataPort
      move.l (a3)+,vdpDataPort
      move.l (a3)+,vdpDataPort
      move.l (a3)+,vdpDataPort
      move.l (a3)+,vdpDataPort
      move.l (a3)+,vdpDataPort
      move.l (a3)+,vdpDataPort
      move.l (a3)+,vdpDataPort
      move.l (a3)+,vdpDataPort
      move.l (a3)+,vdpDataPort
      move.l (a3)+,vdpDataPort
    
    * interrupts on
    andi #$F8FF,sr
      
    **********************************
    * do nametable data transfer
    **********************************
    
*     * top half
*     
*     * retrieve old target VDP pattern index
*     move.l (a7)+,d0
*     add.w scriptObj_baseVdpPatternDst(a0),d0
*     
*     move.l d6,d5
*     * interrupts off
*     ori #$0700,sr
*       jsr setUpVramWrite
*       move.w d0,vdpDataPort
*     * interrupts on
*     andi #$F8FF,sr
*     
*     * bottom half
*     
*     addq.w #1,d0
*     * tells us how many bytes to add to advance to next row in nametable
*     add.w $FFFF8A64,d5
*     * interrupts off
*     ori #$0700,sr
*       jsr setUpVramWrite
*       move.w d0,vdpDataPort
*     * interrupts on
*     andi #$F8FF,sr
    
    * retrieve old target VDP pattern index
    move.l (a7)+,d0
    add.w scriptObj_baseVdpPatternDst(a0),d0
    
    move.l d6,d5
    
    * inline setUpVramWrite
    move.l d5,-(a7)
      asl.l #2,d5
      lsr.w #2,d5
      ori.w #$4000,d5
      swap d5
      andi.w #$3,d5
    
      * interrupts off
      ori #$0700,sr
        * top half
        move.l d5,vdpControlPort
        move.w d0,vdpDataPort
      * interrupts on
      andi #$F8FF,sr
    move.l (a7)+,d5
      
    * bottom half
    addq.w #1,d0
    
    * tells us how many bytes to add to advance to next row in nametable
    add.w $FFFF8A64,d5
    
    * inline setUpVramWrite
    asl.l #2,d5
    lsr.w #2,d5
    ori.w #$4000,d5
    swap d5
    andi.w #$3,d5
    
    * interrupts off
    ori #$0700,sr
      move.l d5,vdpControlPort
      move.w d0,vdpDataPort
    * interrupts on
    andi #$F8FF,sr
    
    rts

  *********************************************************************
  * New op20 handler.
  *
  * a0 = pointer to script object slot
  *********************************************************************
  
  newOp20Handler:
    jsr resetThisObjVwfStruct
    * make up work
    move.w #$1884,d0
    jsr $49334
    jmp $493C8

  *********************************************************************
  * New op24 handler.
  *
  * a0 = pointer to script object slot
  *********************************************************************
  
  newOp24Handler:
    jsr resetThisObjVwfStruct
    * make up work
    move.w #$18AC,d0
    jsr $4937A
    jmp $493FE

  *********************************************************************
  * New script kill handler.
  *
  * a0 = pointer to script object slot
  *********************************************************************
  
  newScriptKillHandler:
    jsr resetThisObjVwfStruct
    * make up work
    move.b $50(a0),d0
    bclr d0,$FFFF86FE
    jmp $4997A

  *********************************************************************
  * New linebreak handler.
  *
  * a0 = pointer to script object slot
  *********************************************************************
  
  newLinebreakHandler:
    jsr resetThisObjVwfStruct
    * make up work
    move.w $FF8A64,d0
    jmp $4931C

  *********************************************************************
  * New target left box handler.
  *
  * a0 = pointer to script object slot
  *********************************************************************
  
  newTargetLeftBoxHandler:
    * make up work
    bset #0,$FFFF86FE
    jmp resetThisObjVwfStruct_withClear

  *********************************************************************
  * New target right box handler.
  *
  * a0 = pointer to script object slot
  *********************************************************************
  
  newTargetRightBoxHandler:
    * make up work
    bset #1,$FFFF86FE
    jmp resetThisObjVwfStruct_withClear

  *********************************************************************
  * New target map label handler.
  *
  * a0 = pointer to script object slot
  *********************************************************************
  
  newTargetMapLabelHandler:
    * make up work
    bset #1,$FFFF86FE
    jmp resetThisObjVwfStruct_withClear

  *********************************************************************
  * New target center box handler.
  *
  * a0 = pointer to script object slot
  *********************************************************************
  
  newTargetCenterBoxHandler:
    * make up work
    bset #2,$FFFF86FE
    jmp resetThisObjVwfStruct_withClear

  *********************************************************************
  * New wait for key handler.
  *
  * a0 = pointer to script object slot
  *********************************************************************
    
  newWaitForKeyHandler:
    * make up work
    move.w d0,$4C(a0)
    move.w d0,$4E(a0)
    jsr resetThisObjVwfStruct_withClear
    jmp $49572

  *********************************************************************
  * Resets a (script) object's VWF struct.
  *
  * a0 = pointer to script object slot
  *********************************************************************
  
  resetThisObjVwfStruct:
    * a2 = pointer to obj vwf struct
    jsr getObjVwfStruct
    
    * if not at pattern boundary,
    * or a buffer is still active,
    * move to next VRAM index
    move.l d0,-(a7)
*      move.w vwfBufferStruct_putPos(a2),d0
*      andi.w #$0007,d0
*      beq resetThisObjVwfStruct_boundaryCheckDone
      
      * check four active markers as a long.
      * if all are zero, do not waste a pattern.
*      tst.l vwfBufferStruct_activeArray(a2)
*      beq resetThisObjVwfStruct_boundaryCheckDone
      
*      move.b vwfBufferStruct_putPos(a2),d0
*      andi.b #$07,d0
*      beq resetThisObjVwfStruct_boundaryCheckDone
      
      * actually, i guess the vdp pos is only advanced
      * when new material is added at the boundary, so we
      * can just advance unconditionally here...?
      * TODO: at least if current position is nonzero...?
      * we're skipping the first 2 patterns every time...
      
      move.w vwfBufferStruct_putPos(a2),d0
      andi.w #$07,d0
      beq resetThisObjVwfStruct_boundaryCheckDone
        move.w scriptObj_linePos(a0),d0
        addq.w #2,d0
        move.w d0,scriptObj_linePos(a0)
      resetThisObjVwfStruct_boundaryCheckDone:
    move.l (a7)+,d0
    
    jmp resetVwfStruct
  
  resetThisObjVwfStruct_withClear:
    * a2 = pointer to obj vwf struct
    jsr getObjVwfStruct
    
    * if not at pattern boundary,
    * or a buffer is still active,
    * move to next VRAM index
    move.l d0,-(a7)
      * actually, i guess the vdp pos is only advanced
      * when new material is added at the boundary, so we
      * can just advance unconditionally here...?
      * TODO: at least if current position is nonzero...?
      * we're skipping the first 2 patterns every time...
      
*        move.w scriptObj_linePos(a0),d0
*        addq.w #2,d0
        move.w #0,scriptObj_linePos(a0)
      resetThisObjVwfStruct_withClear_boundaryCheckDone:
    move.l (a7)+,d0
    
    jmp resetVwfStruct
  
*********************************************************************
* Generic VWF stuff
*********************************************************************

  *********************************************************************
  * Resets a VWF buffer.
  *
  * a2 = pointer to start of target VWF buffer
  *********************************************************************
  
  resetVwfStruct:
    movem.l a1/d0-d1,-(a7)
    
      * a1 = pointer to memory to clear
      move.l a2,a1
      move.l #vwfBufferStruct_activeArray,d0
      add.l d0,a1
      
      * d1 = counter
      move.w #(vwfBufferStruct_patbuf0-vwfBufferStruct_activeArray)/4,d1
      subq.w #1,d1
      
      * d0 = fill value
      moveq #0,d0
      
      * clear memory
      resetVwfStruct_fillLoop:
        move.l d0,(a1)+
        dbf.w d1,resetVwfStruct_fillLoop
    
    movem.l (a7)+,a1/d0-d1
    rts

  *********************************************************************
  * Writes a character to the pointed-to VWF buffer.
  * Trashes everything except A0.
  *
  * a0 = pointer to start of target VWF buffer
  * d0 = word: index number of target character
  *********************************************************************

  writeToVwfPatternBuffer:
*    movem.l   d0-d7/a0-a6,-(a7)
    
    * update lastChar field with target char index
    move.w d0,vwfBufferStruct_lastChar(a0)
    
    * update lastNonSpaceChar if appropriate
    cmp.w #spaceCharIndex,d0
    beq writeToVwfPatternBuffer_newCharIsSpace
      move.w d0,vwfBufferStruct_lastNonSpaceChar(a0)
    writeToVwfPatternBuffer_newCharIsSpace:
    
    * zero-extend index num of target char
    andi.l #$0000FFFF,d0
    * multiply by $2 to get offset to glyph data
    lsl.l #1,d0
    * a1 = pointer to glyph data table for target char
    move.l #fontCharTable,a1
    add.l d0,a1
  
    **********************************
    * Read glyph metrics
    **********************************
    
    * set lineOverhang (old advanceWidth - old transWidth)
    ***** UNSAFE OVERHANG CODE START ****
    move.b vwfBufferStruct_transAdvanceWidth(a0),d2
    move.b vwfBufferStruct_transWidth(a0),d3
    sub.b d3,d2
    move.b d2,vwfBufferStruct_lineOverhang(a0)
    ***** UNSAFE OVERHANG CODE END ****
    
    * d2 = glyph width
    move.b vwfGlyphData_glyphWidth(a1),d2
    * save to vwf buffer
    move.b d2,vwfBufferStruct_transWidth(a0)
    * d1 = advance width
    move.b vwfGlyphData_advanceWidth(a1),d1
    
    * save advanceWidth
    move.l d1,-(a7)
  
      **********************************
      * Get pointer to source data
      **********************************
    
      * multiply by $40 ($80, including the previous multiplication)
      * to get actual offset to target pattern data
*      lsl.l #6,d0
      * now accounting for extra padding to allow lazy long-size copies
      * account for row padding
      lsl.l #8,d0
      lsl.l #1,d0
      * a1 = pointer to source pattern data for target char
      move.l #fontPatternData,a1
      add.l d0,a1
  
      **********************************
      * Set up other transfer params
      **********************************
      
      * set up width parameter for pattern data transfer(s)
      move.b d2,d0
      
      * save advance width
      move.b d1,vwfBufferStruct_transAdvanceWidth(a0)
    
*       * set transStart.
*       * transStart is the old penStart plus the previous transWidth,
*       * yielding the position at which new content (including any "overhang"
*       * from an advanceWidth exceeding the glyphWidth of the previous transfer)
*       * may begin.
*       move.b vwfBufferStruct_penStart(a0),d2
*       move.b vwfBufferStruct_transWidth(a0),d1
*       add.b d2,d1
*       move.b d1,vwfBufferStruct_transStart(a0)
      
      * reset linePosStart
*      move.b vwfBufferStruct_linePos(a0),d1
*      move.b d1,vwfBufferStruct_linePosStart(a0)
      
      * TODO: check for kerning with previous character
      * for now, just ensure it remains at zero
*      move.b #$00,vwfBufferStruct_kerningOffset(a0)
      
      * reset penStart
      move.b vwfBufferStruct_penPos(a0),d1
      move.b d1,vwfBufferStruct_penStart(a0)
      
      * srcPos
      moveq.l #0,d2
  
      **********************************
      * Compose source patterns into
      * buffer.
      *
      * Source characters may be up to
      * 16px in width, so up to three
      * transfers may be needed (depending
      * on alignment with the destination
      * buffers). If after any one of them
      * the remaining width becomes zero,
      * we're done.
      **********************************
      
      jsr transferVwfToNextBoundary
      tst.b d0
      beq writeToVwfPatternBuffer_transferDone
      
      jsr transferVwfToNextBoundary
      tst.b d0
      beq writeToVwfPatternBuffer_transferDone
      
      jsr transferVwfToNextBoundary
      
    writeToVwfPatternBuffer_transferDone:
    
    **********************************
    * update penPos from advanceWidth
    * (resetting active flag to 0 for any buffer we exit,
    *  and ensuring any buffer we enter is initialized)
    **********************************
    
    * d0 = advanceWidth
    move.l (a7)+,d0
    
    * update linePos
*    move.b vwfBufferStruct_linePos(a0),d1
*    add.b d0,d1
*    move.b d1,vwfBufferStruct_linePos(a0)
    
    * d1 = penPos
    move.b vwfBufferStruct_penPos(a0),d1
    
    * d2 = index number of current buffer
    move.b d1,d2
    lsr.b #3,d2
    
    * d1 = (penPos + advanceWidth) % 32
    add.b d0,d1
    andi.b #$1F,d1
    * write updated penPos
    move.b d1,vwfBufferStruct_penPos(a0)
    
    * d3 = index number of final buffer
    move.b d1,d3
    lsr.b #3,d3
    
    move.l a0,a1
    move.l #vwfBufferStruct_activeArray,d0
    add.l d0,a1
    writeToVwfPatternBuffer_activeUpdate:
      * if buffer is not active, initialize it.
      * normally this will do nothing, but we have
      * to do this in order to allow for an advanceWidth
      * that exceeds the glyphWidth by more than 8 (since
      * otherwise, an entire pattern of data may get skipped
      * over and otherwise would never get initialized
      * before being transferred to VRAM).
      tst.b (a1,d2)
      bne writeToVwfPatternBuffer_activeUpdate_alreadyInited
        * do not initialize the current buffer if we are exactly on
        * its boundary (penPos % 8 == 0)
        cmp.b d2,d3
        bne writeToVwfPatternBuffer_activeUpdate_initPat_notLast
          move.b d1,d4
          andi.b #$07,d4
          beq writeToVwfPatternBuffer_done
        writeToVwfPatternBuffer_activeUpdate_initPat_notLast:
        
        * mark as initialized
        move.b #$FF,(a1,d2)
        
        * a2 = pointer to start of buffers
        move.l a0,a2
        move.l #vwfBufferStruct_patbuf0,d4
        add.l d4,a2
        * d4 = offset to target buffer
        moveq.l #0,d4
        move.b d2,d4
        lsl.l #6,d4
        * a2 = pointer to start of target buffer
        add.l d4,a2
        
        * initialize
        move.b d3,d5
          jsr initializeVwfPatternBuffer
        move.b d5,d3
        
      writeToVwfPatternBuffer_activeUpdate_alreadyInited:
      
      * check if we've progressed to the current buffer
      cmp.b d2,d3
      beq writeToVwfPatternBuffer_done
      
      * mark this buffer as inactive
      move.b #$00,(a1,d2)
      
      * move to next buffer
      addq.b #1,d2
      andi.b #$03,d2
      bra writeToVwfPatternBuffer_activeUpdate
    
    writeToVwfPatternBuffer_done:
    
    rts

  *********************************************************************
  * Initializes a VWF pattern buffer.
  * Trashes A3, D3.
  *
  * a2 = pointer to target buffer start
  *********************************************************************
    
  initializeVwfPatternBuffer:
    * save pointer to buffer start
    move.l a2,a3
    
      * buffer clear value
*      move.w #$1111,d3
      move.l #$11111111,d3
      
      * d4 = loop counter
*      move.b #(vwfPatBufSize/2)-1,d4
*      transferVwfToNextBoundary_patBufInitLoop:
*        
*        dbf d4,transferVwfToNextBoundary_patBufInitLoop

      * unrolled loop: write word 32 times to fill buffer
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+
*       move.w d3,(a2)+

      * unrolled loop: write long 16 times to fill buffer
      move.l d3,(a2)+
      move.l d3,(a2)+
      move.l d3,(a2)+
      move.l d3,(a2)+
      move.l d3,(a2)+
      move.l d3,(a2)+
      move.l d3,(a2)+
      move.l d3,(a2)+
      move.l d3,(a2)+
      move.l d3,(a2)+
      move.l d3,(a2)+
      move.l d3,(a2)+
      move.l d3,(a2)+
      move.l d3,(a2)+
      move.l d3,(a2)+
      move.l d3,(a2)+
    
    * restore buffer start pointer
    move.l a3,a2
    
    rts

  *********************************************************************
  * Transfers data to a specified VWF buffer up to the next pattern
  * boundary (or less, if fewer pixel columns remain than that).
  *
  * a0 = pointer to start of target VWF buffer
  * a1 = pointer to START OF source pattern data
  * d0 = byte: remaining width of data to be transferred in pixels
  * d1 = byte: current penPos
  * d2 = byte: current offset in srcData
  * 
  * A1, D0, D1, and D2 will be returned as their updated values after
  * the transfer.
  *********************************************************************
  
  transferVwfToNextBoundary:
    * save srcPos
    move.b d2,d6
  
    * d2 = index num of target pattern buffer (penPos/8)
    move.b d1,d2
    lsr.b #3,d2
    
    * a2 = offset to pattern buffers
    move.l a0,a2
    move.l #vwfBufferStruct_patbuf0,d3
    add.l d3,a2
    * d3 = offset to start of target pattern buffer
    moveq.l #0,d3
    move.b d2,d3
    lsl.l #6,d3
    * a2 = pointer to start of target pattern buffer
    add.l d3,a2
    
    * a3 = pointer to buffer active array
*    move.l a0,a3
*    move.l #vwfBufferStruct_activeArray,d3
*    add.l d3,a3
  
    **********************************
    * initialize target pattern buffer
    * if inactive
    **********************************
    
*    tst.b (a3,d2)
    tst.b vwfBufferStruct_activeArray(a0,d2)
    bne transferVwfToNextBoundary_alreadyActive
      * mark buffer as active
      move.b #$FF,vwfBufferStruct_activeArray(a0,d2)
      
      jsr initializeVwfPatternBuffer
    transferVwfToNextBoundary_alreadyActive:
  
    **********************************
    * determine transfer width and dst
    **********************************
    
    * d4 = penPos % 8
    move.b d1,d4
    andi.b #$07,d4
    
    * d3 = default width = (8 - (penPos % 8))
*    moveq.l #0,d3
    move.b #8,d3
    sub.b d4,d3
    
    * if actual pixels remaining < distance to pattern end,
    * use actual pixels remaining as width
    * (d0 = actual remaining, d3 = remaining in pattern)
    cmp.b d3,d0
    bge transferVwfToNextBoundary_notAtSrcEnd
      move.b d0,d3
    transferVwfToNextBoundary_notAtSrcEnd:
    
    * do nothing if transfer width is zero (shouldn't happen)
    tst.b d3
    beq transferVwfToNextBoundary_done
    
    * remaining width -= transfer width
    sub.b d3,d0
    
    * restore srcPos
    move.b d6,d2
    
    **********************************
    * now:
    *   d0 = remaining data width
    *        - width of this transfer
    *   d1 = penPos
    *   d2 = position in src data in
    *        pixels
    *   d3 = transfer width
    *   a0 = vwf buffer pointer
    *   a1 = pointer to START OF src
    *        pattern data
    *   a2 = pointer to START OF dst
    *        patbuf
    * 
    * do the transfer proper.
    **********************************
    
    movem.l a1-a2/d1,-(a7)
      * penPos %= 8
      andi.b #$07,d1
    
      * if srcPos/2 is odd, move to even-aligned version of src
      btst #1,d2
      beq transferVwfToNextBoundary_initalSrcNotAtOddAddr
        move.l #$000001FF,d4
        add.l d4,a1
      transferVwfToNextBoundary_initalSrcNotAtOddAddr:
    
      * if srcPos is odd, move to nybble-aligned version of src
      btst #0,d2
      beq transferVwfToNextBoundary_initalSrcNotOdd
        move.l #$00000100,d4
        add.l d4,a1
      transferVwfToNextBoundary_initalSrcNotOdd:
      
      * top half
      jsr transferVwfBufferPattern
    
      * bottom half
      move.l #patternSize,d4
      add.l  d4,a2
*      lsl.l #1,d4
      * account for row padding
      lsl.l #2,d4
      add.l  d4,a1
      jsr transferVwfBufferPattern
    movem.l (a7)+,a1-a2/d1
    
    **********************************
    * return updated values
    **********************************
    
    transferVwfToNextBoundary_done:
    
    * penPos += transfer width
    add.b d3,d1
    * penPos %= 32
    andi.b #$1F,d1
    
    * srcPos += transfer width
    add.b d3,d2
    
    rts
    
  *********************************************************************
  * Transfers one pattern (or less) of VWF data from source font
  * to pattern buffer.
  *
  *   d0 = PRESERVE
  *   d1 = dstPos (penPos % 8)
  *   d2 = srcPos
  *   d3 = transfer width (PRESERVE)
  *   a0 = vwf buffer pointer (PRESERVE)
  *   a1 = pointer to START OF src pattern data
  *   a2 = pointer to START OF dst
  *        patbuf
  *********************************************************************
    
  transferVwfBufferPattern:
    
    movem.l a1-a2/d0-d2,-(a7)
    
    * compute initial src/dst pointers
    moveq.l #0,d0
    * src
    move.b d2,d0
    lsr.b #1,d0
    add.l d0,a1
    
*     * if srcPos/2 is odd, move to even-aligned version of src
*     btst #1,d2
*     beq transferVwfBufferPattern_initalSrcNotAtOddAddr
*       move.l #$000000FF,d0
*       add.l d0,a1
*     transferVwfBufferPattern_initalSrcNotAtOddAddr:
    
    * d7 = pattern line counter
    moveq #patternH-1,d7
    transferVwfBufferPattern_patternRowCopyLoop:
      * read a long's worth of data from src
      move.l (a1),d4
      
*       * if srcPos is odd, we have to shift the result left a nybble
*       btst #0,d2
*       beq transferVwfBufferPattern_srcAlignmentDone
*       transferVwfBufferPattern_doNybbleAlignShift:
*         lsl.l #4,d4
*         
*         * if width is 8, we have to read an extra src byte to get
*         * the last nybble
*         cmp.b #8,d3
*         * if width is 8, we can also skip the other shift
*         bne transferVwfBufferPattern_doDataCombine
*         
*           move.b 4(a1),d5
*           lsr.b #4,d5
*           or.b d5,d4
*         
*       transferVwfBufferPattern_srcAlignmentDone:
      
      * shift src data right by (dstPos * 4)
      moveq #0,d5
      move.b d1,d5
      lsl.b #2,d5
      lsr.l d5,d4
      
      transferVwfBufferPattern_doDataCombine:
      
      * d5 = pixel data for pattern row from buffer
      move.l (a2),d5
      
      * OR src and dst longs
      * (not safe in general, but works for our case where
      * bg color = $1 and fg color = $f.
      * otherwise, we'd need to mask this appropriately.)
      or.l d4,d5
      
      * save back to buffer
      move.l d5,(a2)
      
      * move dstptr/srcptr to next line
      move.l #patternRowByteSize,d6
      add.l d6,a2
*      lsl.l #1,d6
      * account for row padding
      lsl.l #2,d6
      add.l d6,a1
      
      * do next row
      dbf d7,transferVwfBufferPattern_patternRowCopyLoop
    
    movem.l (a7)+,a1-a2/d0-d2
    rts
  
  * v2
*   transferVwfBufferPattern:
*     
*     movem.l a1-a2/d0-d2,-(a7)
*     
*     * compute initial src/dst pointers
*     moveq.l #0,d0
*     * src
*     move.b d2,d0
*     lsr.b #1,d0
*     add.l d0,a1
*     * dst
* *    move.b d1,d0
* *    lsr.b #1,d0
* *    add.l d0,a2
*     
*     * d7 = pattern line counter
* *    moveq.l #0,d7
* *    move.b #patternH-1,d7
*     moveq #patternH-1,d7
*     transferVwfBufferPattern_patternRowCopyLoop:
*     
* *      movem.l a1-a2/d1-d2,-(a7)
*     
*       * read a long's worth of data from src.
*       
*       * if srcPos/2 is even, we're word-aligned and 
*       * can read src data as a long
*       btst #1,d2
*       bne transferVwfBufferPattern_srcNotWordAligned
*         move.l (a1),d4
*         
*         * if srcPos odd, we need to do nybble alignment
*         btst #0,d2
*         bne transferVwfBufferPattern_doNybbleAlignShift
*         
*         bra transferVwfBufferPattern_srcReadDone
*       transferVwfBufferPattern_srcNotWordAligned:
*       * else we have to read as bytes
*       
*       * byte 0
*       move.b 0(a1),d4
*       lsl.w #8,d4
*       * byte 1
*       move.b 1(a1),d4
*       lsl.l #8,d4
*       * byte 2
*       move.b 2(a1),d4
*       lsl.l #8,d4
*       * byte 3
*       move.b 3(a1),d4
*       
*       * if srcPos is odd, we have to shift the result left a nybble
*       btst #0,d2
*       beq transferVwfBufferPattern_srcAlignmentDone
*       transferVwfBufferPattern_doNybbleAlignShift:
*         lsl.l #4,d4
*         
*         * if width is 8, we have to read an extra src byte to get
*         * the last nybble
*         cmp.b #8,d3
*         * if width is 8, we can also skip the other shift
*         bne transferVwfBufferPattern_doDataCombine
*         
*           move.b 4(a1),d5
*           lsr.b #4,d5
*           or.b d5,d4
*         
*       transferVwfBufferPattern_srcAlignmentDone:
*       
*       transferVwfBufferPattern_srcReadDone:
*       
*       * shift src data right by (dstPos * 4)
*       moveq #0,d5
*       move.b d1,d5
*       lsl.b #2,d5
*       lsr.l d5,d4
*       
*       transferVwfBufferPattern_doDataCombine:
*       
*       * d5 = pixel data for pattern row from buffer
*       move.l (a2),d5
*       
*       * OR src and dst longs
*       * (not safe in general, but works for our case where
*       * bg color = $1 and fg color = $f.
*       * otherwise, we'd need to mask this appropriately.)
*       or.l d4,d5
*       
*       * save back to buffer
*       move.l d5,(a2)
*         
* *      movem.l (a7)+,a1-a2/d1-d2
*       
*       * move dstptr/srcptr to next line
*       move.l #patternRowByteSize,d6
*       add.l d6,a2
* *      lsl.l #1,d6
*       * account for row padding
*       lsl.l #2,d6
*       add.l d6,a1
*       
*       * do next row
*       dbf d7,transferVwfBufferPattern_patternRowCopyLoop
*     
*     movem.l (a7)+,a1-a2/d0-d2
*     rts
    
  * old, slow routine
*   transferVwfBufferPattern:
*     
*     movem.l a1-a2/d0-d2,-(a7)
*     
*     * compute initial src/dst pointers
*     moveq.l #0,d0
*     * src
*     move.b d2,d0
*     lsr.b #1,d0
*     add.l d0,a1
*     * dst
*     move.b d1,d0
*     lsr.b #1,d0
*     add.l d0,a2
*     
*     * d7 = pattern line counter
*     moveq.l #0,d7
*     move.b #patternH-1,d7
*     transferVwfBufferPattern_patternRowCopyLoop:
*     
*       movem.l a1-a2/d1-d2,-(a7)
*       
*       * d4 = srcdata
* *      moveq.l #0,d4
*       * d5 = dstdata
* *      moveq.l #0,d5
*       
*       * d6 = number of pixels to copy from src
*       moveq.l #0,d6
*       move.b d3,d6
*       subq #1,d6
*       transferVwfBufferPattern_srcReadLoop:
*         * read in src pattern data a byte at a time.
*         * this corresponds to 2 pixels.
*         move.b (a1),d4
*         
*         * if srcPos is EVEN, we want the high nybble.
*         * otherwise, we want to increment src.
*         move.b d2,d0
*         andi.b #1,d0
*         bne transferVwfBufferPattern_srcReadLoop_srcPosNotEven
*         transferVwfBufferPattern_srcReadLoop_srcPosIsEven:
*           lsr.b #4,d4
*           bra transferVwfBufferPattern_srcReadLoop_srcPosParCheckDone
*         transferVwfBufferPattern_srcReadLoop_srcPosNotEven:
*           tst.b (a1)+
*         transferVwfBufferPattern_srcReadLoop_srcPosParCheckDone:
*         * increment srcPos
*         addi.b #1,d2
*         
*         * mask to target nybble only
*         and.b #$0F,d4
*         
*         * read dst
*         move.b (a2),d5
*         
*         * if penPos is even, target high nybble
*         move.b d1,d0
*         andi.b #1,d0
*         bne transferVwfBufferPattern_srcReadLoop_dstPosNotEven
*         transferVwfBufferPattern_srcReadLoop_dstPosIsEven:
*           lsl.b #4,d4
* *          bra transferVwfBufferPattern_srcReadLoop_dstPosParCheckDone
*         transferVwfBufferPattern_srcReadLoop_dstPosNotEven:
*         
*         * OR src with dst
*         * WARNING: this is not safe for the general case!
*         * but we're using a monochrome font where visible color
*         * is 0xF and background color is 0x1, so it's fine for
*         * this purpose.
*         or.b d4,d5
*         
*         * write to dst
*         move.b d5,(a2)
*         
*         * if penPos is odd, increment dst ptr
*         tst.b d0
*         beq transferVwfBufferPattern_srcReadLoop_dstIncFail
*           tst.b (a2)+
*         transferVwfBufferPattern_srcReadLoop_dstIncFail:
*         * increment penPos
*         addi.b #1,d1
*         
*         * check if all pixels copied
* *        tst d6
* *        bne transferVwfBufferPattern_srcReadLoop
*         dbf d6,transferVwfBufferPattern_srcReadLoop
*         
*       movem.l (a7)+,a1-a2/d1-d2
*       
*       * move dstptr/srcptr to next line
*       move.l #patternRowByteSize,d6
*       add.l d6,a2
*       move.l #patternRowByteSize*2,d6
*       add.l d6,a1
*       
*       * do next row
*       dbf d7,transferVwfBufferPattern_patternRowCopyLoop
*     
*     movem.l (a7)+,a1-a2/d0-d2
*     rts
  
  *********************************************************************
  * cait sith plurality stuff
  *********************************************************************
  
  **********************************
  * capsule prompt
  **********************************

  * D0 = monster ID
  newCapsuleReleasePrompt:
    * save monster ID
*    move.w d0,(capsuleReleaseEnemyId)
    
    * make up work
    * put monster name in buffer
    jsr $8272
    
    * check for cait siths id
*     move.w (capsuleReleaseEnemyId),d0
*     cmp.w #caitSithsIdNum,d0
    move.b (capsuleMonsterId),d0
    cmp.b #caitSithsIdNum,d0
    beq newCapsuleReleasePrompt_enemyNotCaitSith
      * original behavior
      move.w #$25,d0
      jmp $81E2
    newCapsuleReleasePrompt_enemyNotCaitSith:
    
    * queue new script
    lea newCapsulePluralReleasePrompt,a2
    jsr $82A6
    jmp $81E6
    
  
  **********************************
  * capsule released
  **********************************
  
  newCapsuleReleased:
    
    * check for cait siths id
*    move.w (capsuleReleaseEnemyId),d0
    move.b (capsuleMonsterId),d0
    cmp.b #caitSithsIdNum,d0
    beq newCapsuleReleased_enemyNotCaitSith
      * original behavior
      move.w #$26,d0
      jsr $8296
      jmp $821C
    newCapsuleReleased_enemyNotCaitSith:
    
    lea newCapsulePluralReleased,a2
    jsr $82A6
    jmp $821C
  
  **********************************
  * monster encounter
  **********************************
  
  newMonsterEncounter:
    * check encountered monster index
    move.b (encounteredMonsterId),d0
    andi.b #$1F,d0
    
    cmp.b #caitSithsIdNum,d0
    beq newMonsterEncounter_isCaitSith
      * make up work
      move.w #6,d0
      jsr $459E
      jmp $3986
    newMonsterEncounter_isCaitSith:
    
    lea newMonsterEncounterPlural,a2
    jsr $45AE
    jmp $3986
  
  **********************************
  * amigo defeat
  **********************************
  
  * this is actually a high-level handler for battle script
  * messages.
  * we have to screen for the specific message we want.
  newAmigoDefeat:
    * make up work
    move.w (a2,d0),d0
    lea (a2,d0),a3
    
    * check if the target script address we just obtained is
    * that of the amigo defeated message
    move.l a3,d0
    cmp.l #$A2672,d0
    bne newAmigoDefeat_done
    
      * check defeated amigo index
      move.b (capsuleMonsterId),d0
      andi.b #$1F,d0
      
      cmp.b #caitSithsIdNum,d0
      bne newAmigoDefeat_done
      
        * use new message
        lea newAmigoDefeatedPlural,a3
    
    newAmigoDefeat_done:
    jmp $46A2
  
  newAmigoDefeat_internal:
*     org $4BE2E
*     capsuleScriptWaitLoc:
    * delay destroying the capsule monster until the script
    * indicating its defeat has run, so that the script runner
    * can check for the cait sith id and special-case it accordingly
    jsr $122C
    jsr $122C
    tst.b $FFFF8520
    beq newAmigoDefeat_internal_done
      jmp $4BE2E
    newAmigoDefeat_internal_done:
    * destroy capsule monster
    clr.b capsuleMonsterId
    jmp $4BF3E
    
    

  *********************************************************************
  * new graphic header packs
  *********************************************************************
  
  **********************************
  * title screen
  **********************************
  
  titleGrpPackLoad:
    lea newTitleGrpPack,a2
    jsr queueDynamicLoad
    jmp $91CA8
  
  titleGrpPackLoad_reload:
    lea newTitleGrpPack,a2
    jsr queueDynamicLoad
    jmp $92414
  
  newTitleGrpPack:
*    dc.w $8000,$0D22,$0000
*    dc.w $8000,$0D24,$2000
    include out/packs/pack240000-0.inc
*    dc.w $8000,$0D26,$4000
    include out/packs/pack240000-1.inc
    dc.w $8000,$0F2A,$8000
*    dc.w $8000,$1144,$C000
    include out/packs/pack240000-2.inc
*    dc.w $8000,$1146,$E000
    include out/packs/pack240000-3.inc
    dc.w $FFFF

  *********************************************************************
  * new title screen sprite text
  *********************************************************************
  
  **********************************
  * bouncy messages
  **********************************
  
  * a0 = object ptr
  * a2 = srcptr
  newSendBouncyMessage:
    * fetch count of input blocks from srcptr
    move.w (a2)+,d0
    * save count to object
    move.w d0,$2C(a0)
    
    newSendBouncyMessage_drawLoop:
      * compute ypos
      
      move.b $37(a0),d0
      subi.b #$20,d0
      move.b d0,$37(a0)
      move.w #$400,d1
      
      * this multiplies d0 (8-bit) by d1 (16-bit)
      * and returns the 24-bit result in d2
      jsr mult8x16
      * get high 16 bits of fixed-point result
      swap d2
      * base ypos = 0x6C
      moveq #$6C,d3
      add.w d2,d3
      * xpos
      move.w $12(a0),d2
      * base pattern num
      clr.w d1
      jsr addSpritesToBuffer
      * update xpos
*      addi.w #$10,$12(a0)
      subq.w #1,$2C(a0)
      bne newSendBouncyMessage_drawLoop
    
    rts

  *********************************************************************
  * new intro/ending cutscene runner
  *********************************************************************
    
*   newIntroEndingScript:
*     * make up work
*     move.w #$C000,$FFFF8516
*     
*     jmp $48D00
*     rts

  *********************************************************************
  * new map label change
  *********************************************************************
  
*   newMapLabelChange:
*     * make up work
*     jsr $4AEE2
*     
*     * clear the portion of the nametable that contains the map number
* *     move.w #$C6B4,d0
* *     move.w #$0002,d1
* *     move.w #$0001,d2
* *     move.w #$8000,d5
* *     jsr clearNametableArea
*     * whole label
*     move.w #$C69E,d0
*     move.w #13,d1
*     move.w #$0001,d2
*     move.w #$8000,d5
*     jsr clearNametableArea
*     
*     * make up work
*     jsr $45BE
*     jmp $3608

  *********************************************************************
  * new map label print buffer fill
  *********************************************************************

  * d0 = index number of floor
  newMapLabelPrintBufferFill:
    * make up work: fetch buffer content and place in buffer
    lea $4602,a2
    move.l (a2,d1),$FFFF86AA
    
    * look up spacing string and send to buffer
    lsl.w #1,d1
    lea mapLabelPrintBufferPadTable,a2
    move.l 0(a2,d1),$FFFF86AA+$4
    * set 5th character to a zero-pixel space.
    * since the space characters are implemented by setting
    * glyphWidth to zero and advanceWidth to the target width,
    * they are not immediately applied to the character buffer
    * but held in reserve until the next character is printed.
    * by printing a zero-width character, we force the spacing
    * to be applied as written.
*    move.w #space0px,$FFFF86AA+$8
    * never mind. for B4F we must _prevent_ any spacing from being
    * applied, because the string fills the available space exactly.
    * so now this information is simply included in the table.
    move.l 4(a2,d1),$FFFF86AA+$8
    
    jmp $45E0
  
  * hardcoded because this is so small and esoteric.
  * if you need it un-hardcoded, comment this out,
  * enable the newMapLabelChange stuff above,
  * and restore the corresponding strings' buffer size
  * opcodes to their original lengths in the script.
  * this will work fine at the cost of flicker every time
  * the map label is reloaded.
  
  * each entry consists of 2 characters that pad out the
  * corresponding map string such that it is as long as the
  * longest map string possible, ensuring any existing
  * content will be hidden.
  ds.w 0
  mapLabelPrintBufferPadTable:
    * aboveground floors
    * target width: 16 (for floor "10")
    
    * 1 = 5px
    dc.w space8px,space3px,space0px,0
    * 2 = 8px
    dc.w space8px,nullchar,space0px,0
    * 3 = 8px
    dc.w space8px,nullchar,space0px,0
    * 4 = 9px
    dc.w space7px,nullchar,space0px,0
    * 5 = 8px
    dc.w space8px,nullchar,space0px,0
    * 6 = 9px
    dc.w space7px,nullchar,space0px,0
    * 7 = 9px
    dc.w space7px,nullchar,space0px,0
    * 8 = 9px
    dc.w space7px,nullchar,space0px,0
    * 9 = 9px
    dc.w space7px,nullchar,space0px,0
    * 10 = 16px
    dc.w nullchar,nullchar,space0px,0
    * 11 = 11px
    dc.w space5px,nullchar,space0px,0
    * 12 = 14px
    dc.w space2px,nullchar,space0px,0
    
    * belowground floors
    * target width: 9 (for floor "4")
    
    * 4 = 9px
    dc.w nullchar,nullchar,nullchar,0
    * 3 = 8px
    dc.w nullchar,nullchar,space0px,0
    * 2 = 8px
    dc.w nullchar,nullchar,space0px,0
    * 1 = 5px
    dc.w space3px,nullchar,space0px,0
    

  *********************************************************************
  * item drop demonstratives
  *********************************************************************

  doNewItemDroppedFromFullInventoryScript:
    * rewrite print buffer to contain item name with
    * near demonstrative
    move.b pickedUpItemId,d0
    bsr itemNameWithNearDemonstrativeToBuffer
    
    * make up work
    move.w #$E,d0
    jmp $459E

  *********************************************************************
  * limited-length item names for item combining
  *********************************************************************
  
  * d0 = item ID
  shortItemNameToBuffer:
    cmp.b #itemId_hungryElephant,d0
    bne shortItemNameToBuffer_notElephant
      lea shortItemName_hungryElephant,a2
      bra copyNameToPrintBuffer
    shortItemNameToBuffer_notElephant:
    jmp $71EE

  *********************************************************************
  * item names with indefinite articles
  *********************************************************************
  
  * d0 = item ID
  itemNameWithIndefiniteArticleToBuffer:
    lea itemIndefiniteArticles,a2
    and.w #$003F,d0
    lsl.w #1,d0
    move.w (a2,d0),d0
    lea (a2,d0),a2
    bra copyNameToPrintBuffer

  *********************************************************************
  * item names with near demonstratives (this/these)
  *********************************************************************
  
  * d0 = item ID
  itemNameWithNearDemonstrativeToBuffer:
    lea itemNearDemonstratives,a2
    and.w #$003F,d0
    lsl.w #1,d0
    move.w (a2,d0),d0
    lea (a2,d0),a2
    bra copyNameToPrintBuffer

  *********************************************************************
  * subroutine for copying new material to item buffer
  *********************************************************************
  
  * a2 = pointer to target script
  copyNameToPrintBuffer:
    lea $FFFF86AA,a3
    clr.l (a3)
    clr.l 4(a3)
    clr.l 8(a3)
    clr.l 12(a3)
    
    * construct a jump command
    move.w #opD0Id,(a3)+
    move.l a2,(a3)
    
    rts

  *********************************************************************
  * momomo deposit/withdraw fixes
  *********************************************************************
  
  **********************************
  * deposit
  **********************************
  
  newMomomoDeposit:
    * check target item ID
    cmp.b #itemId_fireExtinguisher,$28(a0)
    bne newMomomoDeposit_notFireExtinguisher
      lea momomoDeposit_fireExtinguisher,a2
      move.w #8,d2
      jsr $39FDA
      bra newMomomoDeposit_done
    newMomomoDeposit_notFireExtinguisher:
    
    * make up work
    move.w #$11,d0
    jsr $39FBA
    
    newMomomoDeposit_done:
    jmp $43C9C
  
  **********************************
  * withdraw
  **********************************
    
  newMomomoWithdraw:
    * check target item ID
    cmp.b #itemId_fireExtinguisher,$28(a0)
    bne newMomomoWithdraw_notFireExtinguisher
      lea momomoWithdraw_fireExtinguisher,a2
      move.w #8,d2
      jsr $39FDA
      bra newMomomoWithdraw_done
    newMomomoWithdraw_notFireExtinguisher:
    
    * make up work
    move.w #$14,d0
    jsr $39FBA
    
    newMomomoWithdraw_done:
    jmp $43EC2

  *********************************************************************
  * karaoke
  *********************************************************************
  
  * d0 = index of target line
  newKaraokeLyricSend:
    * d1 = index
    move.w d0,d1
    
    * look up tilemap pointer
    lsl.w #2,d0
    lea newKaraokeMapTable,a3
    move.l (a3,d0),a2
    
    * vdp target
*    move.w #$D602,d0
    * move up a line from original so english translation is not in
    * overscan area
    move.w #$D602-$100,d0
    * if index is odd, add 0x300 to vdp target
    btst #0,d1
    beq newKaraokeLyricSend_indexNotOdd
      add.w #$0300,d0
    newKaraokeLyricSend_indexNotOdd:
    
    * dimensions = 38*3
    move.w #38-1,d1
    move.w #3-1,d2
    
    * done
    jmp $8FCBA
  
  karaokeHideFinalLine:
    * display new line 10, which is blank and used to cover up
    * the last line
    move.w #10,d0
    jsr $8FC9E
    
    * make up work
    move.w #$FD90,d0
    move.w d0,$A(a0)
    jmp $8FEB0
  
  karaokeFixScrollModeInit:
    * here, the game wants to change the horizontal scrolling mode
    * to 2 (per-row scrolling).
    * the original game failed to mask off the bits first, meaning
    * this switch would fail if the mode was already set to 3.
    
    * get memory copy of vdp mode3 reg
    move.b $FFFF8A5B,d0
    * mask off hscroll type bits
    andi.b #$FC,d0
    * set hscroll mode to 2
    ori.b #$02,d0
    * resume normal flow
    jmp $8EE0C

  *********************************************************************
  * extra lines in ending
  *********************************************************************
    
  
  extendEnding_double:
    * double delay
    lsl.w #1,d0
    add.w #60,d0
    * make up work
    jmp $120C
  
  extendEnding_oneHalf:
    move.w d0,d1
    lsr.w #1,d1
    add.w d1,d0
    add.w #60,d0
    * make up work
    jmp $120C
    
  extendEnding_doubleOneHalf:
    move.w d0,d1
    lsr.w #1,d1
    * double delay
    lsl.w #1,d0
    add.w d1,d0
    add.w #60,d0
    * make up work
    jmp $120C
    
  extendEnding_triple:
    move.w d0,d1
    * double delay
    lsl.w #1,d0
    add.w d1,d0
    add.w #60,d0
    * make up work
    jmp $120C
  
  ********************************************************************
  * credits
  ********************************************************************

obj_creditsParent_waitFlag equ $26

obj_creditsRunner_parentPtr equ $2E
obj_creditsRunner_srcTables equ $40
obj_creditsRunner_srcPtr equ $44
obj_creditsRunner_timer equ $48
obj_creditsRunner_deathTime equ $4A
obj_creditsRunner_parentNotifyDoneFlag equ $4C

creditsSrcTable_stdOffset equ $0
creditsSrcTable_cleanupOffset equ $2

creditsEvent_nullId equ $0000
creditsEvent_sendTilemapId equ $0001
creditsEvent_clearAreaId equ $0002

creditsRunnerVdpBase equ $C000
creditsRunnerVdpRowSize equ $80
creditsRunnerClearTileId equ $0000
  
  **********************************
  * spawn a credits runner
  * a0 = parent pointer (should be the main credits thread)
  * a2 = sequence data pointer
  **********************************
  
  spawnCreditsRunner:
    lea creditsRunnerUpdate,a1
    * returns a1 = pointer to newly spawned object
    jsr spawnObj
    
    **********************************
    * initialize
    **********************************
    
    * set flags6 to some value that appears to do what we want.
    * the only flag whose meaning i know is bit 7, which is cleared
    * to indicate that this object does not get drawn automatically.
    move.b #$BF,obj_flags6(a1)
    * set parent
    move.l a0,obj_creditsRunner_parentPtr(a1)
    * set sequence data
    move.l a2,obj_creditsRunner_srcTables(a1)
    * no timeout
    move.w #$FFFF,obj_creditsRunner_deathTime(a1)
    
    rts
  
  * d0 = time limit
  spawnCreditsRunnerWithTimeLimit:
    move.l d0,-(a7)
      lea creditsRunnerUpdate,a1
      * returns a1 = pointer to newly spawned object
      jsr spawnObj
    move.l (a7)+,d0
    
    **********************************
    * initialize
    **********************************
    
    * set flags6 to some value that appears to do what we want.
    * the only flag whose meaning i know is bit 7, which is cleared
    * to indicate that this object does not get drawn automatically.
    move.b #$BF,obj_flags6(a1)
    * set parent
    move.l a0,obj_creditsRunner_parentPtr(a1)
    * set sequence data
    move.l a2,obj_creditsRunner_srcTables(a1)
    * no timeout
    move.w d0,obj_creditsRunner_deathTime(a1)
    
    rts
  
  **********************************
  * credits runner update routine
  * a0 = self
  **********************************
  
  * shortcut to avoid bra instructions
  creditsRunnerIdle:
    rts
  
  creditsRunnerUpdate:
    
    **********************************
    * initialize
    **********************************
    
    * zero timer
    move.w #0,obj_creditsRunner_timer(a1)
    
    * srcptr = std events
    * a1 = table pointer
    move.l obj_creditsRunner_srcTables(a0),a1
    * fetch offset
    move.w creditsSrcTable_stdOffset(a1),d0
    * a1 = srcptr
    lea (a1,d0),a1
    * save to self
    move.l a1,obj_creditsRunner_srcPtr(a0)
    
    **********************************
    * main logic loop
    **********************************
    
    * resume from here next update
    jsr objSetResumePoint
    
    creditsRunnerUpdate_mainLoop:
      * handle next event(s)
      jsr creditsRunnerProcessPendingEvents
      
      * is parent dead?
      move.l obj_creditsRunner_parentPtr(a0),a1
      beq creditsRunnerUpdate_mainLoop_noParent
        move.l obj_creditsRunner_parentPtr(a0),a1
        move.w obj_creditsParent_waitFlag(a1),d0
        beq creditsRunnerUpdate_done
      creditsRunnerUpdate_mainLoop_noParent:
      
      * are we out of time?
      move.w obj_creditsRunner_deathTime(a0),d0
      cmp.w #$FFFF,d0
      beq creditsRunnerUpdate_mainLoop_noTimeout
        * check if timer has reached death time
        cmp.w obj_creditsRunner_timer(a0),d0
        * if > our time, done
        ble creditsRunnerUpdate_done
      creditsRunnerUpdate_mainLoop_noTimeout:
      
      * did we reach end of src data?
*       move.l obj_creditsRunner_srcPtr(a0),a1
*       cmp.w #$FFFF,(a1)
*       beq creditsRunnerUpdate_waitForEnd
      
      * increment timer
      move.w obj_creditsRunner_timer(a0),d0
      addq.w #1,d0
      move.w d0,obj_creditsRunner_timer(a0)
      
      * done
      rts
    
    **********************************
    * wait for parent wait flag to
    * get cleared
    **********************************
    
*     creditsRunnerUpdate_waitForEnd:
*     jsr objSetResumePoint
*       
*       * are we out of time?
*       move.w obj_creditsRunner_deathTime(a0),d0
*       cmp.w #$FFFF,d0
*       beq creditsRunnerUpdate_waitForEnd_noTimeout
*         * check if timer has reached death time
*         cmp.w obj_creditsRunner_timer(a0),d0
*         * if > our time, done
*         ble creditsRunnerUpdate_done
*       creditsRunnerUpdate_waitForEnd_noTimeout:
*     
*       move.l obj_creditsRunner_parentPtr(a0),a1
*       move.w obj_creditsParent_waitFlag(a1),d0
*       bne creditsRunnerIdle
    
    **********************************
    * do cleanup
    **********************************
    
    creditsRunnerUpdate_done:
    
    * srcptr = cleanup events
    * a1 = table pointer
    move.l obj_creditsRunner_srcTables(a0),a1
    * fetch offset
    move.w creditsSrcTable_cleanupOffset(a1),d0
    * a1 = srcptr
    lea (a1,d0),a1
    * save to self
    move.l a1,obj_creditsRunner_srcPtr(a0)
    
    * do event processing.
    * all cleanup events should have their time set to 0,
    * so the entire sequence will trigger.
    jsr creditsRunnerProcessPendingEvents
    
    * notify parent that we are finished if specified
    tst.b obj_creditsRunner_parentNotifyDoneFlag(a0)
    beq creditsRunnerUpdate_noParentNotify
      move.l obj_creditsRunner_parentPtr(a0),a1
      clr.w $26(a1)
    creditsRunnerUpdate_noParentNotify:
    
*    jsr objSetResumePointAndYield
    
    * kill self
    jmp killObj
    
  **********************************
  * event data processor
  **********************************
  
  creditsRunnerProcessPendingEvents:
    * a1 = srcptr
    move.l obj_creditsRunner_srcPtr(a0),a1
    creditsRunnerProcessPendingEvents_loop:
      * check if at terminator
      cmp.w #$FFFF,(a1)
      beq creditsRunnerProcessPendingEvents_done
      
      * d0 = current timer value
      move.w obj_creditsRunner_timer(a0),d0
      * check event's time
      cmp.w (a1),d0
      * if > our time, done
      bcs creditsRunnerProcessPendingEvents_done
      
      * handle event
      addq.l #2,a1
      jsr creditsRunnerHandleEvent
      
      * loop
      bra creditsRunnerProcessPendingEvents_loop
    
    creditsRunnerProcessPendingEvents_done:
    * save updated srcptr
    move.l a1,obj_creditsRunner_srcPtr(a0)
    rts
  
  * a1 = srcptr; return updated value
  creditsRunnerHandleEvent:
    * check event's type
    
    move.w (a1)+,d0
    
    cmp.w #creditsEvent_nullId,d0
    bne creditsRunnerHandleEvent_notNull
      rts
    creditsRunnerHandleEvent_notNull:
    
    cmp.w #creditsEvent_sendTilemapId,d0
    beq creditsRunnerHandleSendTilemap
    
    cmp.w #creditsEvent_clearAreaId,d0
    beq creditsRunnerHandleClearArea
    
    * should never happen
    rts
  
  creditsRunnerHandleSendTilemap:
    * base tilemap positions
    move.w #creditsRunnerVdpBase,d0
    
    **********************************
    * retrieve parameters
    **********************************
    
    * x
    move.w (a1)+,d1
    lsl.w #1,d1
    add.w d1,d0
    
    * y
    move.w (a1)+,d1
    move.w #creditsRunnerVdpRowSize,d2
    mulu d1,d2
    add.w d2,d0
    
    * d1 = w
    move.w (a1)+,d1
    subq.w #1,d1
    
    * d2 = h
    move.w (a1)+,d2
    subq.w #1,d2
    
    * a2 = src data
    move.l a1,a2
    
    **********************************
    * set up additional write parameters
    **********************************
    
    * rowskip
    move.l #creditsRunnerVdpRowSize<<16,d3
    * flags
    moveq #0,d5
    
    **********************************
    * do the write
    **********************************
    
    jsr sendTilemap_karaoke
    
    **********************************
    * skip past tilemap data in src
    **********************************
    
    move.l a2,a1
    
    rts
  
  creditsRunnerHandleClearArea:
    
    * base tilemap positions
    move.w #creditsRunnerVdpBase,d0
    
    **********************************
    * retrieve parameters
    **********************************
    
    * x
    move.w (a1)+,d1
    lsl.w #1,d1
    add.w d1,d0
    
    * y
    move.w (a1)+,d1
    move.w #creditsRunnerVdpRowSize,d2
    mulu d1,d2
    add.w d2,d0
    
    * d1 = w
    move.w (a1)+,d1
    subq.w #1,d1
    
    * d2 = h
    move.w (a1)+,d2
    subq.w #1,d2
    
    move.w #creditsRunnerClearTileId,d5
    
    jmp clearNametableArea
  
  ********************************************************************
  * credits runner spawners
  ********************************************************************
    
  spawnCreditsRunnerGeneric:
    * make up work
    jsr spawnChildObj
    * save child pointer
    move.w sr,-(a7)
    move.l a1,-(a7)
      * spawn runner
      jsr spawnCreditsRunner
    move.l (a7)+,a1
    move.w (a7)+,sr
    rts
    
  spawnCreditsRunnerWithTimeLimitGeneric:
    move.l d0,d1
      * make up work
      jsr spawnChildObj
    move.l d1,d0
    * save child pointer
    move.w sr,-(a7)
    move.l a1,-(a7)
      * spawn runner
      jsr spawnCreditsRunnerWithTimeLimit
    move.l (a7)+,a1
    move.w (a7)+,sr
    rts
    
  spawnCreditsRunner0:
    lea newCreditsSeq0,a2
    bra spawnCreditsRunnerGeneric
    
  spawnCreditsRunner1:
    lea newCreditsSeq1,a2
    bra spawnCreditsRunnerGeneric
    
  spawnCreditsRunner2a:
    lea newCreditsSeq2a,a2
    bra spawnCreditsRunnerGeneric
    
  spawnCreditsRunner2b:
    lea newCreditsSeq2b,a2
    bra spawnCreditsRunnerGeneric
    
  spawnCreditsRunner3a:
    lea newCreditsSeq3a,a2
    bra spawnCreditsRunnerGeneric
    
  spawnCreditsRunner3b:
    lea newCreditsSeq3b,a2
    bra spawnCreditsRunnerGeneric
    
  spawnCreditsRunner3c:
    lea newCreditsSeq3c,a2
    bra spawnCreditsRunnerGeneric
    
  spawnCreditsRunner4a:
    lea newCreditsSeq4a,a2
    bra spawnCreditsRunnerGeneric
    
  spawnCreditsRunner4b:
    lea newCreditsSeq4b,a2
    bra spawnCreditsRunnerGeneric
    
  spawnCreditsRunner5a:
    lea newCreditsSeq5a,a2
    bra spawnCreditsRunnerGeneric
    
  spawnCreditsRunner5b:
    lea newCreditsSeq5b,a2
    bra spawnCreditsRunnerGeneric
    
  spawnCreditsRunner6:
    lea newCreditsSeq6,a2
    bra spawnCreditsRunnerGeneric
    
  spawnCreditsRunner7a:
    lea newCreditsSeq7a,a2
    bra spawnCreditsRunnerGeneric
    
  spawnCreditsRunner7b:
    lea newCreditsSeq7b,a2
    bra spawnCreditsRunnerGeneric
    
  spawnCreditsRunner7c:
    lea newCreditsSeq7c,a2
    bra spawnCreditsRunnerGeneric
    
*   spawnCreditsRunner7d:
*     lea newCreditsSeq7d,a2
*     bra spawnCreditsRunnerGeneric
    
  spawnCreditsRunner8:
    lea newCreditsSeq8,a2
    bra spawnCreditsRunnerGeneric
    
  spawnCreditsRunner9a:
*     lea newCreditsSeq9a,a2
*     bra spawnCreditsRunnerGeneric
*     move.w #380,d0
*     bra spawnCreditsRunnerWithTimeLimitGeneric
    * make up work
    move.w #$5,$28(a0)
    
    lea newCreditsSeq9a,a2
    move.w #400,d0
    jsr spawnCreditsRunnerWithTimeLimit
    
    * remove parent -- we depend solely on the time limit
    move.l #$00000000,obj_creditsRunner_parentPtr(a1)
    rts
    
    
  spawnCreditsRunner9b:
*     lea newCreditsSeq9b,a2
*     bra spawnCreditsRunnerGeneric
    * make up work: wait
    jsr $120C
    jsr $1216
    
    lea newCreditsSeq9b,a2
    move.w #400,d0
    jsr spawnCreditsRunnerWithTimeLimit
    
    * remove parent -- we depend solely on the time limit
    move.l #$00000000,obj_creditsRunner_parentPtr(a1)
    
    jmp $9885A
    
  spawnCreditsRunner9c:
*     lea newCreditsSeq9c,a2
* *     bra spawnCreditsRunnerGeneric
*     move.w #690,d0
*     bra spawnCreditsRunnerWithTimeLimitGeneric
    * this one works differently from everything else -- there is no
    * child object spawn to interrupt
    
    * make up work
    move.w #$60,$A(a0)
    
    lea newCreditsSeq9c,a2
    move.w #700,d0
    jsr spawnCreditsRunnerWithTimeLimit
    
    * remove parent -- we depend solely on the time limit
    move.l #$00000000,obj_creditsRunner_parentPtr(a1)
    
    rts
    
  *********************************************************************
  * extended credits
  *********************************************************************
    
  extendedCreditsIdle:
    rts
  
  doExtendedCredits:
    * make up work: destroy credits header object
    jsr $11F0
    
    **********************************
    * wait a bit
    **********************************
    
    move.w #60,d0
    jsr $120C
    jsr $1216
    
    **********************************
    * page 10
    **********************************
    
    * load graphics
    * i don't know what FF9630 does but the game always sets it before
    * queueing a load during this sequence, so let's play it safe
    move.b #1,$FFFF9630
    lea credits10GrpPack,a2
    jsr queueDynamicLoad
    
    * wait for graphics to load
    jsr objSetResumePointAndYield
    tst.b dynamicLoadStatus
    bne extendedCreditsIdle
    
    * spawn new credits runner
    lea newCreditsSeq10,a2
    move.w #960,d0
    jsr spawnCreditsRunnerWithTimeLimit
    * turn on parent notification
    move.b #$01,obj_creditsRunner_parentNotifyDoneFlag(a1)
    
    * set notification flag
    move.w #$0001,$26(a0)
    * wait to be notified
    jsr objSetResumePointAndYield
    tst.w $26(a0)
    bne extendedCreditsIdle
    
    * resume normal ending logic
    jmp $98AB2
  
  ********************************************************************
  * reinstate unused "wake up" script in intro
  ********************************************************************
  
  startIntroWakeUpScript:
    * trigger intro script 1
    moveq #1,d0
    jsr runCutsceneScript
    
    * make up work
    lea $FF9498,a2
    jmp $8A304
  
  clearIntroWakeUpScript:
*     * trigger intro script 3C = clear box
*     moveq #$3C,d0
*     jsr runCutsceneScript
*     
*     * make up work
*     move.w #$20,$26(a0)
*     jmp $8A3A6

*     * trigger intro script 3C = clear box
*     moveq #$3C,d0
*     jsr runCutsceneScript
*     
*     * make up work
*     lea $FF94B8,a2
*     jmp $8A3BA
    
    * trigger intro script 3C = clear box
    moveq #$3C,d0
    jsr runCutsceneScript
    
    * make up work
    move.w #$20,$26(a0)
    jmp $8A484
  
  ********************************************************************
  * combine items window clear fix
  ********************************************************************
  
  combineItems_clearWindowsFix_idle:
    rts
  
  combineItems_clearWindowsFix:
    
    * wait for currently active scripts to finish before continuing
    * on to clear the windows
    jsr objSetResumePoint
    move.b scriptActiveFlags,d0
    andi.b #$07,d0
    bne combineItems_clearWindowsFix_idle
    
    
    * make up work
    move.w #$C8AC,d0
    move.w #$C,d1
    jmp $3A296
  
  ********************************************************************
  * the original game has a bug where, if the a-capsule arrow
  * collides with (some?) monsters on the exact frame that they
  * begin an attack, the capture gets flagged as a success but the
  * enemy is not actually sent into the capture animation,
  * causing the game to loop endless with Arle stuck in the
  * item use animation.
  *
  * the code below runs from the arrow's logic after the game detects
  * collision between the arrow and a monster.
  * the bug occurs when the monster has not properly detected the
  * collision and instead started an attack.
  * this simply modifies the arrow's logic so that, if the enemy
  * is not idling, it goes back to the failure state rather than
  * the success one.
  ********************************************************************
  
  aCapsuleHitDoubleCheck:
    * check enemy "state" (0 = idle?)
    tst.w $FFFFC724
    beq aCapsuleHitDoubleCheck_success
      
      * if enemy not in "idle" state,
      * failure
      * jump back to regular "failure" code
*      jmp $8A36
*      move.w #$0000,$FFFFC724
      jmp $8A06
    
    aCapsuleHitDoubleCheck_success:
    * make up work
    move.b #$FF,$FFFF88B6
    jmp $BFF0
  
  ********************************************************************
  * in the true final boss battle, the game occasionally tries to
  * check if the object slot it's operating on is the "special" enemy
  * slot at FFC6E0, and does not despawn the object if so.
  * but the check is bugged: it specifically checks if the target
  * address is 0x00FFC6E0 as a long, when the address will often
  * (always?) be formatted as the equivalent 0xFFFFC6E0.
  * so if e.g. satan uses his HP drain attack, and the player uses
  * a max-level ice storm, satan will be permanently despawned and
  * the battle will never end.
  *
  * this occurs for two different cases, both covered below.
  ********************************************************************
  
  satanDespawnFix1:
    * make up work
    cmpa.l #$FFC6E0,a0
    beq satanDespawnFix1_success
      cmpa.l #$FFFFC6E0,a0
      beq satanDespawnFix1_success
        jmp killObj
    satanDespawnFix1_success:
    jmp $23422
  
  satanDespawnFix2:
    * make up work
    cmpa.l #$FFC6E0,a0
    beq satanDespawnFix2_success
      cmpa.l #$FFFFC6E0,a0
      beq satanDespawnFix2_success
        jmp $29B16
    satanDespawnFix2_success:
    jmp $23422
  
  
*   puyoSpecialStuff:
* temp equ vwfBuffer2Pos+$110
*     move.b temp,d0
*     cmp.b #$00,d0
*     beq puyoSpecialStuff_0
*     cmp.b #$01,d0
*     beq puyoSpecialStuff_0
*     bra puyoSpecialStuff_1
*     
*     
*     puyoSpecialStuff_0:
*       add.b #$1,d0
*       move.b d0,temp
*       jmp $29EBE
*       
*     puyoSpecialStuff_1:
*       add.b #$1,d0
*       move.b d0,temp
*       jmp $2A000
    
    
  *********************************************************************
  * new data
  *********************************************************************
  
  * pattern data
  ds.l 0
  fontPatternData:
    include out/asm/font.inc
  
  * glyph width/advance width table
  ds.l 0
  fontCharTable:
    include out/asm/chartable.inc
  
  * kerning table
  ds.l 0
  kerningTable:
    include out/asm/kerning.inc
  
  * new capsule plural release prompt
  ds.l 0
  newCapsulePluralReleasePrompt:
    include out/asm/capsule_plural_release_prompt.inc
  
  * new capsule plural released
  ds.l 0
  newCapsulePluralReleased:
    include out/asm/capsule_plural_released.inc
  
  * monster encountered plural
  ds.l 0
  newMonsterEncounterPlural:
    include out/asm/monster_encounter_plural.inc
  
  * monster defeated plural
  ds.l 0
  newAmigoDefeatedPlural:
    include out/asm/monster_defeated_plural.inc
  
  * short item names
  ds.l 0
  shortItemName_hungryElephant:
    include out/asm/hungry_elephant_short.inc
  
  * momomo fire extinguisher deposit message
  ds.l 0
  momomoDeposit_fireExtinguisher:
    include out/asm/momomo_fireext_deposit.inc
  
  * momomo fire extinguisher withdraw message
  ds.l 0
  momomoWithdraw_fireExtinguisher:
    include out/asm/momomo_fireext_withdraw.inc
  
  * offset table of item names with indefinite articles
  ds.l 0
  itemIndefiniteArticles:
    include out/asm/item_articles_indefinite.inc
  
  * offset table of item names with demonstratives
  ds.l 0
  itemNearDemonstratives:
    include out/asm/item_demonstratives.inc
  
  * title bouncy messages
  ds.l 0
  newPressStartMessageStructure:
    include out/spritetxt/title-0.inc
  newOptionPromptStructure:
    include out/spritetxt/title-1.inc
  newLoadPromptStructure:
    include out/spritetxt/title-2.inc
  newPresentPromptStructure:
    include out/spritetxt/title-3.inc
  
  * title options
  newNewGameTextStructure:
    include out/spritetxt_static/newgame.inc
  newContinueTextStructure:
    include out/spritetxt_static/continue.inc
  newPresentTextStructure:
    include out/spritetxt_static/present.inc
  newJournal1TextStructure:
    include out/spritetxt_static/journal1.inc
  newJournal2TextStructure:
    include out/spritetxt_static/journal2.inc
  newSorcerySongTextStructure:
    include out/spritetxt_static/sorcerysong.inc
  newSoundTestTextStructure:
    include out/spritetxt_static/soundtest.inc
  newSamplesTextStructure:
    include out/spritetxt_static/samples.inc
  
  * bayoen maps
  ds.l 0
  bayoenNameMap0:
    include out/maps/bayoen_name_0.inc
  bayoenNameMap1:
    include out/maps/bayoen_name_1.inc
  bayoenNameMap2:
    include out/maps/bayoen_name_2.inc
  bayoenNameMap3:
    include out/maps/bayoen_name_3.inc
  bayoenNameMap4:
    include out/maps/bayoen_name_4.inc
  bayoenNameMap5:
    include out/maps/bayoen_name_5.inc
  bayoenNameMap6:
    include out/maps/bayoen_name_6.inc
  
  * bayoen ID assignment table
  ds.l 0
  newBayoenIdTable:
    dc.l bayoenNameMap0,bayoenNameMap1,bayoenNameMap2,bayoenNameMap3
    dc.l bayoenNameMap4,bayoenNameMap5,bayoenNameMap6
  
  * cockadoodle maps
  ds.l 0
  cockadoodleMap0:
    include out/maps/cockadoodle_0.inc
  cockadoodleMap1:
    include out/maps/cockadoodle_1.inc
  cockadoodleMap2:
    include out/maps/cockadoodle_2.inc
  cockadoodleMap3:
    include out/maps/cockadoodle_3.inc
  cockadoodleMap4:
    include out/maps/cockadoodle_4.inc
  cockadoodleMap5:
    include out/maps/cockadoodle_5.inc
  cockadoodleMap6:
    include out/maps/cockadoodle_6.inc
  
  * cockadoodle structure table
  ds.l 0
  newCockadoodleIdTable:
    dc.l cockadoodleMap0,cockadoodleMap1,cockadoodleMap2,cockadoodleMap3
    dc.l cockadoodleMap4,cockadoodleMap5,cockadoodleMap6
  
  * new karaoke map lookup table
  ds.l 0
  newKaraokeMapTable:
    dc.l newKaraokeMap0,newKaraokeMap1,newKaraokeMap2,newKaraokeMap3
    dc.l newKaraokeMap4,newKaraokeMap5,newKaraokeMap6,newKaraokeMap7
    dc.l newKaraokeMap8,newKaraokeMap9,newKaraokeMap10
  
  * new karaoke maps
  ds.l 0
  newKaraokeMap0:
    include out/maps/karaoke_line0.inc
  newKaraokeMap1:
    include out/maps/karaoke_line1.inc
  newKaraokeMap2:
    include out/maps/karaoke_line2.inc
  newKaraokeMap3:
    include out/maps/karaoke_line3.inc
  newKaraokeMap4:
    include out/maps/karaoke_line4.inc
  newKaraokeMap5:
    include out/maps/karaoke_line5.inc
  newKaraokeMap6:
    include out/maps/karaoke_line6.inc
  newKaraokeMap7:
    include out/maps/karaoke_line7.inc
  newKaraokeMap8:
    include out/maps/karaoke_line8.inc
  newKaraokeMap9:
    include out/maps/karaoke_line9.inc
  newKaraokeMap10:
    include out/maps/karaoke_line10.inc
  
  * new credits graphic packs
  
  * orig = 9DF7E
  newCredits0GrpPack:
    * copy old material verbatim
    * except for the header graphics which i've decided at the last minute
    * to have in english 
*    dc.b $80,$00,$14,$10,$00,$00
    include out/packs/pack270000-12.inc
    dc.b $80,$00,$0F,$2A,$80,$00,$80,$00,$0C
    dc.b $12,$A0,$00,$80,$00,$14,$0E,$C0,$00,$80,$00,$14,$0E,$E0,$00
    include out/packs/pack270000-1.inc
    dc.w $FFFF
  
  * orig = 9DF9E
  newCredits1GrpPack:
*     dc.b $80,$00,$14,$12,$00,$00,
    include out/packs/pack270000-13.inc
    dc.b $80,$00,$0D,$14,$20,$00,$80,$00,$0D
    dc.b $16,$40,$00,$80,$00,$10,$10,$56,$00,$80,$00,$10,$12,$90,$00
    include out/packs/pack270000-2.inc
    dc.w $FFFF
  
  * orig = 9DFBE
  newCredits2GrpPack:
*     dc.b $80,$00,$14,$14,$00,$00,
    include out/packs/pack270000-14.inc
    dc.b $80,$00,$0F,$20,$1C,$00,$80,$00,$0F
    dc.b $26,$3C,$00,$80,$00,$0F,$20,$56,$00,$80,$00,$0F,$24,$90,$00
    include out/packs/pack270000-3.inc
    dc.w $FFFF
  
*   * orig = 9DFDE
*   newCredits3aGrpPack:
*     dc.b $80,$00,$0E,$06,$1C,$00,$80,$00,$10,$08,$56,$00,$80,$00,$10
*     dc.b $0A,$90,$00
*     include out/packs/pack270000-4.inc
*     dc.w $FFFF
  
  * orig = 9DFF2
  newCredits3GrpPack:
*     dc.b $80,$00,$14,$16,$00,$00,
    include out/packs/pack270000-15.inc
    dc.b $80,$00,$0E,$08,$90,$00,$80,$00,$0E
    dc.b $0A,$56,$00,$80,$00,$13,$36,$C0,$00
    include out/packs/pack270000-4.inc
    dc.w $FFFF
  
  * orig = 9E020
  newCredits4GrpPack:
*     dc.b $80,$00,$14,$18,$00,$00,
    include out/packs/pack270000-16.inc
    dc.b $80,$00,$0D,$1A,$20,$00,$80,$00,$0D
    dc.b $1C,$40,$00,$80,$00,$0F,$06,$56,$00,$80,$00,$0F,$08,$90,$00
    include out/packs/pack270000-5.inc
    dc.w $FFFF
  
  * orig = 9E040
  newCredits5GrpPack:
*     dc.b $80,$00,$14,$1A,$00,$00,
    include out/packs/pack270000-17.inc
    dc.b $80,$00,$0F,$0E,$56,$00,$80,$00,$0F
    dc.b $12,$90,$00
    include out/packs/pack270000-6.inc
    dc.w $FFFF
  
  * orig = 9E054
  newCredits6GrpPack:
*     dc.b $80,$00,$14,$1C,$00,$00,
    include out/packs/pack270000-18.inc
    dc.b $80,$00,$0E,$20,$56,$00,$80,$00,$0E
    dc.b $22,$90,$00,$80,$00,$13,$36,$C0,$00
    include out/packs/pack270000-7.inc
    dc.w $FFFF
  
  * orig = 9E06E
  newCredits7GrpPack:
*     dc.b $80,$00,$14,$1E,$00,$00,
    include out/packs/pack270000-19.inc
    dc.b $80,$00,$10,$42,$20,$00,$80,$00,$0C
    dc.b $2C,$A0,$00,$80,$00,$14,$0E,$C0,$00
    include out/packs/pack270000-8.inc
    dc.w $FFFF
  
  * orig = 9E088
  newCredits8GrpPack:
*     dc.b $80,$00,$14,$20,$00,$00,
    include out/packs/pack270000-20.inc
    dc.b $80,$00,$14,$26,$20,$00
    include out/packs/pack270000-9.inc
    dc.w $FFFF
  
  * orig = 9E096
  newCredits9GrpPack:
*     dc.b $80,$00,$14,$22,$00,$00,
    include out/packs/pack270000-21.inc
    dc.b $80,$00,$14,$28,$20,$00,$80,$00,$10
    dc.b $3C,$40,$00,$80,$00,$0C,$12,$A0,$00
    include out/packs/pack270000-10.inc
    dc.w $FFFF
  
  credits10GrpPack:
    include out/packs/pack270000-11.inc
    dc.w $FFFF
  
*   credits11GrpPack:
*     include out/packs/pack270000-12.inc
*     dc.w $FFFF
  
  * new credits sequence data
  newCreditsSeq0:
    include out/credits/credits_seq_0.inc
  newCreditsSeq1:
    include out/credits/credits_seq_1.inc
  newCreditsSeq2a:
    include out/credits/credits_seq_2a.inc
  newCreditsSeq2b:
    include out/credits/credits_seq_2b.inc
  newCreditsSeq3a:
    include out/credits/credits_seq_3a.inc
  newCreditsSeq3b:
    include out/credits/credits_seq_3b.inc
  newCreditsSeq3c:
    include out/credits/credits_seq_3c.inc
  newCreditsSeq4a:
    include out/credits/credits_seq_4a.inc
  newCreditsSeq4b:
    include out/credits/credits_seq_4b.inc
  newCreditsSeq5a:
    include out/credits/credits_seq_5a.inc
  newCreditsSeq5b:
    include out/credits/credits_seq_5b.inc
  newCreditsSeq6:
    include out/credits/credits_seq_6.inc
  newCreditsSeq7a:
    include out/credits/credits_seq_7a.inc
  newCreditsSeq7b:
    include out/credits/credits_seq_7b.inc
  newCreditsSeq7c:
    include out/credits/credits_seq_7c.inc
*   newCreditsSeq7d:
*     include out/credits/credits_seq_7d.inc
  newCreditsSeq8:
    include out/credits/credits_seq_8.inc
  newCreditsSeq9a:
    include out/credits/credits_seq_9a.inc
  newCreditsSeq9b:
    include out/credits/credits_seq_9b.inc
  newCreditsSeq9c:
    include out/credits/credits_seq_9c.inc
  newCreditsSeq10:
    include out/credits/credits_seq_10.inc
  newCreditsSeq11:
    include out/credits/credits_seq_11.inc
  
  
