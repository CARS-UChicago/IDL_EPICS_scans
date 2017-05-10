pro do_xanes_As_s2

; add bench atten if needed
; reset Io gain if needed

;*********************************************************
;As xanes
;*********************************************************
;Move to an energy lower then the start of the scan
Eo = 11867
s = caput('13IDA:CDEn:Energy', Eo-100 )
wait,20

scan_file = 'as_k_med.scn'
prefix    = 'FeAsS2b_med_As'

;*********************************
;Put Vortex into the beam
moveMotor, '13IDC:m13',0
;*********************************
;Remove 50 um Mo
s = caput('13IDC:Unidig2Bo15', 1)
;Set the size of the entrance vertical slit
moveMotor, '13IDC:m4',100
;Set gain on Io
s = caput('13IDC:B1sens_num.VAL', 0)
;Set io offset
s = caput('13IDC:B1off_u_put.VAL',230 )

mu        = [0.05, 0.1, 0.14, 0.18]
nrepeat   = [5, 5, 5, 5]

;open the bench shutter
s = caput('13IDC:Unidig1Bo0', 0)

mu_scan, scan_file=scan_file,datafile=prefix,mu=mu,nrepeat=nrepeat

;close the bench shutter
s = caput('13IDC:Unidig1Bo0', 1)
;*********************************

;*********************************
;Insert 50 um Mo
s = caput('13IDC:Unidig2Bo15', 0)
;Set the size of the entrance vertical slit
moveMotor, '13IDC:m4',100
;Set gain on Io
s = caput('13IDC:B1sens_num.VAL', 0)
;Set io offset
s = caput('13IDC:B1off_u_put.VAL',230 )

mu        = [0.4]
nrepeat   = [5]

;open the bench shutter
s = caput('13IDC:Unidig1Bo0', 0)

mu_scan, scan_file=scan_file,datafile=prefix,mu=mu,nrepeat=nrepeat

;close the bench shutter
s = caput('13IDC:Unidig1Bo0', 1)
;*********************************

;*********************************************************

return
end
