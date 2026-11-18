from mgmod.module import Module

MODULE = Module(
    name='vs_deadband',
    title='Wider Varispeed zones at original speed, forward and reverse (green LED)',
    status='on hardware',
    source='vs_deadband.S', entry='vs_zone',
    hooks=[
        (0x0802acde, 'f7ee008a', 'vs_zone'),         # audio: calibrated Varispeed x >= 0, before the clamp
    ],
)
