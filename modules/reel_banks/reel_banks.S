@ Module reel_banks: 8 banks of 32 reels, one folder per bank (mg204).
@ Linked after the previous module's code (mgmod/module.py).
@ Design: README.md beside this file. Requires options_keys (bank) and
@ sd_updater (its boot default).
@
@ Bank 1 is the card's root, exactly as stock. Banks 2-8 are the folders
@ bank2 .. bank8, each holding its own mg1.wav .. mgw.wav. Every reel file
@ name in stock comes from reel_name (0x08021f74) or from the literal
@ "mg1.wav" at the boot check (0x080236d4), so prefixing those two moves
@ every reel operation (load, new reel, delete, compaction) into the bank.
@
@ Hooks:
@   N1  0x08021f74  reel_name(out, n): replaced, writes [bankN/]mgC.wav
@   B1  0x080236d2  boot, after options.txt: check the bank's folder (create
@                   it if missing; root if that fails), recount its reels,
@                   then the stock mg1.wav check, in the bank
@   H1  0x08025266  TIM2 state 17 (reel mode just entered with SPLICE + REC,
@                   waiting for release): time the hold. From 3 s on, the
@                   pending bank is the next one, plus one more each second;
@                   releasing either button asks the main loop to switch
@   L1  0x080249c6  TIM2 LED: reel window shows the bank (reel colours,
@                   bank b = reel b's colour) while pending and 1.5 s after
@   M1  0x08022fbc  main loop, card mounted: apply a requested switch
@
@ Stock pieces:
@   0x20001024  SHIFT/REC/SPLICE state machine time stamp (REC press here)
@   0x20021c88  time, 96,000 ticks a second: the audio loop adds 2 per
@               48 kHz frame (TIM2 holds it in lr)
@   0x20001040  reel index (1000 = new reel), 0x200012a0 reel count
@   0x0802214c  stock compaction (unused by stock): renames mgN.wav files to
@               fill gaps and sets the reel count
@   0x200220ac  Organize reading the selection last used (reel mode picks a
@               reel only when Organize moves more than 8 counts from it)
@   0x20001038  reel window colour code (reel index & 7; 8, 9 special)

    .syntax unified
    .cpu cortex-m4
    .thumb

    .equ SETTINGS,       0x2002A0F0
    .equ SETTINGS_MAGIC, 0x5354504f
    .equ BANK,           0x2002A607     @ options.txt bank (options_keys), u8 1-8
    .equ RB,             0x2002A610     @ state block, see below
    .equ RB_MAGIC,       0x4b4e4142     @ "BANK"
    .equ PATH,           0x2002A620     @ 32-byte name buffer (RB + 16)
    @ RB: +0 magic, +4 stamp (the hold already used), +8 show-until time,
    @     +12 pending bank (0 none), +13 requested bank (0 none)

    .equ HOLD_T0,        0x20001024
    .equ NOW,            0x20021c88
    .equ REEL_INDEX,     0x20001040
    .equ REEL_COUNT,     0x200012a0
    .equ ORG_USED,       0x200220ac
    .equ REEL_COLOR,     0x20001038
    .equ REC_ACTIVE,     0x20022108
    .equ FLAGS,          0x20022074     @ main-loop requests; 0x80 = rewrite options.txt
    .equ F_STAT,         0x08033129
    .equ F_MKDIR,        0x080334d5
    .equ COMPACT,        0x0802214d

    .equ HOLD_TICKS,     288000         @ 3 s
    .equ STEP_TICKS,     96000          @ 1 s per further bank
    .equ SHOW_TICKS,     144000         @ bank shown 1.5 s after release

    .equ BOOT_RETURN,    0x080236da
    .equ HOLD_WAIT,      0x080248fc     @ TIM2 done (buttons still down)
    .equ HOLD_RELEASED,  0x0802526e
    .equ LED_RETURN,     0x080249cc
    .equ MAIN_ON,        0x08022fc2
    .equ MAIN_OFF,       0x08022f96

    .text
    .global rb_name, rb_boot, rb_hold, rb_led, rb_main

@ r0 = active bank 1-8: 1 without the settings magic or out of range. r0, r1.
    .thumb_func
bank_get:
    ldr     r1, =SETTINGS
    ldr     r0, [r1]
    ldr     r1, =SETTINGS_MAGIC
    cmp     r0, r1
    bne     1f
    ldr     r1, =BANK
    ldrb    r0, [r1]
    subs    r1, r0, #1
    cmp     r1, #7
    bhi     1f
    bx      lr
1:  movs    r0, #1
    bx      lr

@ Write "bankN" at r0 (r1 = 2-8). Returns r0 past it. r0-r3.
    .thumb_func
put_dir:
    ldr     r2, =s_bank
1:  ldrb    r3, [r2], #1
    cbz     r3, 2f
    strb    r3, [r0], #1
    b       1b
2:  adds    r1, r1, #'0'
    strb    r1, [r0], #1
    strb    r3, [r0]                    @ r3 = 0
    bx      lr

@ N1: replaces reel_name(out, n) at 0x08021f74 (AAPCS, called with bl).
@ Stock: 32 zero bytes, then "mg", '0'+n (n <= 9) or 'a'+n-10, ".wav".
    .thumb_func
rb_name:
    push    {r4, r5, lr}
    mov     r4, r0
    mov     r5, r1
    movs    r2, #0
    movs    r3, #0
1:  str     r2, [r4, r3]
    adds    r3, r3, #4
    cmp     r3, #32
    blo     1b
    bl      bank_get
    mov     r1, r0
    mov     r0, r4
    cmp     r1, #1
    beq     2f
    bl      put_dir
    movs    r3, #'/'
    strb    r3, [r0], #1
2:  movs    r3, #'m'
    strb    r3, [r0], #1
    movs    r3, #'g'
    strb    r3, [r0], #1
    cmp     r5, #9
    ite     le
    addle   r3, r5, #'0'
    addgt   r3, r5, #('a' - 10)
    strb    r3, [r0], #1
    ldr     r2, =s_wav
3:  ldrb    r3, [r2], #1
    strb    r3, [r0], #1
    cmp     r3, #0
    bne     3b
    pop     {r4, r5, pc}

@ r0 = 0 when bank r0 can be used: root, or its folder exists or was just
@ created. Otherwise the FatFs error. AAPCS.
    .thumb_func
rb_folder:
    push    {r4, lr}
    cmp     r0, #1
    beq     8f
    mov     r1, r0
    ldr     r0, =PATH
    bl      put_dir
    ldr     r0, =PATH
    movs    r1, #0
    ldr     r3, =F_STAT
    blx     r3
    cbz     r0, 9f
    ldr     r0, =PATH
    ldr     r3, =F_MKDIR
    blx     r3
    cmp     r0, #8                      @ FR_EXIST
    bne     9f
8:  movs    r0, #0
9:  pop     {r4, pc}

@ B1: boot, after options.txt is parsed and closed, replacing
@ "ldr r2,[r7]; ldr r0,=mg1.wav; orr r3,r2,#0x80" at 0x080236d2.
@ Live: r7 = &FLAGS, sb = 0 (f_stat's second argument). r0-r3, ip, lr free.
    .thumb_func
rb_boot:
    bl      bank_get
    cmp     r0, #1
    beq     2f
    bl      rb_folder
    cbz     r0, 1f
    ldr     r1, =BANK                   @ no folder: play from the root
    movs    r0, #1
    strb    r0, [r1]
    b       2f
1:  ldr     r3, =COMPACT                @ stock counted the root's reels
    blx     r3
2:  ldr     r0, =PATH
    movs    r1, #1
    bl      rb_name
    ldr     r2, [r7]
    ldr     r0, =PATH
    orr     r3, r2, #0x80
    b.w     BOOT_RETURN

@ H1: TIM2 state 17, replacing "ldr r2,[sp,#4]; cmp r2,#0; bne.w done" at
@ 0x08025266. Live: r2 = REC, r3 = SPLICE, ip = SHIFT (non-zero = held),
@ lr = now, sb = &state, [sp, #4] = buttons down. Keeps everything but r2.
    .thumb_func
rb_hold:
    push    {r0, r1, r4, lr}
    ldr     r4, =RB
    ldr     r0, [r4]
    ldr     r1, =RB_MAGIC
    cmp     r0, r1
    beq     1f
    str     r1, [r4]
    movs    r0, #0
    str     r0, [r4, #4]
    str     r0, [r4, #8]
    str     r0, [r4, #12]
1:  ldr     r1, =HOLD_T0
    ldr     r1, [r1]
    cmp     r2, #0
    beq     5f
    cmp     r3, #0
    beq     5f
    cmp     ip, #0
    bne     5f
    ldr     r0, [r4, #4]                @ this hold already switched
    cmp     r0, r1
    beq     9f
    subs    r0, lr, r1
    ldr     r1, =HOLD_TICKS
    subs    r0, r0, r1
    bmi     9f
    ldr     r1, =STEP_TICKS
    udiv    r0, r0, r1
    push    {r0}
    bl      bank_get
    pop     {r1}
    add     r0, r0, r1                  @ bank + steps - 1 + 1, wrapped to 1-8
    and     r0, r0, #7
    adds    r0, r0, #1
    strb    r0, [r4, #12]
    b       9f
5:  ldrb    r0, [r4, #12]               @ a button released
    cbz     r0, 9f
    strb    r0, [r4, #13]
    movs    r0, #0
    strb    r0, [r4, #12]
    str     r1, [r4, #4]
    ldr     r0, =SHOW_TICKS
    add     r0, r0, lr
    str     r0, [r4, #8]
9:  pop     {r0, r1, r4, lr}
    ldr     r2, [sp, #4]
    cmp     r2, #0
    bne     8f
    b.w     HOLD_RELEASED
8:  b.w     HOLD_WAIT

@ L1: TIM2, replacing "ldr r2,=0x20001058; ldr r7,[r2]; cmp r7,#1" at
@ 0x080249c6, after the reel window colour is chosen. Keeps all but r2, r7.
    .thumb_func
rb_led:
    push    {r1, r3}
    ldr     r2, =RB
    ldr     r7, [r2]
    ldr     r3, =RB_MAGIC
    cmp     r7, r3
    bne     9f
    ldrb    r7, [r2, #12]               @ pending
    cbnz    r7, 5f
    ldr     r1, =NOW
    ldr     r1, [r1]
    ldr     r3, [r2, #8]
    subs    r3, r3, r1                  @ show time left
    ble     9f
    ldr     r1, =SHOW_TICKS
    cmp     r3, r1
    bhi     9f
    push    {r0, lr}
    bl      bank_get
    mov     r7, r0
    pop     {r0, lr}
5:  and     r7, r7, #7
    ldr     r2, =REEL_COLOR
    str     r7, [r2]
9:  pop     {r1, r3}
    ldr     r2, =0x20001058
    ldr     r7, [r2]
    cmp     r7, #1
    b.w     LED_RETURN

@ M1: main loop, replacing "cmp r6,#1; ldr r5,[r7]; bne.w loop" at
@ 0x08022fbc. Live: r6 = card state (1 = mounted), r7 = &FLAGS.
    .thumb_func
rb_main:
    push    {r0-r4, ip, lr}
    sub     sp, sp, #4
    cmp     r6, #1
    bne     8f
    ldr     r0, =RB
    ldr     r1, [r0]
    ldr     r2, =RB_MAGIC
    cmp     r1, r2
    bne     8f
    ldrb    r1, [r0, #13]
    cbz     r1, 8f
    movs    r2, #0
    strb    r2, [r0, #13]
    mov     r0, r1
    bl      rb_apply
8:  add     sp, sp, #4
    pop     {r0-r4, ip, lr}
    ldr     r5, [r7]
    cmp     r6, #1
    bne     9f
    b.w     MAIN_ON
9:  b.w     MAIN_OFF

@ Switch to bank r0 (main loop context). AAPCS.
    .thumb_func
rb_apply:
    push    {r4, lr}
    mov     r4, r0
    subs    r0, r4, #1
    cmp     r0, #7
    bhi     9f
    ldr     r0, =REC_ACTIVE
    ldr     r0, [r0]
    cbnz    r0, 9f
    bl      bank_get
    cmp     r0, r4
    beq     9f
    mov     r0, r4
    bl      rb_folder
    cbnz    r0, 9f
    ldr     r1, =BANK
    strb    r4, [r1]
    ldr     r3, =COMPACT                @ this bank's reels: compact and count
    blx     r3
    ldr     r1, =REEL_COUNT             @ selection: reel 1, or a new reel
    ldr     r1, [r1]
    mov     r0, #1000
    cmp     r1, #0
    it      ne
    movne   r0, #1
    ldr     r2, =REEL_INDEX
    str     r0, [r2]
    ldr     r1, =ORG_USED               @ and let Organize pick again
    ldr     r0, =-100000
    str     r0, [r1]
    mrs     r2, primask                 @ save bank in options.txt (TIM2 also
    cpsid   i                           @ sets bits in FLAGS)
    ldr     r1, =FLAGS
    ldr     r0, [r1]
    orr     r0, r0, #0x80
    str     r0, [r1]
    msr     primask, r2
9:  pop     {r4, pc}
    .ltorg

    .align 2
s_bank: .asciz "bank"
    .align 2
s_wav:  .asciz ".wav"
