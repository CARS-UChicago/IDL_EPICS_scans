pro sscan_multi, file=file, number=number, view=view, start=start, help=help, $
                comment=comment, no_motors=no_motors
;
; repetition of sscan
;
if (keyword_set(help) ne 0) then begin
    print, 'Sscan_multi: Repeated 1D scans'
    print, ' argument         meaning      '
    print, '  file       prefix of output file name   '
    print, '  view       array of detectors to view'
    print, '  number     number of scans to repeat'
    print, '  start      starting index for file name suffix [default=001]'
    print, '  /no_motors do not collect motors for each scan'
    print, '  /help      print this help message'
    return
endif

out_file = 'sscan'
if (n_elements(file) eq 0)  then  file = ''
if (file ne '')             then  out_file = file

comment_ = ' '
if (n_elements(comment) ne 0)  then  comment_ = comment

imax = 1
if (n_elements(number) ne 0)  then  imax = number>1

get_motors = 1
if (keyword_set(no_motors) ne 0)  then  get_motors = 0

imin = 1
if (n_elements(start) ne 0)  then  imin = start>1

for i = imin, imax+imin-1 do begin
    scan_file = out_file + '_' + string(i,format='(i3.3)') + '.dat'
    if ((i gt imin) and (get_motors eq 0)) then begin
        status = sscan(file=scan_file , view=view, /no_motors, $
                             comment=comment_)
        print, ' sscan status = ', status
    endif else begin
        status = sscan(file=scan_file , view=view, comment=comment_)
        print, ' sscan status = ', status
    endelse

    if (status ne 0) then begin
        print, 'sscan_multi saw interrupt from sscan'
        return
    endif
endfor

return
end
