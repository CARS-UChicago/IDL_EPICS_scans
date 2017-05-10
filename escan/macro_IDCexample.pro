pro move_to_energy, energy=energy, $
                    id_offset=id_offset,$
                    id_harmonic=id_harmonic,$
                    mono_chi=mono_chi,$
                    mono_dtheta=mono_dtheta, $
                    table_height=table_height, $
                    table_x=table_x

if keyword_set(energy) eq 0 then begin
    print, 'must give energy to move to!!'
    return
endif

x = caput('13IDA:E:z2_track.VAL', 1)
x = caput('13IDA:E:y2_track.VAL', 1)
x = caput('13IDA:mono_pid1.FBON', 0)
x = caput('13IDA:DAC1_3.VAL', -1.0)
if keyword_set(id_harmonic) ne 0 then  x = caput('ID13:HarmonicValue', id_harmonic)
if keyword_set(id_offset)   ne 0 then  x = caput('13IDA:E:id_off.VAL', id_offset)

x = caput('13IDA:E:Energy.VAL', energy)

if keyword_set(mono_chi)    ne 0 then  x = caput('13IDA:m11', mono_chi)
if keyword_set(mono_dtheta) ne 0 then  x = caput('13IDA:m12', mono_dtheta)
if keyword_set(table_height) ne 0 then x = caput('13IDC:m6', table_height)
if keyword_set(table_x) ne 0 then x = caput('13IDC:XAS:t1.X', table_x)

wait,5.0
x = caput('13IDA:E:z2_track.VAL', 0)
x = caput('13IDA:E:y2_track.VAL', 0)
x = caput('13IDA:mono_pid1.FBON', 1)

return
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro set_i0, value
    x = caput('13IDA:mono_pid1.VAL', value)
return
end

pro wait_for_move, pv, tmax=tmax
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


pro set_i1amp_gain, sens,unit
 ; set i0 gain: sens
 steps = [1, 2, 5, 10, 20, 50, 100, 200, 500]
 units = ['pA/V', 'nA/V','uA/V', 'mA/V']

 sval = where(steps eq sens)
 uval = where(units eq unit)

 x = caput('13IDC:A2sens_num.VAL',     sval)
 x = caput('13IDC:A2sens_unit.VAL',     uval)
 if sval ge 3 then begin
    x = caput('13IDC:A2offset_unit.VAL',   uval)
    x = caput('13IDC:A2offset_num.VAL',   sval-3)
 endif else begin
    x = caput('13IDC:A2offset_unit.VAL',   uval-1)
    x = caput('13IDC:A2offset_num.VAL',   sval+6)
 endelse
 x = caput('13IDC:A2off_u_put.VAL',   110)
return
end


pro set_i0amp_gain, sens,unit
 ; set i0 gain: sens
 steps = [1, 2, 5, 10, 20, 50, 100, 200, 500]
 units = ['pA/V', 'nA/V','uA/V', 'mA/V']

 sval = where(steps eq sens)
 uval = where(units eq unit)

 x = caput('13IDC:A1sens_num.VAL',     sval)
 x = caput('13IDC:A1sens_unit.VAL',     uval)
 if sval ge 3 then begin
    x = caput('13IDC:A1offset_unit.VAL',   uval)
    x = caput('13IDC:A1offset_num.VAL',   sval-3)
 endif else begin
    x = caput('13IDC:A1offset_unit.VAL',   uval-1)
    x = caput('13IDC:A1offset_num.VAL',   sval+6)
 endelse
 x = caput('13IDC:A1off_u_put.VAL',   110)
return
end



pro set_preslit_gain, sens,unit
 ; set i0 gain: sens
 steps = [1, 2, 5, 10, 20, 50, 100, 200, 500]
 units = ['pA/V', 'nA/V','uA/V', 'mA/V']

 sval = where(steps eq sens)
 uval = where(units eq unit)

 x = caput('13IDC:A3sens_num.VAL',      sval)
 x = caput('13IDC:A3sens_unit.VAL',     uval)
 x = caput('13IDC:A4sens_num.VAL',      sval)
 x = caput('13IDC:A4sens_unit.VAL',     uval)
 if sval ge 3 then begin
    x = caput('13IDC:A3offset_unit.VAL',   uval)
    x = caput('13IDC:A3offset_num.VAL',    sval-3)
    x = caput('13IDC:A4offset_unit.VAL',   uval)
    x = caput('13IDC:A4offset_num.VAL',    sval-3)
 endif else begin
    x = caput('13IDC:A3offset_unit.VAL',   uval-1)
    x = caput('13IDC:A3offset_num.VAL',    sval+6)
    x = caput('13IDC:A4offset_unit.VAL',   uval-1)
    x = caput('13IDC:A4offset_num.VAL',    sval+6)
 endelse
 x = caput('13IDC:A3off_u_put.VAL',   110)
 x = caput('13IDC:A4off_u_put.VAL',   110)
return
end

pro detector_distance , pos
   x = caput('13IDC:m15.VAL', pos)
return
end

pro filter_in
   x = caput('13IDC:m7.VAL', 15)
   x = caput('13IDC:m83.VAL', 1000)
   wait_for_move, '13IDC:m83.VAL', tmax=300
   x = caput('13IDC:m7.VAL', 0)
   wait_for_move, '13IDC:m7.VAL', tmax=300
return
end


pro filter_out
   x = caput('13IDC:m7.VAL', 15)
   x = caput('13IDC:m83.VAL', 15000)
   wait_for_move, '13IDC:m83.VAL', tmax=300
   x = caput('13IDC:m7.VAL', 0)
   wait_for_move, '13IDC:m7.VAL', tmax=300
return
end


pro move_to_pb
move_to_energy, energy=13100.0, $
                id_offset=0.140,$
                id_harmonic=3,$
                mono_chi=-0.025, $
                mono_dtheta=-0.063, $
                table_height=23.200, table_x = 1.70


set_i0amp_gain, 200, 'nA/V'
set_i0, 30.0
adjust_mono_tilt
return
end


pro move_to_xrd
move_to_energy, energy=18000.0, $
                id_offset=0.140,$
                id_harmonic=3,$
                mono_chi=-0.0370, $
                mono_dtheta=-0.074, $
                table_height=23.200, table_x = 1.70


set_i0amp_gain, 200, 'nA/V'
set_i0, 20.0
adjust_mono_tilt
return
end

pro move_to_map
   move_to_xrd
return
end


pro move_coarse, x, y
    rx = caput('13XRM:m4.VAL', x)
    ry = caput('13XRM:m6.VAL', y)
return
end

pro move_fine, x, y
    rx = caput('13XRM:m1.VAL', x)
    ry = caput('13XRM:m2.VAL', y)
return
end

pro move_to_spot, x, y
    rx = caput('13XRM:m1.VAL', x)
    ry = caput('13XRM:m2.VAL', y)
return
end

pro zeroscan_motors
   x = caput('13XRM:m1.VAL', 0.)
   x = caput('13XRM:m2.VAL', 0.)
return
end


pro detector_out
   x = caput('13IDC:m7.VAL', 20.0)
   wait, 2.0
return
end


pro detector_in
   x = caput('13IDC:m7.VAL', 0.0)
   wait, 2.0
return
end

pro detector_in2
   x = caput('13IDC:m7.VAL', 10.0)
   wait, 2.0
return
end

pro close_shutter
   x = caput('13IDC:m82.VAL', 1000.0)
   wait, 2.0
return
end
pro open_shutter
   x = caput('13IDC:m82.VAL', 0.0)
   wait, 2.0
return
end

pro expose,t=t,i0=i0, name=name, index=index
    if keyword_set(t)    eq 0 then t = 30
    if keyword_set(name) eq 0 then name  = 'bob'
    if keyword_set(index) eq 0 then index = 1
    xtime = t
    x = caget('13IDA:mono_pid1.VAL', i0_val)
    if keyword_set(i0) ne 0 then begin
      set_i0, i0
      wait, 3.0
    endif
    x = caput('13MARCCD2:det1:FileTemplate', name)
    x = caput('13MARCCD2:det1:SeqNumber', index)
    x = caput('13MARCCD2:det1:Seconds', xtime)

    x = caput('13XRM:XRF:filebase', byte(name))
    x = caput('13XRM:XRF:fileext', strtrim(string(index),2))
    x = caput('13SDD1:PresetReal', xtime)
    open_shutter
    x = caput('13MARCCD2:det1:AcquireCLBK', 1)
    x = caput('13XRM:XRF:Request', 1)

    collecting =1
    xtmax = 100
    count = 0
    poll_time = xtime*0.1
    wait, xtime/4.0
    while collecting eq 1 do begin
        s = caget('13MARCCD2:det1:AcquireCLBK', det_state)
        if det_state eq 0    then collecting = 0
        if count ge xtmax    then collecting = 0
        count  = count+1
        wait, poll_time
    endwhile
	print, 'done!'
    wait, 2.0
    open_shutter
return
end

pro save_xrf, t=t, name=name, index=index
    if keyword_set(t)    eq 0 then t = 30
    if keyword_set(name) eq 0 then name  = 'bob'
    if keyword_set(index) eq 0 then index = 1
    xtime = t
 
    x = caput('13XRM:XRF:filebase', byte(name))
    x = caput('13XRM:XRF:fileext',  strtrim(string(index),2))
    x = caput('dxpMercury:PresetReal', xtime)

    x = caput('13XRM:XRF:Request', 1)

    det_on = 0
    while det_on ne 1 do begin
        wait, 1.0
        s = caget('dxpMercury:Acquiring', det_on)
    endwhile
    wait, 2.0
    while det_on ne 0 do begin
        wait, 1.0
        s = caget('dxpMercury:Acquiring', det_on)
    endwhile
    wait, 2.0
    xrf_status = 1
    while xrf_status ne 0 do begin
        wait, 1.0
        s = caget('13XRM:XRF:Status', xrf_status)
    endwhile
return
end


pro position_scan, pos=pos, scanfile=scanfile, datafile=datafile, number=number
   move_xyz, position=pos, xyz_file='xyz_autosave.ini'
   wait, 15.0
   do_scan, scan_file=scanfile,  datafile=datafile, number=number

return
end

pro scan_at, x=x,y=y, name=name, scan=scan, number=number
   move_to_spot, x, y
   index = 1
   datafile = name + '_' + scan+ '.'+string(format='(i3.3)',index)
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


pro pos_scan, pos=pos, scan=scan, number=number
   move_xyz, position=pos, xyz_file='xyz_autosave.ini'
   wait, 2.0
   index = 1
   datafile = scan+'_'+pos+ '.'+string(format='(i3.3)',index)
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

;;
;; MAP AT
;;
pro map_at, pos=pos, scan=scan
   x = caput('13IDC:AbortScans.PROC',1)

   move_xyz, position=pos
   wait, 2.0
   index = 1
   datafile = scan+'_'+pos+ '.'+string(format='(i3.3)',index)
   scanfile = scan+'.scn'

   on_ioerror, io_error
      openr, lx, datafile, /get_lun
      close, lx
      free_lun, lx
      datafile=increment_scanname(datafile,/newfile)
io_error:
    lx = 1 ; success
   do_map, scan_file=scanfile,  datafile=datafile
   move_to_spot, 0.0, 0.0
return
end

;;--------------------------------------------------------;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


pro macro

;;; comment character is ;

;; move_to_cd
;; scan_at, x=-0.030,y=0.036, name='Spot1', scan=cd_xanes, number=5
;; scan_at, x=-0.030,y=0.036, name='Spot1', scan=cd_xanes, number=5
;; scan_at, x=-0.030,y=0.036, name='Spot1', scan=cd_xanes, number=5

;; move_to_spot, 0.040, -0.04


;; expose, t=30, name='AcidX_Spot1'


;; move_to_map
;; map_at, pos='acid_no_kso4', scan='map_200'
;; map_at, pos='acid_2mM_kso4', scan='map_200'

;; move_to_pb

;; detector_in2
;; pos_scan, name='su078_area1_spot2', scan='pb_xafs', number=6
;; pos_scan, name='su078_area2_spot4', scan='pb_xafs', number=6
;; pos_scan, name='su078_area2_spot5', scan='pb_xafs', number=6
;; pos_scan, name='tb020_area1_spot10', scan='pb_xafs', number=6


;; detector_out
;; pos_scan, name='tb020_area1_spot5', scan='pb_xafs', number=6
;; pos_scan, name='su078_area1_spot3', scan='pb_xafs', number=6
;; pos_scan, name='su078_area1_spot7', scan='pb_xafs', number=6
;; pos_scan, name='su078_area1_spot9', scan='pb_xafs', number=6
;; pos_scan, name='su078_area1_spot10b', scan='pb_xafs', number=6


;map_at, pos='su078_area1', scan='map_2mm_scan1'
;map_at, pos='su078_area2', scan='map_2mm_scan2'
;map_at, pos='tb020_area1', scan='map_2mm_scan3'
;map_at, pos='tb020_area2', scan='map_2mm_scan4'

return
end
