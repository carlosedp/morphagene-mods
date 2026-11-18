# Every module. Each feature is switched in options.txt (tape, octl, scal, fxsl,
# mcap, sldm, cpul, ingn, mono, thru, bank), so one image covers every combination.
REMIX = dict(
    title='Full',
    description='Every module: Varispeed scale lock, wider 1x zones on Varispeed, tape / TLA feedback, SRR, warble, Slide jitter, '
                'Turing mode, mono input, play-through on Organize, 8 reel banks, SD-card updates, options.txt settings, always-on flash prefetch and a troubleshooting CPU log.',
    modules=['record_start_splice', 'shift_gestures', 'tape_sos', 'sd_updater', 'options_keys', 'gene_shape',
             'cpu_meter', 'mono_in', 'vs_deadband', 'splice_thru', 'reel_banks'],
    sha256='6644dd2e5b22637fe591bf42e3b93abff1d7ee6af3fb08faee1d0939bd7089bb',
)
