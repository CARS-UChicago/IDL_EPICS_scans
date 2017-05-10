
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

 tc = tc0 + (-50)* coarse_delta
 tcbest = tc
 x = caput(tilt_coarse, tc)
 wait, 0.5
 imax = 0
 for i = 0, 99 do begin
    tc = tc0 + (i-50)* coarse_delta
    x = caput(tilt_coarse, tc)
    wait, 0.05
    x = caget(i_actual, ix)
    if (ix gt imax) then begin
        imax = ix
        tcbest = tc
    endif
endfor

; set coarse tilt to near best setting
x = caput(tilt_coarse, (tcbest+ 1 * coarse_delta)-0.002 )

x = caget(i_setpoint,  iset)
if (imax lt iset) then begin
   print, ' max intensity below setpoint!! '
endif

x = caput(i_fbon,1)
x = caput(i_reset,1)

print, ' found max, now waiting for lock at setpoint ', iset

wait_for_i0_lock

s = caget(i_locked, islocked)
if ((islocked eq 0)) then begin
    print, ' Feedback not locked '
    return
endif

s = caget(tilt_fine, fval)
if ((islocked eq 1) and (abs(fval) lt 2)) then begin
    print, ' Tilt Value OK '
    return
endif

; adjust fine piezo  until
sign = 1
if fval gt 0 then sign = -1

print, ' tweaking tilt ' , sign
ok = 0
count = 0
while ok eq 0 do begin
    count = count + 1
    x = caget(tilt_coarse, tcval)
    x = caput(tilt_coarse, tcval+sign*coarse_delta)
    print, 'set mono tilt to ' , tcval, sign
    wait, 0.10
    wait_for_i0_lock

    s = caget(tilt_fine, fval)
    if (count ge 10 or (abs(fval) lt 2)) then ok = 1
endwhile


print, ' mono tilt set.'
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

pro move_to_mn, i0=i0
 move_to_energy, 6600.0, i0=i0
return
end

pro move_to_fe, i0=i0
 move_to_energy, 7200.0, i0=i0
return
end

pro move_to_zn, i0=i0
 move_to_energy, 9700.0, i0=i0
return
end


pro move_to_as, i0=i0
 move_to_energy, 11900.0, i0=i0
return
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro scan_at, pos=pos, scan=scan, number=number
   x = caput('13BMD:AbortScans.PROC',1)
   move_xyz, position=pos, xyz_file='xyz_autosave.ini'
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
   move_xyz, position=pos, xyz_file='xyz_autosave.ini'
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


pro lower_shield
  x = caput('13BMD:Unidig2Bo10', 1)
return
end

pro raise_shield
  x = caput('13BMD:Unidig2Bo10', 0)
return
end
pro open_beamstop
   x = caput('13BMD:Unidig2Bo9.VAL', 1)
return
end

pro close_beamstop
   x = caput('13BMD:Unidig2Bo9.VAL', 0)
return
end

pro open_shutter
   x = caput('13BMA:BMDEnableShutter', 1)
   x = caput('13BMA:OpenBMDShutter.PROC', 1)
return
end

pro close_shutter
   x = caput('13BMA:BMDEnableShutter', 0)
   x = caput('13BMA:CloseBMDShutter.PROC', 1)
return
end



pro xrd_expose,t=t, name=name, i0=i0, ext=ext
    if keyword_set(t)     eq 0 then t   = 30
    if keyword_set(ext)   eq 0 then ext = 1
    if keyword_set(name)  eq 0 then name = 'sample'


    x = caget('13BMA:mono_pid1.VAL', i0_val)
    if keyword_set(i0) eq 0 then i0 = i0_val

    set_i0, i0
    x = caput('13BMA:mono_pid1.FBON', 0)
    wait, 1.0

    ni = string(ext, format='(i3.3)')

    ; turn off auto-shutter open
    x = caget('13BMA:BMDEnableShutter', bmdshutter_enable)
    x = caput('13BMA:BMDEnableShutter', 0)
    
    byte_name = bytarr(strlen(name) + 1)
    byte_name[0:strlen(name)-1] = byte(name)

    x = caput('13MAR345_1:cam1:FileName',   byte_name)
    x = caput('13MAR345_1:cam1:FileNumber', ext)
    x = caput('13MAR345_1:cam1:AcquireTime', t)
    ;x = caput('13GE2:med:PresetReal', t)

    print, 'closing beamstop'
    close_beamstop
    wait, 0.5
    raise_shield

    ;med = obj_new('EPICS_MED', '13GE2:med:')
    wait, 5.0

    x = caput('13MAR345_1:cam1:Acquire',1)
    ;x = caput('13GE2:med:EraseStart.VAL',1)

    count = 0
    collecting = 1
    max_count  = t + 180  ; wait up to 3 minutes more than collection time
    while collecting eq 1 do begin
       s = caget('13MAR345_1:cam1:DetectorState_RBV', collecting)
       count  = count+1
       wait, 1.0
       if count gt max_count then collecting = 0
    endwhile
    print, 'Collection Done ', t, count
    lower_shield

    ;med_file = name + '_' + ni + '.mca'
    ;med->write_file, med_file
    ;obj_destroy, med

    wait,5.0

    ; turn autoshuter back to original state
    x = caput('13BMA:BMDEnableShutter', bmdshutter_enable)
    x = caput('13BMA:mono_pid1.FBON', 1)
    open_beamstop
return
end

pro xrd_at, pos=pos, t=t
   move_xyz, position=pos, xyz_file='xyz_autosave.ini'
   wait, 1.0
   xrd_expose,t=t, name=pos
   wait, 10.0
return
end


pro bmd_macros
   x = 'loaded bmd macros'
return
end
