pro do_map, scan_file=scan_file, datafile=datafile
;
;  execute a defined 2dscan

s_file   = 'default.scn'
if (keyword_set(scan_file) ne 0 ) then s_file = scan_file
es      = obj_new('epics_scan', scan_file = s_file)
prefix  = es->get_param('prefix')
scan1PV = es->get_scan_param(0,'scanpv')
scan2PV = es->get_scan_param(1,'scanpv')

outfile = 'test_map.001'
if (keyword_set(datafile) ne 0 ) then outfile = datafile

x = es->load_to_crate()
x = es->set_param('datafile', outfile)
x = es->set_param('dimension', 1)

n = caget(scan2PV+'.NPTS', s2_npts)
n = caget(scan2PV+'.P1PA', s2_p1pa)
n = caget(scan2PV+'.P1PV', s2_p1pv)

scan_pause = prefix+'scanPause.VAL'
short_labels=0
save_med  = es->get_param('save_med')

es->set_clientid

s2_p1dmov = strmid(s2_p1pv,0,strpos(s2_p1pv,'.VAL')) + '.DMOV'

for i = 0,  s2_npts - 1 do begin
    ismaster = es->check_clientid()
    if ismaster eq 0 then begin
        wait, 1.0
        continue
    endif

    print , '=== move ' , s2_p1pv , ' to ', s2_p1pa(i)
    s   = caput(s2_p1pv, s2_p1pa(i), /wait)
    lun = es->open_scanfile(/append)
    done_moving = 0
    while done_moving eq 0 do begin
        wait, 0.010
        x = caget(s2_p1dmov, done_moving)
    endwhile

    if (i eq 0) then begin
        printf, lun, '; Epics Scan 2 dimensional scan'
        printf, lun, '; '
        printf, lun, ';2D ',  s2_p1pv, ': ', f2a(s2_p1pa[i])
        wait, 1.0
        x = es->start_scan1d()
    endif else begin
        printf, lun, ';2D ',  s2_p1pv, ': ', f2a(s2_p1pa[i])
        x = es->start_scan1d(/no_header)
    endelse

    running = 1
    wait, 0.1
    while running eq 1 do begin
        s = caget(scan1PV+'.EXSC',running)
        if (save_med eq 1) then begin
            sready_to_read = es->check_scan_wait()
            if (sready_to_read eq 1) then  begin
                x = es->save_med_spectra(row=i+1)
                x = es->clear_scan_wait()
            endif
        endif
        ; check for interrupt
        c = strlowcase(get_kbrd(0))
        if ((c eq string(16B)) or (c eq 'p')) then goto, interrupt
        wait, 0.05
    endwhile
    resume:
    print, ' 1D scan is finished ! ', i+1 , s2_npts
    x = es->write_scan_data(short_labels=short_labels)
    x = es->close_scanfile()
    short_labels=1
    if (save_med eq 1) then x = es->save_med_spectra(row=i+1)

;    outfile  = increment_scanname ( outfile )
;    x = es->set_param('datafile', outfile)
endfor

print, 'MAP DONE!'

obj_destroy, es
heap_gc, /obj, /ptr

return

;;-----------------------------------;;
;; handle interrupts of scan
; time_out:
;   print, ''
;   print, 'scan timed-out... cannot get scanning status'
;   print, 'aborting scan: not writing data file'
;   s = caput(scan_pause, 0)
;   if (lun gt 0) then begin
;       close, lun
;       free_lun, lun
;   endif
;   return

interrupt:
  print, ''
  print, ' ####################################'
  print, ' scan paused by user.  Type one of the following options:'
  print, '    r   to resume scan sequence'
  print, '    n   to abort this scan and go to next'
  print, '    a   to abort all scans'
  print, '    k   to kill batch file / macro'
  print, '    f   to finish this scan, but not start any more'
  print, '           (for multiple or multi-dimensional scans)  '
  print, ' ####################################'
  s = caput(scan_pause, 1)

interrupt_2:
  c = get_kbrd(1)
  c = strlowcase(c)
  case c of
      'a': begin
          print, 'aborting scan: not writing data file'
          s = caput(scan1PV+'.EXSC',0)
          s = caput(scan_pause, 0)
          if (lun gt 0) then begin
              close, lun
              free_lun, lun
          endif
          obj_destroy, es
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
      'k': begin
          continue_to_next = 0

          spre    = es->get_param('prefix')
          pausePV = spre + 'scanPause.VAL'
          scanPV  = spre + 'scan1'
          execPV  = scanPV + '.EXSC'

          print, 'aborting all scans'
          s = caput(execPV,0)
          s = caput(pausePV, 0)
          x = es->write_scan_data()
          x = es->close_scanfile()
          obj_destroy, es
          retall
      end
      else: begin
          print, ' scan paused: type r for resume, a for abort, f to finish current scan only'
          goto, interrupt_2
      end
  endcase
;;-----------------------------------;;

obj_destroy, es

return
end

