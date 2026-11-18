# Full, plus Morph fully down playing a seamless loop (a table edit, so it has no
# options.txt switch; use Full for stock Morph).
REMIX = dict(
    title='Full + Morph loop',
    description='Everything in Full, and Morph fully down plays a seamless loop instead of adding silence '
                '(stock reaches the loop at about 8 o\'clock).',
    modules=['record_start_splice', 'shift_gestures', 'tape_sos', 'sd_updater', 'options_keys', 'gene_shape',
             'cpu_meter', 'mono_in', 'vs_deadband', 'splice_thru', 'morph_loop'],
    sha256='df8e9d309e96cc8d14283476c4f29ce78f07bb80551afe8ffa5bd7cbbf096e64',
)
