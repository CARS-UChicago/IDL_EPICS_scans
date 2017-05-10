function f2a, x
; floating point to string
; print, 'F2A X2 ', x, type(x)
; help, x
if meron_type(x) eq 2 then return,  strtrim(string(x),2)
if meron_type(x) eq 1 then x = float(x)

if abs(x) le 1.e-16 then return,  '0.0'

catch, error, /cancel
if error ne 0 then al = 0.
al  = alog10(abs(x))

fstr = '(f17.7)'
if (abs(al) gt 5) then fstr = '(g15.6)'
s = strtrim(string(x,format=fstr),2)
dosub = 1
for i = strlen(s), 0, -1 do begin
   if strmid(s,i-1,1) ne '0' then dosub = 0
   if strmid(s,i-1,1) eq '0' and  dosub eq 1 then strput, s, ' ', i-1
endfor


s =  strtrim(s,2)  
if strmid(s,strlen(s)-1,1) eq '.' then s = s  + '0'

s = strtrim(s,2)  
;; print, 'f2a ', x, ' ==> ', s
return , s
         
end
