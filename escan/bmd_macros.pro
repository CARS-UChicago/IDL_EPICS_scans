pro set_srs570_gain, amppv, sens, unit
; set sensitivity for SRS570 amplifier
    steps = [1, 2, 5, 10, 20, 50, 100, 200, 500]
    units = ['pA/V', 'nA/V','uA/V', 'mA/V']

    sval = where(steps eq sens)
    uval = where(units eq unit)

    ; set sensitivity
    x = caput(amppv + 'sens_num.VAL',   sval)
    x = caput(amppv + 'sens_unit.VAL',  uval)

    ; set input offset scale to be 10x smaller than sensitivity
    off_unit = uval
    off_num  = sval - 3
    if sval lt 3 then begin
        off_unit = uval - 1
        off_num  = sval + 6
    endif
    x = caput(amppv + 'offset_unit.VAL',   off_unit)
    x = caput(amppv + 'offset_num.VAL',    off_num)
    x = caput(amppv + 'off_u_put.VAL',     140)
    x = caput(amppv + 'init.PROC',     1)
return
end

pro wait_for_motor, pv, tmax=tmax
; wait for a motor to finish moving
    xtmax =10
    if (keyword_set(tmax) ne 0) then xtmax =tmax
    dpv = strmid(pv,0,strpos(pv,'.VAL'))+'.DMOV'
    moving = 1
    count = 0
    xtmax = xtmax * 10.0
    while moving eq 1 do begin
        s = caget(dpv, dmove)
        if dmove eq 1     then moving = 0
        if count ge xtmax then moving = 0
        count  = count+1
        wait,0.1
    endwhile
return
end


pro set_i0_sensitivity, sens, unit
    set_srs570_gain, '13BMD:A3', sens, unit
return
end

pro set_i0, value
    x = caput('13BMA:mono_pid1.VAL', value)
return
end

pro wait_for_i0_lock
   i_locked     = '13BMA:mono_pid1Locked'
   count = 0
   locked= 0
   while ((count le 600) and (locked eq 0)) do begin
       wait, 0.1
       x = caget(i_locked,locked)
       count = count + 1
   endwhile
return
end


pro adjust_mono_tilt
; auto adjust mono tilt:
; find peak i0 intensity with fine steps of coarse tilt motor
; then adjust until feedback is locked with piezo near zero.

 tilt_coarse  = '13BMA:MON:t1.AX'
 tilt_fine    = '13BMA:DAC1_3.VAL'
 i_setpoint   = '13BMA:mono_pid1.VAL'
 i_actual     = '13BMA:mono_pid1.CVAL'
 i_locked     = '13BMA:mono_pid1Locked'
 i_fbon       = '13BMA:mono_pid1.FBON'
 i_reset      = '13BMA:mono_pid1EnableReset'

 coarse_delta = 0.0004

 s = caput(i_fbon,0)
 s = caput(i_reset,0)

 s = caput(tilt_fine, 0)
 s = caget(tilt_coarse, tc0)

 tc = tc0  -20 * coarse_delta
 tcbest = tc
 x = caput(tilt_coarse, tc)
 wait, 0.5
 imax = 0
 for i = 0, 39 do begin
    tc = tc0 + (i-20)* coarse_delta
    x = caput(tilt_coarse, tc)
    wait, 0.1
    x = caget(i_actual, ix)
    if (ix gt imax) then begin
        imax = ix
        tcbest = tc
    endif
endfor

; set coarse tilt to near best setting
x = caput(tilt_coarse, (tcbest+ 1 * coarse_delta)-0.002 )
x = caput(tilt_fine, -1.5)

x = caput(i_fbon,1)
x = caput(i_reset,1)
print, ' found max, now waiting for lock at setpoint '

wait_for_i0_lock

return
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro move_mono_energy, energy=energy

    if keyword_set(energy) eq 0 then begin
        print, 'must give energy to move to!!'
        return
    endif
    x = caput('13BMA:E:z2_track.VAL', 1)
    x = caput('13BMA:E:y2_track.VAL', 1)
    wait, 0.5

    x = caput('13BMA:mono_pid1.FBON', 0)
    x = caput('13BMA:E:Energy.VAL', energy)
    x = caput('13BMA:DAC1_3.VAL', 0.0)

    wait, 2.0

    x = caput('13BMA:E:Energy.VAL', energy)
    wait, 0.5

    wait_for_motor, '13BMA:m14.VAL', tmax=300
    wait_for_motor, '13BMA:m12.VAL', tmax=300

    wait, 0.5
    x = caput('13BMA:E:z2_track.VAL', 0)
    x = caput('13BMA:E:y2_track.VAL', 0)
    return
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pro move_to_energy, energy, i0=i0
 move_mono_energy, energy=energy
 if keyword_set(i0) ne 0 then set_i0, i0
 wait, 1.0
 adjust_mono_tilt
return
end


pro move_to_as, i0=i0
   print, "move_to_energy, 11900.0, i0=i0"
return
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro collect_xrf, pos, t=t, ext=ext

    if keyword_set(t)     eq 0 then t   = 60
    if keyword_set(ext)   eq 0 then ext = 1

    move_stage, position=pos, wait=0 
    index = string(ext, format='(i3.3)')
    counttime = t
    x = caput('13BMD:AbortScans.PROC',1)

    prefix = 'dxpMercury:' 
    env_file = '//cars5/Data/xas_user/config/XRM_XMAP_PVS_BMD.DAT'

    med = obj_new('EPICS_MED', prefix, 4, environment_file=env_file)
    x = caput(prefix+'PresetReal', counttime)
    x = caput(prefix+'EraseAll',      1)
    x = caput(prefix+'PresetLive',    0)
    x = caput(prefix+'PresetMode',    1)
    x = caput(prefix+'CollectMode',   0)

    move_stage, position=pos, wait=1 
    wait, 0.50

    x = caput(prefix+'EraseStart.VAL', 1)
    print, 'Waiting for XRF to complete'
    collecting = 1
    count = 0
    while collecting eq 1 do begin
       wait, 1.0
       count = count + 1.0
       s = caget(prefix+'Acquiring', collecting)
       if (count gt t + 30.0) then begin
           collecting = 1 
           print, 'timed out waiting for "Done".'
       endif
    endwhile

    med_file = pos + '_xrf.000'
    med_file =increment_scanname(med_file, /newfile)
    print, 'writing med file to : ', med_file
    med->write_file, med_file
    obj_destroy, med
    return
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro scan_at, pos=pos, scan=scan, number=number
   x = caput('13BMD:AbortScans.PROC',1)
   move_stage, position=pos
   wait, 2.0
   index = 1
   datafile = pos+'_'+scan+'.'+string(format='(i3.3)',index)
   scanfile = scan+'.scn'

   on_ioerror, io_error
      openr, lx, datafile, /get_lun
      close, lx
      free_lun, lx
      datafile=increment_scanname(datafile,/newfile)
io_error:
    lx = 1 ; success
   do_scan, scan_file=scanfile,  datafile=datafile, number=number
return
end
;;--------------------------------------------------------;;

pro map_at, pos=pos, scan=scan
   x = caput('13BMD:AbortScans.PROC',1)
   move_stage, position=pos
   wait, 2.0
   datafile = scan+'_'+pos+ '.001'
   scanfile = scan+'.scn'

   on_ioerror, io_error
      openr, lx, datafile, /get_lun
      close, lx
      free_lun, lx
      datafile=increment_scanname(datafile,/newfile)
io_error:
    lx = 1 ; success
   do_map, scan_file=scanfile,  datafile=datafile
return
end


pro bmd_macros
  bmd_xrd_macros
   x = 'loaded bmd macros'
return
end
