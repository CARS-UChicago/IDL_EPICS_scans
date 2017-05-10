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
    x = caput(amppv + 'off_u_put.VAL',     110)
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


pro gse_macros
   print, 'loaded GSECARS macros'
return
end
