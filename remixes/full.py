# Every module. Each feature is switched in options.txt (tape, octl, scal, fxsl,
# mcap, sldm, cpul, ingn, mono, thru), so one image covers every combination.
REMIX = dict(
    title='Full',
    description='Every module: Varispeed scale lock, wider 1x zones on Varispeed, tape / TLA feedback, SRR, warble, Slide jitter, '
                'Turing mode, mono input, play-through on Organize, SD-card updates, options.txt settings, always-on flash prefetch and a troubleshooting CPU log.',
    modules=['record_start_splice', 'shift_gestures', 'tape_sos', 'sd_updater', 'options_keys', 'gene_shape',
             'cpu_meter', 'mono_in', 'vs_deadband', 'splice_thru'],
    sha256='a36512c1840d7ea546cd7eaa793411f70913db8a1ce580ad362349d60a102099',
)
