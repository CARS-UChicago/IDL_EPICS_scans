function sec2hms, x
; convert time in seconds to hhh:mm:ss.dd string

xsgn  = 1
if (x le 0) then xsgn = -1
x     = abs(x)
rem   = double(x)
if (rem gt 1.e12) then return,  'out of range'
   
extra = 0.
if (rem gt 1.e8) then begin
    while (rem gt 1.e8) do begin
        extra = extra + 1.e4
        rem   = rem - 1.e4*3600.
    endwhile
endif

hh  = long(rem / 3600.)
rem = rem - hh * 3600.
mm  = long(rem / 60.)
rem = rem - mm * 60.
ss  = abs(long(rem)) < 60 
dd  = abs(round((rem - ss)*10)) > 0 < 9

; print, hh, mm, ss, dd
ff  = '(i2.2)'
del = ':'
dot = '.'
s   =  strtrim(string(hh+extra,del,mm,del,ss,dot,dd, $
                      format='(i9,a,i2.2,a,i2.2,a,i1.1)'),2)

if (xsgn lt 0) then s = '-' + s
return, s
end






