pro sscan_2d, file=file, view=view, comment = comment, $
              start=start, no_append=no_append, number = number
;
; simple emulation of 2D EPICS scan, reading values set from 
; scan record, and then performing 1d 'sscan' repeatedly.
;
;  -- assumes  scan2 is setup in scan record properly

out_file = 'sscan'
if (n_elements(file) ne 0)  then  out_file =file


new_file = 0
if (keyword_set(no_append) ne 0)  then  new_file = 1

title = ' '
if (n_elements(comment) ne 0)  then  title = comment + title

ibeg= 1
if (n_elements(start) ne 0)  then  ibeg = start>1

icount= 1
if (n_elements(number) ne 0)  then  icount = number>1

P='13IDC:scan2.'
; start scan, with some error checking
s = caget(P+'NPTS', s_npts)

s = caget(P+'P1SM', s_mode)
s = caget(P+'P1PA', s_p1pa)
s = caget(P+'P1PV', pos)

if (s_mode eq 0) then begin
    s = caget(P+'P1SP', s_p1sp)
    s = caget(P+'P1SI', s_p1si)
    for i = 0, s_npts-1 do  s_p1pa[i] = s_p1sp + s_p1si * i
    s_p1pa[s_npts]   = s_p1pa[s_npts-1]
    s_p1pa[s_npts+1] = s_p1pa[s_npts-1]
endif

; update index, perform simple scan
print, 'ibeg, s_npts = ', ibeg, s_npts

for i = ibeg, s_npts - 1 + ibeg do begin
    j = i - ibeg
    print, ' move ', pos, '   to ', s_p1pa[j], ' point ' , j
    s = caput(pos, s_p1pa[j])
    for k =  1, icount do begin
        print, format='(1x,3a,f12.6,a,i3,a,i3)', ' move ', pos , ' to ',$
          s_p1pa[j], ' : point ',i,' of ', s_npts
        otitle = title + pos + '=' + string(s_p1pa[j])
        scan_file = out_file
        if (new_file eq 1) then begin
            scan_file = out_file  + string(i,format='(i3.3)')  + '.dat'
            if (k gt 1)   then scan_file = out_file  + $
              string(i,format='(i3.3)')  + '_' + string(k,format='(i2.2)') + '.dat'
        endif
        wait, 0.5
        if ((i gt ibeg)) then begin
            status = sscan(file=scan_file , view=view, $
                           comment = otitle, /append, $
                           /no_motors, /no_detectors)
        endif else begin
            status = sscan(file=scan_file , view=view, $
                           comment = otitle, /append)
        endelse
        if (status ne 0) then begin
            print, 'sscan_2d saw interrupt from sscan'
            return
        endif
    endfor
endfor

print, ' sscan_2d is done.'
return
end


