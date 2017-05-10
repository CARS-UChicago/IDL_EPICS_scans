t0 = systime(1)
t = caput('13GE2:scaler1.CNT',1)
buff = dblarr(2,100)
for i=0,99 do begin
   t = caget('13GE2:scaler1.CNT', c)
   buff[0,i]=systime(1)-t0
   buff[1,i]=c
endfor
end
