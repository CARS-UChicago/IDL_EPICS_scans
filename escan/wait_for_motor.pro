function wait_for_motor, motor=motor, maxtrys=maxtrys, wait_time=wait_time
;
; wait for a motor to finish moving 
; defined as a motor's DMOV field going to 1
; 
; returns number of 'wait interval' (calls to caget)
;
; 
if (n_elements(motor) eq 0) then begin
    print, ' Wait For Motor Needs Motor Name'
    return, -1
endif

if (n_elements(maxtrys)   eq 0) then maxtrys = 200
if (n_elements(wait_time) eq 0) then wait_time = 0.05

; munge motor name to  DMOV variable
motor_dmov  = motor
len = strlen(motor_dmov)
if (strupcase(strmid(motor_dmov,len-4,4)) eq '.VAL') then begin
    motor_dmov = strmid(motor_dmov,0,len-4)  + '.DMOV'
endif else begin
    motor_dmov = motor_dmov + '.DMOV'
endelse

; print, ' waiting for ', motor, ' to be done : ', motor_dmov
;
; wait for motor
ntrys = 0
dmov  = 0
while (dmov eq 0) do begin
    wait, wait_time
    ntrys = ntrys + 1
    s = caget(motor_dmov, dmov)
    if (ntrys ge maxtrys) then dmov = 1
endwhile      

return, ntrys

end



