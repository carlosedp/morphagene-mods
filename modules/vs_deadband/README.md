# vs_deadband

**Status:** on hardware. Measured with a diagnostic log at 5% per zone; now 7%, which is emulated only.

## What it does

The Varispeed LED is green only when the rate is exactly 1× or −1×. In stock,
each of those rates covers one small step of the knob: 0.5% of its travel
(about 1.5° of rotation) with `vsop 0`, or 1% with `vsop 1`. That makes it hard
to find original speed by hand.

This module makes both zones **7.1% of the travel** (about 20°), about fourteen
times wider with `vsop 0`, centred where they were. The rest of the knob is
squeezed by 9–34% to make room, mostly between 1× and 2× and between −1× and −2×:
- every stock rate can still be reached;
- the knob ends are still −2× and 2×;
- stop and the other rates are where they were, give or take a few counts.

It is always on, with no `options.txt` switch. `vsop 2` (forward-only) is left
stock.

## How

Stock turns the calibrated knob position *x* (0..1) into an index
*m* = trunc(400 *x*) and reads the rate table at an even index (`vsop 0`) or a
multiple of 4 (`vsop 1`). 1× is *m* 344–345 and −1× is *m* 52–53 (344–347 and
52–55 with `vsop 1`).

The hook remaps *x* before anything reads it. The remap is piecewise linear and
stretches each 1× bucket over 0.07 of the knob. Knots are inset 0.0005 from the
bucket edges, so float rounding can't leave the bucket inside a zone. The
tables are written for `vsop` 0 and 1; to change the width, recompute the
knots with the formula in the source.

shift_gestures' scale lock (P5, 0x0802787c) runs after the remap, so a held
SHIFT + Varispeed snaps the remapped position, and a locked rate still
overrides it. Its pickup compares the raw knob reading, so release is
unchanged.

## Hook

| Site | Original | Rate | Does |
|---|---|---|---|
| 0x0802acde | `vmov.f32 s17, #1.0` | block | Re-runs the stock clamp, remaps *x*, continues at 0x0802787c |

0x0802acde is the "*x* ≥ 0" exit of the Varispeed calibration. Only
0x08027874 branches there. The *x* < 0 path stores 0, which the remap
leaves unchanged anyway.

**Cost:** about 30 instructions per audio block, with no per-sample code.

## Verification (emulator)

Unicorn runs the built `full` image from the hook site through the stock
rate selection to the target store (0x200220e8). A knob sweep of 40,951
positions (10 per ADC count) was compared with the stock image:

| `vsop` | 1× zone, stock → mod | −1× zone, stock → mod | Rates reachable | Monotonic |
|---|---|---|---|---|
| 0 | 0.50% → 7.08% | 0.50% → 7.08% | 193 of 193 | yes |
| 1 | 1.00% → 7.08% | 1.00% → 7.08% | 97 of 97 | yes |
| 2 | 0.31% (unchanged) | n/a | 290 (unchanged) | yes |

r0, sp and every register it uses come back unchanged. The LED test
(0x08024b02) compares the target with exactly ±1.0, so the green zone is the
same width.

**Hardware:**
- At 2.1%, it was easier to tune but still tight.
- At 5%, a diagnostic build logged the raw reading and the target once per
  second. The calibrated range was 62–4095 (4,033 counts) and knob noise was
  ±1–2 counts. 1× was green up to about 3645 and −1× up to 698, close to the
  expected 3440–3641 and 496–697. Both zones were about 200 counts wide, as
  designed.
- The 7% version hasn't been tried yet. Expected with that calibration: 1× at
  about 3399–3682, −1× at about 455–738.

**Trade-off.** At 7%, the octave from 1× to 2× takes about 10% of the
travel (13.75% in stock), and semitones near 2× are about 30 counts apart (39
in stock).
