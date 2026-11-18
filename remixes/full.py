# Every module. Each feature is switched in options.txt (tape, octl, scal, fxsl,
# mcap, sldm, cpul, ingn, mono), so one image covers every combination.
REMIX = dict(
    title='Full',
    description='Every module: Varispeed scale lock, wider 1x zones on Varispeed, tape / TLA feedback, SRR, warble, Slide jitter, '
                'Turing mode, mono input, SD-card updates, options.txt settings, always-on flash prefetch and a troubleshooting CPU log.',
    modules=['record_start_splice', 'shift_gestures', 'tape_sos', 'sd_updater', 'options_keys', 'gene_shape',
             'cpu_meter', 'mono_in', 'vs_deadband'],
    sha256='18851c6b565e480cac66cf77b37d7973097c207db9509d7f20c3ebab1d95a056',
)
