pro wait_for_i0_lock
   i_locked     = '13IDA:mono_pid1Locked'
   count = 0
   locked=0
   while ((count le 200) and (locked eq 0)) do begin
       wait, 0.1
       x = caget(i_locked,locked)
       count = count + 1
   endwhile
return
end

pro adjust_ID_mono_tilt
; auto adjust mono tilt:
; find peak i0 intensity with fine steps of coarse tilt motor
; then adjust until feedback is locked with piezo near zero.

 tilt_coarse  = '13IDA:m12.VAL'
 tilt_fine    = '13IDA:DAC1_3.VAL'
 i_setpoint   = '13IDA:mono_pid1.VAL'
 i_actual     = '13IDA:mono_pid2_incalc.I'
 i_locked     = '13IDA:mono_pid1Locked'
 i_fbon       = '13IDA:mono_pid1.FBON'
 i_reset      = '13IDA:mono_pid1EnableReset'

 preslit_left  = '13IDC:IP330_11.VAL'
 preslit_right = '13IDC:IP330_12.VAL'

 coarse_delta = 0.0005

 s = caput(i_fbon,0)
 s = caput(i_reset,0)

 s = caput(tilt_fine, 0)
 s = caget(tilt_coarse, tc0)

; first, see if the tilt_fine can work to control set point
imax = -1.00
fine_best=-1.0

s = caget(i_setpoint, i0_setvalue)

for i = 0, 81 do begin
    fine_val = -4.0 + i * 0.1
    x = caput(tilt_fine, fine_val)
    wait, 0.1
    x = caget(i_actual, ix)
    if (ix gt imax) then begin
        imax = ix
        fine_best = fine_val
    endif
    if imax ge i0_setvalue*1.10 and ix le i0_setvalue  then break
 endfor

s = caget(i_setpoint, i0_setvalue)
print, 'fine search:: ', fine_best, imax, i0_setvalue

if (imax ge i0_setvalue*1.10) then begin
  print, ' no need for full search!'
  x = caput(tilt_fine, fine_best-3.0)
  wait,0.1
  x = caput(tilt_fine, fine_best-0.25)

  x = caput(i_fbon,1)
  x = caput(i_reset,1)
  print, ' waiting for lock'
  wait_for_i0_lock
  return
endif


;
; next, optimize pre-slit sum
 s = caput(tilt_fine, 0.0)
 s = caget(tilt_coarse, tc0)

 tc = tc0 + (-20)* coarse_delta
 x = caput(tilt_coarse, tc)
 wait, 0.5
 imax = 0
 for i = 0, 39 do begin
    tc = tc0 + (i-20)* coarse_delta
    x = caput(tilt_coarse, tc)
    wait, 0.1
    x = caget(preslit_left, ix1)
    x = caget(preslit_right, ix2)
    ix = ix1 + ix2
    if (ix gt imax) then begin
        imax = ix
        tcbest = tc
    endif
 endfor
 print , 'SPLIT: imax, tcbest = ', imax, tcbest
 ; then do fine control for i0
 coarse_delta = 0.0002

 tc = tcbest + (-20)* coarse_delta
 x = caput(tilt_coarse, tc)
 wait, 0.5
 imax = 0
 for i = 0, 39 do begin
    tc = tc0 + (i-20)* coarse_delta
    x = caput(tilt_coarse, tc)
    wait, 0.15
    x = caget(i_actual, ix)
    if (ix gt imax) then begin
        imax = ix
        tcbest = tc
    endif
  endfor
s = caput(tilt_fine, -3.0)
print , 'THEN: imax, tcbest = ', imax, tcbest

 ; set coarse tilt to near best setting
 x = caput(tilt_coarse, tcbest+ 1 * coarse_delta)
wait,0.1
s = caput(tilt_fine, -1.25)
x = caput(i_fbon,1)
x = caput(i_reset,1)

print, ' waiting for lock'

wait_for_i0_lock

print, ' done.'


return
end

