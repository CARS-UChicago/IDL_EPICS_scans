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
   ; x = caput('13BMD:Unidig2Bo9.VAL', 1)
   open_shutter
return
end

pro close_beamstop
  ; x = caput('13BMD:Unidig2Bo9.VAL', 0)
  close_shutter
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


pro I1_distance , pos
   x = caput('13BMD:m84.VAL', pos)
return
end

pro Wait_for_I1
   wait_for_motor, '13BMD:m84.VAL', tmax=30
return
end

pro I1_in
   I1_distance, 0
return
end
pro I1_out
   I1_distance, 100.0
return
end

pro xrd_expose,t=t, name=name, i0=i0, ext=ext

    if keyword_set(t)     eq 0 then t   = 30
    if keyword_set(ext)   eq 0 then ext = 1
    if keyword_set(name)  eq 0 then name = 'sample'

    I1_out

    x = caget('13BMA:mono_pid1.VAL', i0_val)
    if keyword_set(i0) eq 0 then i0 = i0_val

    set_i0, i0
    x = caput('13BMA:mono_pid1.FBON', 1)

    print, 'closing shutter'
    close_shutter
    
    ni = string(ext, format='(i3.3)')

    ; turn off auto-shutter open
    x = caget('13BMA:BMDEnableShutter', bmdshutter_enable)
    x = caput('13BMA:BMDEnableShutter', 0)
    
    byte_name = bytarr(strlen(name) + 1)
    byte_name[0:strlen(name)-1] = byte(name)


    med_file = name + '_' + ni + '.mca'
    print, 'will write med file to : ', med_file
    x = caput('13MAR345_1:cam1:FileName',   byte_name)
    x = caput('13MAR345_1:cam1:FileNumber', ext)
    x = caput('13MAR345_1:cam1:AcquireTime', t)

    x = caput('dxpMercury:PresetReal', t)
    x = caput('dxpMercury:EraseAll',      1)
    x = caput('dxpMercury:PresetLive',    0)
    x = caput('dxpMercury:PresetMode', 1)
    x = caput('dxpMercury:CollectMode', 0)

    raise_shield
    med = obj_new('EPICS_MED', 'dxpMercury:', 4)
    wait, 2.0
    Wait_For_I1

    open_shutter
    x = caput('13MAR345_1:cam1:Acquire',1)
    x = caput('dxpMercury:EraseStart.VAL',1)

    print, 'Exposing ... '
    wait, t-5.0
    print, 'Waiting for Acquire to finish'
    time_remaining = 15.0
    while time_remaining gt 0.01 do begin
       s = caget('13MAR345_1:cam1:TimeRemaining_RBV', time_remaining)
       wait, 1.0
    endwhile
    close_shutter
    print, 'Exposure Done '
    lower_shield

    med_file = name + '_' + ni + '.mca'
    print, 'writing med file to : ', med_file
    med->write_file, med_file
    obj_destroy, med

    detstate = 1
    count = 0 
    max_wait=150
    print, 'waiting for detector scanning to finish'
    while detstate gt 0 do begin
       count  = count+1
       wait, 1.0
       s = caget('13MAR345_1:cam1:DetectorState_RBV', detstate)
       if count gt max_wait then detstate = 0
    endwhile

    print, 'Scanning Done'

    ; turn autoshuter back to original state
    x = caput('13BMA:BMDEnableShutter', bmdshutter_enable)
    x = caput('13BMA:mono_pid1.FBON', 1)
    open_shutter
return
end

pro xrd_at, pos=pos, t=t
   move_xyz, position=pos, xyz_file='xyz_autosave.ini'
   wait, 1.0
   xrd_expose,t=t, name=pos
   wait, 10.0
return
end

pro bmd_xrd_macros
   x = 'loaded bmd xrd macros'
return
end
