from mgmod.module import Module

MODULE = Module(
    name='reel_banks',
    title='8 banks of 32 reels: root plus folders bank2-bank8 (bank; SPLICE + REC held 3 s)',
    status='emulated',
    source='reel_banks.S', entry='rb_name',
    requires=['sd_updater', 'options_keys'],
    hooks=[
        (0x08021f74, 'f0b48ab0', 'rb_name'),                   # reel_name(out, n): bank folder prefix
        (0x080236d2, '3a68594842f08003', 'rb_boot'),           # boot, after options.txt: folder, recount, mg1 check
        (0x08025266, '019a002a7ff447ab', 'rb_hold'),           # TIM2 state 17: SPLICE + REC held 3 s
        (0x080249c6, '2b4a1768012f', 'rb_led'),                # TIM2: reel window shows the bank
        (0x08022fbc, '012e3d68e9d1', 'rb_main'),               # main loop, card mounted: switch banks
    ],
    ram=[(0x2002A610, 0x2002A63F)],                            # state, name buffer
    gestures=['SPLICE+REC hold'],
)
