pro do_scan, scan_file=scan_file,  number=number, datafile=datafile, save_image=save_image
;
;  execute a defined 1d epics scan multiple times

s_file   = 'default.scn'
dat_file = 'scan.dat'
nrepeat  = 1
with_image = 0
if (keyword_set(save_image) ne 0 ) then  with_image = save_image
if (keyword_set(scan_file) ne 0 )  then  s_file   = scan_file
if (keyword_set(number)    ne 0 )  then  nrepeat  = number
if (keyword_set(datafile)  ne 0 )  then  dat_file  = datafile

es  = obj_new('epics_scan', scan_file = s_file)
x   = es->load_to_crate()
x   = es->set_param('datafile', dat_file)
x   = es->set_param('dimension', 1)
es->set_clientid

spre    = es->get_param('prefix')
pausePV = spre + 'scanPause.VAL'
scanPV  = spre + 'scan1'
execPV  = scanPV + '.EXSC'

outfile  = dat_file
continue_to_next = 1

wait, 1.0

for j = 0, nrepeat - 1 do begin
    x   = es->set_param('datafile', outfile )
    print, '     repeat ', j+1, ' of ', nrepeat
    print, '   Hit  "p" to pause scan '
    if with_image then save_microscope_image, outfile + '.jpg'
    wait, 1.0
    x    = es->set_param('dimension', 1)
    lun  = es->open_scanfile(/append)
    printf, lun, '; Epics Scan 1 dimensional scan'
    x    = es->start_scan1d()
    if (x eq -2 ) then begin
        print , '; scan appears busy: will try again'
        wait, 60.
        x    = es->start_scan1d()
        if (x eq -2) then begin
            print, '; scan really seems busy: bailing on this scan !'
            printf, lun, '; scan could not be started'
            goto, next_scan
        endif
        print, '; ok, now the scan is going.....'
    endif
    wait, 1.0
    scanning = 1
    while scanning eq 1 do begin
        resume:
        s = caget(execPV, scanning)
        c = get_kbrd(0)
        c = strlowcase(c)
        if ((c eq string(16B)) or (c eq 'p')) then begin
            goto, interrupt
        endif
        wait, 0.5
    endwhile

    next_scan:
    x   = es->write_scan_data()
    x   = es->close_scanfile()
    print, ' scan done, wrote ', outfile
    outfile  = increment_scanname ( outfile, /new )
    if (continue_to_next eq 0) then begin
        obj_destroy, es
        return
    endif
endfor

obj_destroy, es
heap_gc, /obj, /ptr

return

;;-----------------------------------;;
;; handle interrupts of scan
interrupt:
  s = caput(pausePV, 1)
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

interrupt_2:
  c = strlowcase(get_kbrd(1))
  case c of
      'a': begin
          print, 'aborting all scans'
          s = caput(execPV,0)
          s = caput(pausePV, 0)
          x = es->write_scan_data()
          x = es->close_scanfile()
          obj_destroy, es
          return
      end
      'n': begin
          print, 'aborting this scan, going to next'
          s = caput(execPV,0)
          s = caput(pausePV, 0)
          continue_to_next = 1
          s  = caput(pausePV, 0)
          goto, next_scan
      end
      'r': begin
          print, 'resuming scan'
          continue_to_next = 1
          s  = caput(pausePV, 0)
          goto, resume
      end
      'f': begin
          print, 'finishing this scan only'
          continue_to_next = 0
          s = caput(pausePV, 0)
          goto, resume
      end
      'k': begin
          continue_to_next = 0
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

end




