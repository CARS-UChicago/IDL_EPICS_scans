function pre_scan_command, scanpv
; dummy pre scan command
print, 'dummy pre scan command ', scanpv
;x = caget('13IDC:edb:dir', wdir)
;workdir = string(wdir)
;if (strlen(workdir) ge 1) then cd, workdir

;x = caput('13BMD:scaler1.CNT',       1)
;x = caput('13BMD:scaler1.CONT',      0)

;x = caput('13GE2:med:EraseAll',      1)
;x = caput('13GE2:med:PresetReal',    1)
;x = caput('13GE2:med:PresetLive',    0)
;x = caput('13GE2:med:StatusAll.SCAN',9)
;x = caput('13GE2:med:ReadAll.SCAN',  8)
;x = caput('13GE2:med:EraseStart',    1)

; get positioner data
;x  = caget('13BMD:scan1.P1PV', p1pv)
;x  = caget('13BMD:scan1.P1PA', p1pa)
;x  = caput(p1pv,p1pa[0])
wait, 0.1

return,1
end
