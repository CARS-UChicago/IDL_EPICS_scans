pro sscan_3d, file=file, view=view, comment = comment
;
; simple emulation of 2D EPICS scan, reading values set from 
; scan record, and then performing 1d 'sscan' repeatedly.
;
;  -- assumes  scan2 is setup in scan record properly

out_file = 'scan'
if (n_elements(file) eq 0)  then  file = ''
if (file ne '')  then  out_file = file

title = ' '
if (n_elements(comment) ne 0)  then  title = comment + title

P3d ='13IDC:scan3.'
; start scan, with some error checking
s = caget(P3d+'NPTS', s3d_npts)
s = caget(P3d+'P1SM', s3d_mode)
s = caget(P3d+'P1PA', s3d_p1pa)
s = caget(P3d+'P1PV', s3d_pos)

; print, ' 3d: mode = ', s3d_mode
if (s3d_mode eq 0) then begin
    s = caget(P3d+'P1SP', s3d_p1sp)
    s = caget(P3d+'P1SI', s3d_p1si)
    s = caget(P3d+'P1AR', s3d_p1ar)
    if (s3d_p1ar eq 1) then  begin
        s = caget(s3d_pos, xx)
        s3d_p1sp = s3d_p1sp + xx
    endif
    for i = 0, s3d_npts-1 do  s3d_p1pa[i] = s3d_p1sp + s3d_p1si * i
endif



P2d ='13IDC:scan2.'
; start scan, with some error checking
s = caget(P2d+'NPTS', s2d_npts)
s = caget(P2d+'P1SM', s2d_mode)
s = caget(P2d+'P1PA', s2d_p1pa)
s = caget(P2d+'P1PV', s2d_pos)

; print, ' 2d: mode = ', s2d_mode, ' -- ', p2d
if (s2d_mode eq 0) then begin
    s = caget(P2d+'P1SP', s2d_p1sp)
    s = caget(P2d+'P1SI', s2d_p1si)
    s = caget(P2d+'P1AR', s2d_p1ar)
    if (s2d_p1ar eq 1) then  begin
        s = caget(s2d_pos, xx)
        s2d_p1sp = s2d_p1sp + xx
    endif
  ;  print, ' 2d:  mode  = ', s2d_mode, s2d_p1ar
  ;  print, ' 2d:  pos   = ', s2d_pos
  ;  print, ' 2d:  start = ', s2d_p1sp
    for i = 0, s2d_npts-1 do  s2d_p1pa[i] = s2d_p1sp + s2d_p1si * i
endif

; update index, perform simple scan

for i3d = 0, s3d_npts - 1 do begin
    s = caput(s3d_pos, s3d_p1pa[i3d])
    print, format='(1x,3a,f12.6,a,i3,a,i3)', ' move ', s3d_pos , ' to ',$
      s3d_p1pa[i3d], ' : point ',i3d+1,' of ', s3d_npts
    scan_file = out_file  + '_' + string(i3d+1,format='(i3.3)')  + '.dat'
    otitle = title + s3d_pos + '=' + string(s3d_p1pa[i3d]) + ' | '
    
    for i2d = 0,  s2d_npts - 1  do begin
        s = caput(s2d_pos, s2d_p1pa[i2d])
        print, format='(1x,3a,f12.6,a,i3,a,i3)', ' move ', s2d_pos , ' to ',$
          s2d_p1pa[i2d], ' : point ',i2d+1,' of ', s2d_npts
        otitle = otitle + s2d_pos + '=' + string(s2d_p1pa[i2d])
        

        wait, 1.
        if (i2d eq 0) then begin
            status = sscan(file=scan_file , view=view, $
                           comment = otitle, /append)
        endif else begin
            status = sscan(file=scan_file , view=view, $
                           comment = otitle, /append, $
                           /no_motors, /no_detectors)
        endelse
        if (status ne 0) then begin
            print, 'sscan_3d saw interrupt from sscan'
            return
        endif
    endfor
endfor

print, ' sscan_3d is done.'
return
end



