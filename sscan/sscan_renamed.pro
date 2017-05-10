function sscan, file=file, view=view, comment=comment,$
                scan=scan, append=append, overwrite=overwrite, $
                no_motors=no_motors, no_detectors=no_detectors, $
                save_xrf=save_xrf, med=med, $
                help=help, debug=debug, prefix=prefix
;
;  simple scan program using 1d epics scan record,
;  saving data as ASCII and doing a simple 1-detector plot
;
;

if (keyword_set(help) ne 0) then begin
    print, 'SScan: Execute scan set up in EPICS scan record'
    print, ' argument         meaning                  [default]'
    print, '  file       output file name              [scan.dat]'
    print, '  comment    title line to add to file     [] '
    print, '  view       detector to plot during scan  [2]' 
    print, '  scan       Epics scan PV to use          ["13IDC:scan1"]'
    print, '  /append    append to file if it exists   [yes]'
    print, '  /overwrite overwrite file if it exists   [no]'
    print, '  /nomotors  do not collect motor positions'
    print, '  /help      print this help message'
    print, '  '
    print, '  While scanning, hit  P to pause scan'
    return, 0
endif

; get postioner/detector names 
pos_names = ['UNUSED', 'UNUSED', 'UNUSED', 'UNUSED', 'UNUSED']
det_names = ['d0', 'd1', 'd2', 'd3', 'd4', 'd5', 'd6', 'd7', $
             'd8', 'd9',  'd10', 'd11', 'd12', 'd13', 'd14', 'd15','d16','d17']

det_to_plot   = 2
append_file   = 1
retval        = 0
scanning      = 1
debug_level   = 0
wait_time     = 0.05
max_check_count = 1000
current_point = 0
prev_point    = 0
get_motors    = 1
list_detectors  = 1
lun           = 0
write_xrf     = 0
pref          = '13IDC:'
outfile      = 'scan.dat'
out_comment  = ';Simple Scan: '

if (n_elements(file)    ne 0)  then  outfile = file
if (n_elements(debug) ne  0)   then  debug_level = debug
if (keyword_set(no_motors))    then  get_motors  = 0
if (keyword_set(no_detectors)) then  list_detectors  = 0
if (keyword_set(save_xrf))     then  write_xrf   = 1
; if (n_elements(med) ne 0)      then  med_obj     = med
if (keyword_set(append))       then  append_file = 1
if (keyword_set(overwrite))    then  append_file = 0
if (n_elements(comment) ne 0)  then  out_comment = out_comment + comment
if (n_elements(prefix)  ne 0)  then  pref = prefix

if (n_elements(view)    ne 0)  then  begin
   print, ' view =', view
   det_to_plot = view
endif

if (n_elements(scan)    ne 0)  then  scanPV = scan
; catch, error
; if (error ne 0) then begin
;     print, ' Simple Scan error ' , error, '  aborting scan!'
;     s = caput(scanPV+'.EXSC',0)
;     return, -1
; endif

scan_pause  = pref + 'scanPause.VAL'
scanPV      = pref + 'scan1'
scalerPV    = pref + 'scaler1'
motor_pv    = pref + 'm'

;
; gather scan parameters
s = caget(scanPV+'.NPTS', npts)
s = caget(scanPV+'.MPTS', mpts)
s = caget(scanPV+'.P1PA', p1pa)
s = caget(scanPV+'.P2PA', p2pa)
s = caget(scanPV+'.P3PA', p3pa)
s = caget(scanPV+'.P4PA', p4pa)

det = fltarr(70,mpts)

x = caget( scanPV   + '.P1PV', p)
x = caget( scanPV   + '.P1NV', v)
if ((x eq 0) and (v eq 0)) then pos_names[1] = p

x = caget( scanPV   + '.P2PV', p)
x = caget( scanPV   + '.P2NV', v)
if ((x eq 0) and (v eq 0)) then pos_names[2] = p

x = caget( scanPV   + '.P3PV', p)
x = caget( scanPV   + '.P3NV', v)
if ((x eq 0) and (v eq 0)) then pos_names[3] = p

x = caget( scanPV   + '.P4PV', p) 
x = caget( scanPV   + '.P4NV', v)
if ((x eq 0) and (v eq 0)) then pos_names[4] = p

s = caget(scanPV+'.P1SM', m)
if (m eq 0) then begin
    s = caget(scanPV+'.P1SP', p1sp)
    s = caget(scanPV+'.P1SI', p1si)
    for i = 0, npts-1 do    p1pa[i] = p1sp + p1si * i
endif else begin
    s = caget(scanPV+'.P1PA', p1pa)
endelse

s = caget(scanPV+'.P2NV', v)
s = caget(scanPV+'.P2SM', m)
if ((v eq 0) and (m eq 0)) then begin
    s = caget(scanPV+'.P2SP', p2sp)
    s = caget(scanPV+'.P2SI', p2si)
    for i = 0, npts-1 do  p2pa[i] = p2sp + p2si * i
endif else if ((v eq 0) and (m eq 1)) then begin
    s = caget(scanPV+'.P2PA', p2pa)
endif

s = caget(scanPV+'.P3NV', v)
s = caget(scanPV+'.P3SM', m)
if ((v eq 0) and (m eq 0)) then begin
    s = caget(scanPV+'.P3SP', p3sp)
    s = caget(scanPV+'.P3SI', p3si)
    for i = 0, npts-1 do p3pa[i] = p3sp + p3si * i
endif else if ((v eq 0) and (m eq 1)) then begin
    s = caget(scanPV+'.P3PA', p2pa)
endif

s = caget(scanPV+'.P4NV', v)
s = caget(scanPV+'.P4SM', m)
if ((v eq 0) and (m eq 0)) then begin
    s = caget(scanPV+'.P4SP', p4sp)
    s = caget(scanPV+'.P4SI', p4si)
    for i = 0, npts-1 do  p4pa[i] = p4sp + p4si * i
endif else if ((v eq 0) and (m eq 1)) then begin
    s = caget(scanPV+'.P4PA', p2pa)
endif

ddx = ['01', '01', '02', '03', '04', '05', '06', '07', '08', '09', $
       '10', '11', '12', '13', '14', '15']
; print, 'a', scanPV

for i = 1, 15 do begin
    PV = scanPV + '.D' + ddx[i] + 'PV'
    s = caget(PV, x)
    det_names[i] = x
endfor


nplots = n_elements(det_to_plot)
dx     = det_to_plot[0]
;
; open output file

es  = obj_new('EPICS_SCAN')
j   = es->set_param('datafile', outfile)
lun = es->open_scanfile(append=1)
j   = es->write_pv_list(lun=lun)


print, '  ==== type  P  to pause scan ===='
s = caput(scanPV+'.EXSC',1)


plotpv = strarr(10)
for ip = 0, nplots-1 do begin
    case  det_to_plot[ip] of 
        1:   plotpv[ip] = scanPV+'.D01CV'
        2:   plotpv[ip] = scanPV+'.D02CV'
        3:   plotpv[ip] = scanPV+'.D03CV'
        4:   plotpv[ip] = scanPV+'.D04CV'
        5:   plotpv[ip] = scanPV+'.D05CV'
        6:   plotpv[ip] = scanPV+'.D06CV'
        7:   plotpv[ip] = scanPV+'.D07CV'
        8:   plotpv[ip] = scanPV+'.D08CV'
        9:   plotpv[ip] = scanPV+'.D09CV'
        10:  plotpv[ip] = scanPV+'.D10CV'
        11:  plotpv[ip] = scanPV+'.D11CV'
        12:  plotpv[ip] = scanPV+'.D12CV'
        13:  plotpv[ip] = scanPV+'.D13CV'
        14:  plotpv[ip] = scanPV+'.D14CV'
        15:  plotpv[ip] = scanPV+'.D15CV'
    endcase
endfor

wait, wait_time
prev_point = -1
while(scanning) do begin
    cpt = -3
    j   = caget(scanPV+'.CPT', current_point)
    if (j eq 0) then cpt = current_point
   ; check for keyboard interrupt
    c = get_kbrd(0)
    c = strlowcase(c)
    x = caget(scan_pause, ex_pause)
  ;;  print, ' xx ' , j, current_point, ex_pause, c

    if ((c eq string(16B)) or (c eq 'p') or $
        (ex_pause eq 1)) then goto, interrupt
;;    print, 'xx OK ', cpt, prev_point
    resume:
    if (cpt gt prev_point) then begin
;------------
; hack to try to reset eps burps: this will push the 'reset' button
; at every point so that temporary (or bogus) eps faults that have
; latched,  don't  kill the whole scan.  Of course, the reset button
; doesn't do any good if  I can't open the shutter too!
;        j = caget('13IDA:eps_mbbi5',  eps_stat)
;        j = caget('13IDA:eps_mbbi81', vac_stat)
;        j = caput('13IDA:eps_bo2',    1)
;------------
;
; get latest data, and update plot
        prev_point = cpt
        s = caget(scanPV+'.NPTS', npts) 

;;        print, ' B ',  x, npts, nplots, cpt
        s = caget(plotpv[0],d_curr)

        ; print message
        ;; print, 'MMM; '
        print, format='(g11.3,$)', d_curr
        if ((cpt mod 10) eq 0) then print, format='(a,i4,a,i4,a)', $
        ' (point ', cpt, '/', npts, ')'
;        print, ' B ',  x, npts
        ; get plot ranges
;         plot_xmax  = p1pa(cpt) + (p1pa(cpt)-p1pa(cpt-1))
;         plot_ymax  = max(det(0,0:cpt-1),imax)
;         plot_ymin  = min(det(0,0:cpt-1),imin)
;         if (nplots gt 1) then begin
;             for ip = 1, nplots-1 do begin
;                 pl = max(det(ip,0:cpt-1),imax)
;                 if (pl gt plot_ymax) then plot_ymax = pl
;                 pl = min(det(ip,0:cpt-1),imin)
;                 if (pl lt plot_ymin) then plot_ymin = pl
;             endfor
;         endif
;        ; plot arrays
;        plot, p1pa(0:cpt-1), det(0,0:cpt-1), $
;          xrange = [p1pa(0), plot_xmax], $
;          yrange = [plot_ymin, plot_ymax], $
;          xstyle=19, charsize=1.4, $ 
;          xtitle = xtitle, ytitle=ytitle, title= plot_title, psym=-1
;        if (nplots gt 1) then begin
;            for ip = 1, nplots-1 do begin
;                psym = -(1 + ip)
;                oplot, p1pa(0:cpt-1), det(ip,0:cpt-1), psym=psym
;            endfor
;        endif
    endif
    ; check status after each point (for abort)
    keep_checking = 1
    check_count   = 0
;    print, ' check = ', keep_checking
    while (keep_checking) do begin
        s = caget(scanPV+'.EXSC',ss)
        if (s eq 0) then begin
            scanning = ss
            keep_checking = 0
        endif else begin
            check_count = check_count + 1
            if (check_count ge max_check_count) then goto, time_out
            wait, wait_time
        endelse
    endwhile
endwhile
wait, wait_time

if ((cpt mod 10) ne 0) then print, ' '

write_output:

; get results


j   = es->write_scan_data(short_labels=0)
j   = es->close_scanfile()


if (append_file) then begin
    print, '  appended file ', outfile
endif else begin
    print, '  wrote file ', outfile
endelse

close, lun
free_lun, lun
; 

busy = 1
while (busy ne 0) do begin
    x = caget(scanPV + '.FAZE', busy)
endwhile

print, ' returning ', retval
return, retval

;;-----------------------------------;;
;; handle interrupts of scan
time_out:
  print, ''
  print, 'scan timed-out... cannot get scanning status'
  print, 'aborting scan: not writing data file'
  s = caput(scanPV+'.EXSC',0)
  s = caput(scan_pause, 0)
  if (lun gt 0) then begin
      close, lun
      free_lun, lun
  endif
  return, -1

interrupt:
  print, ''
  print, ' ####################################'
  print, ' scan paused by user'
  print, ' type  r   to resume scan'
  print, ' type  a   to abort  scan'
  print, ' type  w   to write  scan so far and quit now'
  print, ' type  f   to finish this scan, but not start any more' 
  print, '           (for multiple or multi-dimensional scans)  '
  print, ' ####################################'
  s = caput(scan_pause, 1)
  
interrupt_2:
  c = get_kbrd(1)
  c = strlowcase(c)
  case c of
      'a': begin
          print, 'aborting scan: not writing data file'
          s = caput(scanPV+'.EXSC',0)
          s = caput(scan_pause, 0)
          if (lun gt 0) then begin
              close, lun
              free_lun, lun
          endif
          return, -1
      end
      'w': begin
          print, 'writing abbreviated scan ... '
          print, 'last few points may be garbage.'
          retval = -1
          npts   = cpt
          s      = caput(scanPV+'.EXSC',0)
          s      = caput(scan_pause, 0)
          goto, write_output
      end
      'r': begin
          print, 'resuming scan'
          s  = caput(scan_pause, 0)
          goto, resume
      end
      'f': begin
          print, 'finishing this scan only'
          retval = -1
          s = caput(scan_pause, 0)
          goto, resume
      end
      else: begin
          print, ' scan paused: type r for resume, a for abort, f to finish current scan only'
          goto, interrupt_2
      end
  endcase
;;-----------------------------------;;

end

