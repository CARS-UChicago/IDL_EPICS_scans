pro scan_3d, scan_file=scan_file, prefix=prefix, zvals=zvals, zpv=zpv
;
;  execute a defined 3d scan as a series of 2d scans 
;  (defined in supplied scanfile) at each element of
;   the array zvals for positioner zpv
;
;  args:
;      scan_file   name of epics_scan parameter file for 2d scan
;      
; 
;
z_vals    = [11850, 11865,11870,11920]
if (keyword_set(zvals) ne 0 ) then z_vals = zvals

z_pv    = '13IDA:E:Energy'
if (keyword_set(zpos) ne 0 ) then z_pv = zpv

s_file   = 'default.scn'
if (keyword_set(scan_file) ne 0 ) then s_file = scan_file

datafile = 'xx_tomo'
if (keyword_set(prefix) ne 0 ) then datafile = prefix
datafile = datafile + '.001'

rep = 1
if (keyword_set(number) ne 0 ) then rep = number

es= obj_new('epics_scan', scan_file = s_file)
x = es->load_to_crate()
print, ' loaded scan to crate'
x = es->set_param('datafile', datafile)
x = es->set_param('dimension', 2)

; sc1 = es->get_param('scan1')
; sc2 = es->get_param('scan2')

n = caget('13IDC:scan2.NPTS', npts2)
n = caget('13IDC:scan2.P1PA', p2a)
n = caget('13IDC:scan2.P1PV', p2_pv)
n = caget('13IDC:scan1.P1PA', p1a)
n = caget('13IDC:scan1.P1PV', p1_pv)

il1 = strlen(p1_pv)
il2 = strlen(p2_pv)
if (strupcase(strmid(p1_pv,il1-4,4)) eq '.VAL') then p1_pv = strmid(p1_pv,0,il1-4)
if (strupcase(strmid(p2_pv,il2-4,4)) eq '.VAL') then p2_pv = strmid(p2_pv,0,il2-4)

scanPV     = '13IDC:scan1'

scan_pause = '13IDC:scanPause.VAL'

for i = 0, n_elements(z_vals) - 1 do begin
    print , ' move ' ,  z_pv, ' to ', z_vals(i)
    print , ' move ' , p1_pv, ' to ', p1a(i), ' and ' , p2_pv, ' to ', p2a(i)
    s = caput(z_pv,  z_vals[i])
    s = caput(p2_pv + '.VAL', p2a(1))
    s = caput(p1_pv + '.VAL', p1a(1))
    s = wait_for_motor(motor = p2_pv, maxtrys=300, wait_time=0.1)
    s = wait_for_motor(motor = p1_pv, maxtrys=300, wait_time=0.1)

    for i2  = 0, npts2 - 1 do begin
        s = caput(p2_pv, p2a[i2])
        lun = es->open_scanfile(/append)
        s = wait_for_motor(motor = p2_pv, maxtrys=300, wait_time=0.1)
        wait, 0.5
        if (i2 eq 0) then begin
            printf, lun, '; Epics Scan 2 dimensional scan'
            printf, lun, '; '
            printf, lun, ';2D ',  p2_pv, ': ', f2a(p2a[i2])
            wait, 2.0
            x = es->start_scan1d()
        endif else begin
            printf, lun, ';2D ',  p2_pv, ': ', f2a(p2a[i2])
            x = es->start_scan1d(/no_header)
        endelse

        wait, 0.5
        running = 1
        while running eq 1 do begin
            s = caget('13IDC:scan1.EXSC', running)
            c = get_kbrd(0)
            c = strlowcase(c)
            if ((c eq string(16B)) or (c eq 'p')) then goto, interrupt
            wait, 1.0
        endwhile
        resume:
        print, ' finished row  ', i2+1, ' of ', npts2, ' for datafile = ', datafile
        slabs = 0 
        if (i2 eq 0) then slabs = 1
        x = es->write_scan_data(short_labels=slabs)
        x = es->close_scanfile()
    endfor
    datafile  = increment_scanname ( datafile )
    x = es->set_param('datafile', datafile)
endfor

;;-----------------------------------;;
;; handle interrupts of scan
time_out:
  print, ''
  print, 'scan timed-out... cannot get scanning status'
  print, 'aborting scan: not writing data file'
  s = caput(scan_pause, 0)
  if (lun gt 0) then begin
      close, lun
      free_lun, lun
  endif
  return

interrupt:
  print, ''
  print, ' ####################################'
  print, ' scan paused by user'
  print, ' type  r   to resume scan'
  print, ' type  a   to abort  scan'
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
          return
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
  
return
end

