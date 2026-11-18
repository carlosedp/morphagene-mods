# Full, plus Morph fully down playing a seamless loop (a table edit, so it has no
# options.txt switch; use Full for stock Morph).
REMIX = dict(
    title='Full + Morph loop',
    description='Everything in Full, and Morph fully down plays a seamless loop instead of adding silence '
                '(stock reaches the loop at about 8 o\'clock).',
    modules=['record_start_splice', 'shift_gestures', 'tape_sos', 'sd_updater', 'options_keys', 'gene_shape',
             'cpu_meter', 'mono_in', 'vs_deadband', 'morph_loop'],
    sha256='79a057d3c09b9b3e817ce1a9b65cdc180cad3a96cee3ff240a1e53d61896a44b',
)
