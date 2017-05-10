pro do_xanes_Fe_S3

; add bench atten if needed
; reset Io gain if needed

;*********************************************************
;Fe xanes
;*********************************************************
;Move to an energy lower then the start of the scan
Eo = 7112
s = caput('13IDA:CDEn:Energy', Eo-100 )
wait,20

scan_file = 'fe_k_med2.scn'
prefix    = 'FeAsS3_med2_Fe'

;*********************************
;Put Vortex into the beam
moveMotor, '13IDC:m13',0
;*********************************
;Remove all filters
s = caput('13IDC:Unidig2Bo15', 1)
;Set the size of the entrance vertical slit
moveMotor, '13IDC:m4',100
;Set gain on Io
s = caput('13IDC:B1sens_num.VAL', 3)
;Set io offset
s = caput('13IDC:B1off_u_put.VAL',230)

mu        = [0.06, 0.24]
nrepeat   = [5, 5]

;open the bench shutter
s = caput('13IDC:Unidig1Bo0', 0)

mu_scan, scan_file=scan_file,datafile=prefix,mu=mu,nrepeat=nrepeat

;close the bench shutter
s = caput('13IDC:Unidig1Bo0', 1)
;*********************************
;Remove all filters
s = caput('13IDC:Unidig2Bo15', 1)
;Set the size of the entrance vertical slit
moveMotor, '13IDC:m4',50
;Set gain on Io
s = caput('13IDC:B1sens_num.VAL', 3)
;Set io offset
s = caput('13IDC:B1off_u_put.VAL',230)

 mu        = [0.5]
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
