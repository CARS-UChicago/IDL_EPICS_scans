pro xrf_scan, file=file, view=view, comment = comment,  help=help

;
; simple emulation of 1D EPICS scan, reading values set from 
; scan record, and then performing 1d 'sscan' repeatedly.
;
;  -- assumes  scan1 is setup in scan record properly

if (keyword_set(help) ne 0) then begin
    print, 'Sscan 1d: Execute EPICS sscan'
    print, ' argument         meaning                  [default]'
    print, '  file       output file name              [scan.dat]'
    print, '  comment    title line to add to file     [] '
    print, '  view       detector to plot during scan  [2]' 
    print, '  /help      print this help message'
    print, '  '
    print, '  While scanning, hit  P to pause scan'
    return
endif

m = obj_new('EPICS_MED', '13IDC:med:')
out_file = 'sscan.dat'
if (n_elements(file) eq 0)  then  file = ''
if (file ne '')  then  out_file = file

title = ' '
if (n_elements(comment) ne 0)  then  title = comment + title

status = sscan(file= out_file, view=view, /save_xrf, med=m, $
                     comment= comment, /overwrite)
if (status ne 0) then begin
    print, 'sscan_1d saw interrupt from sscan'
    return
endif

print, ' sscan_1d is done.'
return
end


