pro xyz_scan, scan_file=scan_file, xyz_file=xyz_file, number=number, datafile=datafile

;  execute a defined 1d epics scan multiple times at a set 
;  of predefined x/y/z stage positions

s_file   = 'default.scn'
def_file = 'xyzstage.def'
outfile  = 'scan.dat'
nrepeat  = 3

if (keyword_set(scan_file) ne 0 )  then  s_file   = scan_file
if (keyword_set(xyz_file)  ne 0 )  then  def_file = xyz_file
if (keyword_set(number)    ne 0 )  then  nrepeat  = number
if (keyword_set(datafile)  ne 0 )  then  outfile  = datafile

es  = obj_new('epics_scan', scan_file = s_file)
x   = es->load_to_crate()
x   = es->set_param('datafile', outfile)
x   = es->set_param('dimension', 1)

scanPV     = '13IDC:scan1'
scan_pause = '13IDC:scanPause.VAL'

print, ' reading xyzstage definition file ' , def_file
on_ioerror, bad_file
openr, dlun,  def_file, /get_lun
str     = ' '
line1   =  1
npts    =  0
point   = {point, name:'', x:0., y:0., z:0. }

while not (eof(dlun)) do begin
    readf, dlun, str
    str  = strtrim(str,2)
    if ((str eq '') or (strmid(str, 0, 1)  eq '#')) then goto, loop_end
    if (line1 eq 1) then begin
        line1 = 0
        s = strmid(str, 0, 26) 
        t = strmid(str, 26, strlen(str)) 
        if (s ne ';XYZ Stage Definition File') then begin
            print, ' File ', s_file,  ' is not a valid scan file'
            return
        endif
    endif
    icol  = strpos(str, ':')
    ismc  = strpos(str, ';')
    if ((ismc eq -1) and (icol ge 2)) then begin
        key = strmid(str,0, icol)
        val = strtrim(strmid(str,icol+1, strlen(str)), 2)
        case key of 
            'motor_x':      motor_x = val
            'motor_y':      motor_y = val
            'motor_z':      motor_z = val
            'point':  begin
                tmp      = point
                tmp.name = val
                readf, dlun, str
                str  = strtrim(str,2)
                n = string_array(str, arr)
                if (n ge 1) then    tmp.x = arr[0]
                if (n ge 2) then    tmp.y = arr[1]
                if (n ge 3) then    tmp.z = arr[2]
                if (npts ge 1) then begin
                    pts = [pts, tmp]
                endif else begin
                    pts = tmp
                endelse
                npts   = npts + 1
                tmp    = ''
            end
            else: x = 1
        endcase
    endif
    loop_end:
endwhile

close, dlun
free_lun, dlun
tmp = ''
continue_to_next = 1
print, ' will scan ', npts, ' points '

for i = 0, npts - 1 do begin
    print , ' moving to position  ' , pts[i].name , ' to ', pts[i].x, pts[i].y, pts[i].z
    outfile = pts[i].name + '.001'
    s = caput(motor_x, pts[i].x)
    s = caput(motor_y, pts[i].y)
    s = caput(motor_z, pts[i].z)
    wait, 10.0

    for j = 0, nrepeat - 1 do begin
        x   = es->set_param('datafile', outfile )
        print, '     repeat ', j+1, ' of ', nrepeat
        wait, 1.0
        x    = es->set_param('dimension', 1)
        lun  = es->open_scanfile(/append)
        printf, lun, '; Epics Scan 1 dimensional scan'
        x    = es->start_scan1d()
        wait, 1.0
        scanning = 1
        while scanning eq 1 do begin
            resume:
             s = caget('13IDC:scan1.EXSC', scanning)
             c = get_kbrd(0)
             c = strlowcase(c)
             if ((c eq string(16B)) or (c eq 'p')) then goto, interrupt
             wait, 0.5
        endwhile
        
        x   = es->write_scan_data()
        x   = es->close_scanfile()
        print, ' scan done, wrote ', outfile
        next_scan:
        outfile  = increment_scanname ( outfile )
        if (continue_to_next eq 0) then return
    endfor
endfor

return

;;-----------------------------------;;
bad_file:
  print, '  Warning: XYZ definition file ', bad_file,  ' could not be loaded.'
  return

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
  s = caput(scan_pause, 1)
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
          s = caput(scanPV+'.EXSC',0)
          s = caput(scan_pause, 0)
          if (lun gt 0) then begin
              close, lun
              free_lun, lun
          endif
          return
      end
      'n': begin
          print, 'aborting this scan: not writing data file'
          s = caput(scanPV+'.EXSC',0)
          s = caput(scan_pause, 0)
          continue_to_next = 1
          s  = caput(scan_pause, 0)
          goto, next_scan
      end
      'r': begin
          print, 'resuming scan'
          continue_to_next = 1
          s  = caput(scan_pause, 0)
          goto, resume
      end
      'f': begin
          print, 'finishing this scan only'
          continue_to_next = 0
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




