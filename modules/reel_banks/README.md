# reel_banks

**Status:** tried on hardware.

## What it does

Stock holds up to 32 reels on the card, `mg1.wav` to `mgw.wav` at the root.
This module adds **8 banks of 32 reels**:

| Bank | Where its reels live | Reel window colour |
|---|---|---|
| 1 | the card's root, exactly as stock | reel 1's colour |
| 2–8 | the folders `bank2` … `bank8` | reel 2's … reel 8's colour |

The colours are the ones the reel window already cycles through for reels
1–8. Bank *b* shows the colour of reel *b*.

**Choosing a bank:**
- **On the module:** hold SPLICE, then REC, as you would to enter reel mode.
  Reel mode opens as usual. Keep holding: after 3 s the reel window changes to
  the next bank's colour, then one bank further each second, wrapping from 8
  to 1. Let go on the bank you want, then pick a reel with Organize and load
  it with SPLICE + REC, as stock.
- **In `options.txt`:** `bank 1` to `bank 8`. Without the line, it's bank 1
  (the root), so a card without the setting behaves as stock. A bank chosen on
  the module is saved there straight away.

**After a switch:**
- The reel window shows the new bank's colour for 1.5 s. Then it shows the
  reel that Organize points at in the new bank, past the last reel is a new
  reel, as stock.
- The reel that was playing keeps playing until you load one. Its file stays
  open, so saving it still writes to the right file.
- **A missing folder is created** the first time its bank is chosen. An empty
  bank behaves like an empty card: the first reel you load or record is
  `mg1.wav` in that folder.
- **If the folder can't be created** (a write-protected card), the bank stays
  as it was.

Inside a bank, reels behave as stock: compaction, new reel, delete reel
(SHIFT + REC in reel mode), each in that bank's folder only.

## How

Every reel file name in stock comes from one function, `reel_name(out, n)`
at 0x08021f74, or from the literal `"mg1.wav"` at the boot check. (Two other
name builders in the image, `first_free` at 0x080221a8 and the compaction at
0x0802214c, are never called.) Prefixing those two places moves every reel
operation into the bank's folder. `options.txt` and the other files stay at
the root.

| Address | Meaning |
|---|---|
| 0x20001040 | Reel index: the loaded reel, or the one reel mode points at. 1000 = new reel |
| 0x200012a0 | Reel count. 0x2000128c holds the maximum, 32 |
| 0x20022074 | Main-loop requests. 0x1000 loads reel 0x20001040 (reel mode exit), 0x800 compacts and recounts, 0x80 rewrites `options.txt` |
| 0x20001020 | SHIFT/REC/SPLICE state. SPLICE held, then REC for 62.5 ms: reel mode (state 8 → 16); 0.25 s later, state 17 waits for every button to be released; state 18 is reel mode |
| 0x20001024 | The state machine's time stamp. In state 17, the time REC joined SPLICE |
| 0x20021c88 | Time, 96,000 ticks a second: the audio loop adds 2 per 48 kHz frame (0x0802a284). TIM2 keeps it in lr |
| 0x20001038 | Reel window colour code: reel index & 7, so the colours repeat every 8 reels |
| 0x0802214c | Stock compaction, never called by stock: renames `mgN.wav` files to fill gaps, then sets the reel count |
| 0x080334d4 | FatFs `f_mkdir`, linked but never called by stock |

**N1 (0x08021f74)** replaces `reel_name`. It writes the same 32 bytes as
stock, with `bankN/` in front for banks 2–8. Without the settings magic, or
with a bank byte out of range, it gives the root names, byte for byte as
stock.

**B1 (0x080236d2, boot):** stock compacts the root's reels, reads
`options.txt`, then checks for `mg1.wav`. B1 runs between the last two. For
banks 2–8 it checks the folder (`f_stat`), creates it if missing (`f_mkdir`),
and recounts that folder's reels with the stock compaction. If there's no
folder and none can be made, it goes back to bank 1. Then it runs the
`mg1.wav` check on the bank's name.

**H1 (0x08025266, TIM2 state 17)** times the hold. With REC and SPLICE down
and SHIFT up, from 3 s after REC went down, the pending bank is the current
one plus 1, plus one more each further second. Releasing either button (or
pressing SHIFT) hands the pending bank to the main loop. That hold is then
used up: pressing both again before releasing everything does nothing.

**L1 (0x080249c6, TIM2)** runs after stock has chosen the reel window's colour.
It shows the pending bank, or for 1.5 s after release the active bank.

**M1 (0x08022fbc, main loop, card mounted)** applies the switch, never while
recording. It checks or creates the folder, sets the bank, and recounts. It
points the selection at reel 1 (new reel if the bank is empty), then lets
Organize pick again by clearing the reading the selection last used. Last, it
asks for an `options.txt` rewrite so the bank is saved.

**Setting:** `bank` (options_keys) is a byte at 0x2002A607, 1–8. sd_updater
sets it to 1 every boot, before `options.txt` is read. State: 0x2002A610 (magic,
hold stamp, show time, pending and requested bank) and a 32-byte name buffer
at 0x2002A620.

**Cost:** H1 runs only in state 17. L1 adds about 10 instructions per TIM2
tick. M1 adds about 12 per main-loop pass.

## Hooks

| Hook | Site | Context | Does |
|---|---|---|---|
| N1 | 0x08021f74 | any | Reel file names in the bank's folder |
| B1 | 0x080236d2 | boot | Folder, recount, then the `mg1.wav` check |
| H1 | 0x08025266 | TIM2, state 17 | SPLICE + REC held 3 s: pending bank |
| L1 | 0x080249c6 | TIM2 | Reel window shows the bank |
| M1 | 0x08022fbc | main loop | Switch banks |

## Verification (emulator)

Unicorn on the built `full` image, against the stock image, with FatFs and the
compaction stubbed:

- **N1:** for reels 1–32, with no settings magic and with bank bytes 1, 0, 9
  and 200, all 40 bytes around the buffer are identical to stock. Banks 2–8
  give `bankN/mgC.wav` in 32 zeroed bytes. r4–r7 and sp come back unchanged.
- **B1:** bank 1 and no settings make no calls and check `mg1.wav`. Bank 3
  with its folder: `f_stat("bank3")`, compaction, `bank3/mg1.wav`. Without the
  folder: `f_mkdir("bank3")`, also when it answers "exists". If `f_mkdir`
  fails: bank 1, `mg1.wav`, no compaction. The flags, r0, r2, r3, r7, r9 and
  callee-saved registers match what the stock code hands on.
- **H1:**
  - nothing under 3 s;
  - bank 2 at 3 s and bank 3 at 4 s, from bank 1;
  - bank 8 at 9 s, wrapping to bank 1 at 10 s;
  - from bank 7, bank 1 at 4 s;
  - releasing REC or SPLICE, or pressing SHIFT, makes the request;
  - the same hold can't switch twice;
  - REC alone does nothing;
  - time wrapping around 2³² is handled;
  - it returns to the stock wait or release path as stock does, with every
    register but r2 unchanged.
- **L1:** pending banks 1, 6 and 8 show colour codes 1, 6 and 0 (reel 8's).
  The active bank shows for exactly 1.5 s after release. Without the magic the
  colour stays stock. r2, r7 and the flags match stock.
- **M1:**
  - switch to bank 4: compaction, then selection 1, Organize re-read,
    `options.txt` rewrite;
  - empty bank: new reel (1000);
  - back to the root: no folder check;
  - same bank, recording, no card, or a bad request: nothing;
  - folder created, or impossible (bank unchanged);
  - registers unchanged.
- **options_keys:** `bank 1`–`bank 8` parse, `bank 0`, `bank 9` and `bank x`
  are ignored, and the writer prints `bank` last, defaulting to 1.

**Hardware:** the first build stepped banks about twice a second, because the
time counter runs at 96,000 ticks a second, not 48,000 (the audio loop adds 2
per frame). With the constants doubled, it works on the module: 3 s to the
first step, then one bank a second, and banks switch as described.
