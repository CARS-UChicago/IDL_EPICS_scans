function sec2hms, x
;
; convert time in seconds to hhh:mm:ss.dd string

default = 'out of range'

catch, error
if (error ne 0) then return, default

x1   = double(x)
x    = abs(x1)
rem  = double(x)
xsgn = 1
if (x ne x1) then xsgn = -1

if (rem gt 1.e12) then return, default
   
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
dd  = abs(round((rem - ss)*100))

; print, hh, mm, ss, dd
ff  = '(i2.2)'
del = ':'
dot = '.'
sgn = ' '
s   =  strtrim(string(hh+extra,del,mm,del,ss,dot,dd, $
                      format='(i9,a,i2.2,a,i2.2,a,i2.2)'),2)

if (xsgn lt 0) then s = '-' + s
return, s
end






