# splice_thru

**Status:** on hardware. It played reels through, splice after splice, on a module.

## What it does

In stock, Organize picks one splice and the Gene loops inside it. To move on
at the end of each splice, you'd tap SHIFT, or patch the EOSG output into the
SHIFT input.

With `thru 1` (the default), the **top 5% of Organize** (fully clockwise)
does that patch for you. At every end of splice, the module asks for the next
splice, exactly as a SHIFT tap does. After the last splice it wraps to the
first, so the whole reel plays through.

- **Turning into the zone** carries on from the splice that's playing.
- **A reel that loads with Organize already in the zone** starts from splice 1.
- **Below the zone,** Organize is stretched slightly, so every splice is still
  reachable, the last one included.
- **It does nothing in reel mode, while recording, or with fewer than 2
  splices.**
- **`thru 0`:** Organize is exactly stock.

The event is the one that drives the EOSG output, so it behaves like the EOSG
patch. With Gene Size turned up, that includes the end of each Gene.

## How

Stock pieces (mg204):

| Address | Meaning |
|---|---|
| 0x20021cbc | Selected splice, 1..count. Organize sets it only when its reading moves more than 8 counts. A SHIFT tap (navigation request 0x200012e0 = 1) adds 1 and wraps to 1 after the last |
| 0x2002208c | Splice count |
| 0x20021338 | Reel mode |
| 0x20021de8 | End-of-splice trigger. The audio code sets it to 4; TIM2 counts it down to 2 while it drives the EOSG gate |
| 0x200220ac, 0x20022080, 0x200220a0 | The Organize reading the selection last used, its calibration minimum, and the scale: position = (reading − minimum) × scale |

**O1 (audio block, 0x080277b0–0x080277d1)** replaces the Organize → splice
mapping, which stock reaches only when Organize moved. It recomputes it with
the same registers. With `thru 1`:
- below 0.95, the position is multiplied by 1/0.95;
- at 0.95 and above, a valid selection is kept, or 1 if there is none.

With `thru 0`, it's identical to stock.

**E1 (TIM2, 0x08024d2a)** re-runs the trigger load. On the first tick that
sees a fresh trigger (4), it sets the navigation request to 1 when all of
these hold:
- `thru` is on;
- the module isn't in reel mode or recording;
- there are 2 or more splices;
- the Organize position the selection last used is 0.95 or more.

It reads that last-used position, not the raw knob, so `gene_shape`'s Organize
hold (SHIFT + Organize in Turing mode) also holds the zone.

**Setting:** `thru` (options_keys) is a byte at 0x2002A606. sd_updater sets it
to 1 every boot, before `options.txt` is read. Without the settings magic, both
hooks treat it as 1.

**Cost:** O1 runs only when Organize moves. E1 adds 3 instructions per TIM2
tick, and about 40 once per end of splice.

## Hooks

| Hook | Site | Rate | Does |
|---|---|---|---|
| O1 | 0x080277b0 | block, when Organize moves | Stretched mapping below the zone; keeps the selection in it |
| E1 | 0x08024d2a | TIM2 | End of splice in the zone → next splice |

## Verification (emulator)

Unicorn on the built `full` image, against the stock image:

- **O1, `thru 0`:** for splice counts 1, 2, 3, 5, 8, 13, 32 and 99, at 2,001
  positions each, with selection 0, 1 and the last, the selection and every
  register the stock code writes (r0, r3, s0, s13, s14, s15, s30, s31) are
  bit-identical to stock.
- **O1, `thru 1`:**
  - below the zone, every splice is reached in order, and the last one just
    below 0.95;
  - in the zone, the selection is kept, or set to 1 when invalid;
  - r1, r4, lr, sp and s21 come back unchanged;
  - without the settings magic it acts as `thru 1`.
- **E1:** it asks for the next splice only for a fresh trigger (4, not 3, 2
  or 0) with `thru` on (or no settings), outside reel mode and recording, with
  2 or more splices, and at the 0.95 boundary (3840 on, 3839 off with min 40
  and range 4000). The trigger value and r1, r2, r3, r9, lr, sp, s0 and s1 are
  unchanged.
- **options_keys:** `thru 0` and `thru 1` parse, `thru 2` and `thru x` are
  ignored, and the writer prints `thru` after `mono`, including the default.

**Hardware:** it works as intended. With Organize fully clockwise, the reel
played through, splice after splice.
