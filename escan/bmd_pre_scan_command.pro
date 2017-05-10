function pre_scan_command, scanpv
;
; this function is meant to be overwritten for custom 'pre-scan' setup

print, 'June08 BM,  pre-scan command for scan= ', scanpv

x = caget('13BMD:edb:dir', w)
workdir= string(w)
if (strlen(workdir) ge 1) then cd, workdir


x = caput('13BMD:scaler1.CNT',       1)
x = caput('13BMD:scaler1.CONT',      0)

;x = caput('13GE2:med:EraseAll',      1)
;x = caput('13GE2:med:PresetReal',    1)
;x = caput('13GE2:med:PresetLive',    0)
;x = caput('13GE2:med:StatusAll.SCAN',9)
;x = caput('13GE2:med:ReadAll.SCAN',  8)
;x = caput('13GE2:med:EraseStart',    1)

; get positioner data
p1pa = 0
x  = caget('13BMD:scan1.P1PV', p1pv)
x  = caget('13BMD:scan1.P1PA', p1pa)
p0 = p1pa[0] + (p1pa[0] - p1pa[2])/2.0

x  = caput(p1pv,p1pa[1])
wait, 1.0

if p1pv eq '13BMA:E:Energy.VAL' then  begin
   x = caput('13BMA:mono_pid1.FBON',0)
   x = caget('13BMA:DAC1_3.VAL',dac_val)
   x = caput('13BMA:DAC1_3.VAL',dac_val-0.050)
   x = caput('13BMA:mono_pid1.FBON',1)
endif


x  = caput(p1pv,p0)
wait, 1.0
x = caput('13GE2:med:EraseAll',      1)

count = 0
beam  = 0
;
while ((count le 3600) and (beam ne 1)) do begin
    x = caget('13BMA:eps_mbbi99',beam)
    count = count + 1
    wait, 1.0
endwhile
;
print, 'beam is on! '

; lock onto beam
x  = caput('13BMA:mono_pid1.FBON',1)
count  = 0
locked = 0

wait, 1.0
while ((count le 500) and (locked eq 0)) do begin
    wait, 0.5
    x = caget('13BMA:mono_pid1Locked',locked)
    count = count + 1
endwhile
;
;
print, 'feedback set,  move to scan start: ', p0
x  = caput(p1pv,p1pa[0])
;
wait, 0.5
return, 1
end
;


