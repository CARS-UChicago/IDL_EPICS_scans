pro multi_2dscan, scan_file=scan_file, prefix=prefix, number=number
;
;  execute a defined 2dscan
;

s_file   = 'default.scn'
if (keyword_set(scan_file) ne 0 ) then s_file = scan_file
es  = obj_new('epics_scan', scan_file = s_file)

datafile = 'sr_line.001'
if (keyword_set(prefix) ne 0 ) then datafile = prefix

rep = 3
if (keyword_set(number) ne 0 ) then rep = number

x = es->load_to_crate()
x = es->set_param('datafile', datafile)
x = es->set_param('dimension', 1)

n = caget('13IDC:scan2.NPTS', npts2)
n = caget('13IDC:scan2.P1PA', p1pa)
n = caget('13IDC:scan2.P1PV', p1_drive)

scanPV     = '13IDC:scan1'
scan_pause = '13IDC:scanPause.VAL'


for i = 0, npts2 - 1 do begin
    print , ' move ' , p1_drive , ' to ', p1pa(i)
    s = caput(p1_drive, p1pa(i))
    wait, 3.0
    for j = 0, rep - 1 do begin
        print, ' repeat # ', j, ' datafile = ', datafile
        wait, 3.0
        lun = es->open_scanfile(/append)
        printf, lun, '; Epics Scan 1 dimensional scan'
        x = es->start_scan1d()
        running = 1
        wait, 5.0
        while running eq 1 do begin
            s = caget('13IDC:scan1.EXSC', running)
            c = get_kbrd(0)
            c = strlowcase(c)
            if ((c eq string(16B)) or (c eq 'p')) then goto, interrupt
            wait, 1.0
        endwhile
        resume:
        print, ' scan is finished ! '
        x = es->write_scan_data()
        x = es->close_scanfile()
        datafile  = increment_scanname ( datafile )
        x = es->set_param('datafile', datafile)
    endfor
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

