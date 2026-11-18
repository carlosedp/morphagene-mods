@ Module vs_deadband: wider Varispeed zones at 1x and -1x (mg204).
@ Linked after the previous module's code (mgmod/module.py).
@ Design: README.md beside this file.
@
@ Stock (vsop 0/1): x = calibrated Varispeed 0..1 (s18), m = trunc(400 x),
@ then the rate is T[(m & ~1) - 200] forward or -T[196 - (m & ~1)] reverse
@ (m & ~3 for vsop 1), with T[144] = 1.0. So 1x is m 344-345 and -1x is
@ m 52-53: 0.5% of the knob's travel each (1% with vsop 1). The Varispeed LED
@ is green only when the target is exactly +1.0 or -1.0.
@
@ This remaps x before anything reads it. Each 1x bucket is stretched to
@ ZONE (7%) of the knob, centred where the bucket was, and the three
@ stretches in between are squeezed (slope about 1.09-1.34), so every
@ stock rate is still reachable and 0 / 1 still map to 0 / 1. Knots are inset
@ 0.0005 (0.2 index) from the bucket edges, so float rounding never leaves
@ the bucket inside a zone. vsop 2 (forward-only table) is left stock.
@
@ Hook site 0x0802acde is the "x >= 0" exit of the calibration (only
@ 0x08027874 branches to it): vmov.f32 s17, #1.0, then the clamp to 1.0, then
@ b.w 0x0802787c. The x < 0 path stores 0, and the remap leaves 0 alone.
@ shift_gestures' P5 (0x0802787c) runs after this, so the scale lock snaps
@ the remapped x and its locked rate still overrides it.

    .syntax unified
    .cpu cortex-m4
    .fpu fpv4-sp-d16
    .thumb

    .equ VSOP,         0x200012a8       @ options.txt vsop (stock)
    .equ RATE_SELECT,  0x0802787c       @ stock: where the clamp path continues
    .equ SEGMENT,      12               @ bytes per table row: start, value, slope

    .text
    .global vs_zone

@ Replaces "vmov.f32 s17, #1.0" at 0x0802acde. s18 >= 0 here (or NaN, which
@ the clamp turns into 1.0). r0 (Gene Size) and r1 are restored; flags are
@ set again by the stock cmp at 0x0802787c.
    .thumb_func
vs_zone:
    vmov.f32 s17, #1.0                  @ replaced instruction
    vcmpe.f32 s18, s17                  @ the stock clamp (0x0802ace2-0x0802acec)
    vmrs    APSR_nzcv, fpscr
    it      hi
    vmovhi.f32 s18, s17
    push    {r0, r1}
    vpush   {s0-s1}
    ldr     r0, =VSOP
    ldr     r0, [r0]
    cmp     r0, #2
    bhs     9f
    ldr     r1, =knots_vsop0 + 4 * SEGMENT   @ last row; walk down
    cbz     r0, 1f
    adds    r1, r1, #5 * SEGMENT        @ vsop 1 table
1:  vldr    s0, [r1]                    @ row start; row 0 starts at 0.0, so
    vcmpe.f32 s18, s0                   @ the walk always ends
    vmrs    APSR_nzcv, fpscr
    bge     2f
    subs    r1, r1, #SEGMENT
    b       1b
2:  vsub.f32 s0, s18, s0                @ x' = value + (x - start) * slope
    vldr    s1, [r1, #8]
    vmul.f32 s0, s0, s1
    vldr    s1, [r1, #4]
    vadd.f32 s18, s1, s0
9:  vpop    {s0-s1}
    pop     {r0, r1}
    b.w     RATE_SELECT
    .ltorg

@ Rows: knob start, x' at start, slope. ZONE = 0.07 of the knob per zone,
@ inset 0.0005. Generated from: bucket a (52/400 and 344/400), width w
@ (2/400 for vsop 0, 4/400 for vsop 1), centre K = a + w/2, zone knob
@ [K - 0.035, K + 0.035] -> [a + 0.0005, a + w - 0.0005].
    .align 2
knots_vsop0:
    .float 0.0,        0.0,        1.33846152   @ knob 0-0.0975: reverse fast end
    .float 0.0975,     0.1305,     0.05714286   @ knob 0.0975-0.1675: -1x zone
    .float 0.1675,     0.1345,     1.1          @ knob 0.1675-0.8275: -1x .. stop .. 1x
    .float 0.8275,     0.8605,     0.05714286   @ knob 0.8275-0.8975: 1x zone
    .float 0.8975,     0.8645,     1.32195127   @ knob 0.8975-1: up to 2x
knots_vsop1:
    .float 0.0,        0.0,        1.30499995
    .float 0.1,        0.1305,     0.12857144
    .float 0.17,       0.1395,     1.09242427
    .float 0.83,       0.8605,     0.12857144
    .float 0.9,        0.8695,     1.30499995
