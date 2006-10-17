pro make_mda_display_sav
   ; This IDL procedure makes mda_display.sav, to run under IDL Virtual Machine
   filenames = ['mda_display']
   classnames = ['epics_sscan', 'epics_sscan_display']
   resolve_routine, filenames, /either, /compile_full_file, /no_recompile
   resolve_all, class=classnames
   itresolve
   save, /routine, file='mda_display.sav'
end

