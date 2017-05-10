pro center_id_bpm, dtheta=dtheta,dchi=dchi

; this auto-centers the ID x-ray BPM, 
; moving the mono dtheta and dchi until the
; BPM DACS read between 1500 and 2500

pitch_motor = '13IDA:m12'
roll_motor  = '13IDA:m11'
pitch_dac   = '13IDA:fast_pitch_pid.OVAL'
roll_dac    = '13IDA:fast_roll_pid.OVAL'

if (keyword_set(dtheta) ne 0 ) then pitch_motor = dtheta
if (keyword_set(dchi) ne 0 )   then roll_motor  = dchi


pitch = obj_new('EPICS_MOTOR', pitch_motor)
roll  = obj_new('EPICS_MOTOR', roll_motor)

max_trys = 10
lo_val = 1500
hi_val = 2500
; pitch
x = caget(pitch_dac, dac0)
x = caget(pitch_motor+'.RBV',p0)
ntry = 0
while ( (dac0 lt lo_val) or (dac0 gt hi_val)) do begin

    ntry = ntry + 1
    
    x = caput(pitch_motor+'.VAL',p0+0.001)
    x = caget(pitch_motor+'.RBV',p1)
    x = caget(pitch_dac,dac1)

    if ((dac1 lt 4096) and (dac1 gt 0)) then  begin
        print,  (dac1-dac0)/(p1-p0)
    

endwhile
