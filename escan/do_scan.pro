pro epics_scan::do_scan, count=count
;
;  execute a defined 1d epics scan multiple times at a set 

nrepeat = 1
if (keyword_set(count)     ne 0 )  then  nrepeat  = count

self->set_param('dimension', 1)
self->load_to_crate()

for j = 0, nrepeat - 1 do begin
    print, '     repeat ', j+1, ' of ', nrepeat
    lun  = self->open_scanfile(/append)
    self->write_to_scanfile, '; Epics Scan 1 dimensional scan'
    x    = self->start_scan1d()
    wait, 1.0
    scanning = 1
    while scanning eq 1 do begin
        resume:
        scanning = self->is_scanning()
        c = get_kbrd(0)
        c = strlowcase(c)
        if ((c eq string(16B)) or (c eq 'p')) then goto, interrupt
        wait, 0.5
    endwhile
   
    x  = self->write_scan_data()
    x  = self->close_scanfile()
    print, ' scan done, wrote ', self.datafile
    next_scan:
    self.datafile  = increment_scanname ( self.datafile )
    if (continue_to_next eq 0) then return
endfor

return

;;-----------------------------------;;
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

;; handle interrupts of scan
interrupt:
  self->pause_scan()
  print, ''
  print, ' ####################################'
  print, ' scan paused by user.  Type one of the following options:'
  print, '    r   to resume scan sequence'
  print, '    n   to abort this scan and go to next'
  print, '    a   to abort all scans'
  print, '    f   to finish this scan, but not start any more' 
  print, '           (for multiple or multi-dimensional scans)  '
  print, ' ####################################'
  
interrupt_2:
  c = strlowcase(get_kbrd(1))
  case c of
      'a': begin
          print, 'aborting scan: not writing data file'
          self->abort()
          if (self.lun gt 0) then  x = self->close_scanfile()
          return
      end
      'n': begin
          print, 'aborting this scan: not writing data file'
          self->abort()
          continue_to_next = 1
          goto, next_scan
      end
      'r': begin
          print, 'resuming scan'
          continue_to_next = 1
          self->unpause()
          goto, resume
      end
      'f': begin
          print, 'finishing this scan only'
          continue_to_next = 0
          self->unpause()
          goto, resume
      end
      else: begin
          print, ' scan paused: type r for resume, a for abort, f to finish current scan only'
          goto, interrupt_2
      end
  endcase
;;-----------------------------------;;
  


end




