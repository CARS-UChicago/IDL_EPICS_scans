function sec2hms, x
; convert time in seconds to hhh:mm:ss.dd string

rem = double(x)

hh  = long(rem / 3600.)
rem = rem - hh * 3600.
mm  = long(rem / 60.)
rem = rem - mm * 60.
ss  = abs(long(rem)) < 100 
dd  = abs(long((rem - ss)*100)) < 1 

; print, ' time: ', x
; print,  ' hh , mm, ss  = ', hh, mm, ss
ff  = '(i2.2)'
s   =  strtrim(string(hh),2) + ':' +  string(mm,format=ff) + ':' + $
       string(ss,format=ff)  + '.' +  string(dd,format=ff) 
return, s
end






