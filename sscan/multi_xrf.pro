pro multi_xrf, file=file, number=number, view=view, start=start, help=help
;
; repetition of sscan
;
if (keyword_set(help) ne 0) then begin
    print, 'multi_xrf: Repeated collection of XRF spectra'
    print, ' argument         meaning      '
    print, '  file       prefix of output file name'
    print, '  number     number of spectra to collect'
    print, '  start      starting index for file name suffix [default=001]'
    print, '  /help      print this help message'
    return
endif

prefix      ='13IDC:med:'
preset_real = prefix + 'PresetReal'
med_start   = prefix + 'Start.VAL'
med= obj_new('EPICS_MED', prefix)
out_file = 'm_xrf'
if (n_elements(file) eq 0)  then  file = ''
if (file ne '')  then  out_file = file

imax = 1
if (n_elements(number) ne 0)  then  imax = number>1

imin = 1
if (n_elements(start) ne 0)  then  imin = start>1

x = caget(preset_real,collect_time)
wait_time =  collect_time/20.0

for i = imin, imax+imin-1 do begin
    xrf_file = out_file + '_' + string(i,format='(i3.3)') + '.xrf'
    x = caput(med_start, 1)
    collecting = 1
    while (collecting) do begin
; check for keyboard interrupt
        c = get_kbrd(0)
        c = strlowcase(c)
        if ((c eq string(16B)) or (c eq 'p')) then goto, interrupt
        resume:
;
        wait, wait_time
        x = caget(med_start, still_going)
        if (still_going eq 0) then begin
            collecting = 0
            med->write_file, xrf_file
            print, ' wrote   ', xrf_file
        endif
    endwhile
endfor

return

interrupt:
  print, ''
  print, ' ####################################'
  print, ' xrf collection paused by user'
  print, ' type  r   to resume collection'
  print, ' type  a   to abort  collection'
  print, ' type  w   to write  spectra so far and quit now'
  print, ' ####################################'
interrupt_2:
  c = get_kbrd(1)
  c = strlowcase(c)
  case c of
      'a': begin
          print, 'aborting scan: not writing data file'
          s = caput(med_start,0)
          return
      end
      'w': begin
          print, 'writing abbreviated spectra ... '
          med->write_file, xrf_file
          print, ' wrote   ', xrf_file
          return
      end
      'r': begin
          print, 'resuming scan'
          goto, resume
      end
      else: begin
          print, ' scan paused: type r for resume, a for abort, w to write and quit'
          goto, interrupt_2
      end
  endcase


end

