function update_scan_settings, w, sc, i
;  update the start, stop, step, npts settings for a scan segments
; 
   sc.npts[i]   = npts_calc(sc.start[i],sc.stop[i],sc.step[i],step_out)
   sc.step[i]   = step_out
   Widget_Control, w.start[i], set_value = f2a(sc.start[i])
   Widget_Control, w.stop[i],  set_value = f2a(sc.stop[i] )
   Widget_Control, w.step[i],  set_value = f2a(sc.step[i] )
   Widget_Control, w.npts[i],  set_value = f2a(sc.npts[i] )
return, sc
end

function set_sensitive_regions, w, nregs
;
;  set sensitivity of scan segment regions
;
; print, ' Set Sensitive Regions ', w, nregs
if (nregs gt 1) then begin
    for i = 0, nregs-1 do begin
        Widget_Control, w.start[i],  SENSITIVE = 1
        Widget_Control, w.stop[i],   SENSITIVE = 1
        Widget_Control, w.step[i],   SENSITIVE = 1
        Widget_Control, w.npts[i],   SENSITIVE = 1
        Widget_Control, w.time[i],   SENSITIVE = 1
        Widget_Control, w.units[i],  SENSITIVE = 1
    endfor
endif
for i = nregs, 2 do begin
    Widget_Control, w.start[i],  SENSITIVE = 0
    Widget_Control, w.stop[i],   SENSITIVE = 0
    Widget_Control, w.step[i],   SENSITIVE = 0
    Widget_Control, w.npts[i],   SENSITIVE = 0
    Widget_Control, w.time[i],   SENSITIVE = 0
    Widget_Control, w.units[i],  SENSITIVE = 0
endfor

return,0
end

function check_motor_limits, pos, is_rel, motor
;
; check that a motor position is within motor limits, 
; includes 'relative position'
;
; returns a value for the position that is within motor limits
out = pos
abs = out
if (is_rel) then abs = abs  + motor.curpos
if ((abs < motor.llim) or (abs > motor.hlim)) then begin
    out = abs > motor.llim < motor.hlim
    if (is_rel)  then out = out  - motor.curpos
endif 
return, out
end
;


pro exafs_event, event
@scan_include
Widget_Control, event.id,  get_uval = uval
; print, ' exafs_event: scan = <',_scan,'>  uval = ', uval
wid     = (*p).escan
case uval of
    'e0': begin
        Widget_Control, wid.e0, get_value = t
        sc.params[0] = strtrim(t,2)
    end
    'nregs': begin
        Widget_Control, wid.nregs, get_value = t
        nregs =  ((fix(strtrim(t[0],2)) > 1) < 3)
        Widget_Control, wid.nregs, set_value = f2a(nregs)
        sc.n_regions = nregs
        u  = (*p).es->set_param(_scan, sc)
        u  = set_sensitive_regions(wid,nregs)
    end
    'use_rel': begin
        do_change = 0
        dx        = sc.params[0]
        if ((event.index eq 1) and (sc.is_rel eq 0)) then begin ;
            do_change = 1
            sc.is_rel = 1
            dx        = -dx
        endif else if ((event.index eq 0) and (sc.is_rel eq 1)) then begin
            do_change = 1
            sc.is_rel = 0
        endif 
        if (do_change eq 1) then begin
            for i = 0, 2 do begin
                if (sc.is_kspace[i] eq 0) then begin
                    sc.start[i] = sc.start[i] + dx
                    sc.stop[i]  = sc.stop[i]  + dx
                    sc          = update_scan_settings(wid, sc, i)
                endif
            endfor
        endif
    end
    'cur_pos': begin
    end
    'start0': begin
        Widget_Control, wid.start[0], get_value = t
        sc.start[0] = a2f(t)
        sc          = update_scan_settings( wid, sc, 0)
    end
    'stop0': begin
        Widget_Control, wid.stop[0],  get_value = t
        sc.stop[0]  = a2f(t)
        sc          = update_scan_settings(wid, sc, 0)
        sc.start[1] = sc.stop[0]
        sc          = update_scan_settings(wid, sc, 1)
    end
    'step0': begin
        Widget_Control, wid.step[0],  get_value = t
        sc.step[0]  = a2f(t)
        sc          = update_scan_settings(wid, sc, 0)
    end
    'start1': begin
        Widget_Control, wid.start[1], get_value = t
        sc.start[1] = a2f(t)
        sc          = update_scan_settings(wid, sc, 1)
        sc.stop[0]  = sc.start[1]
        sc          = update_scan_settings(wid, sc, 0)
    end
    'stop1': begin
        Widget_Control, wid.stop[1],  get_value = t
        sc.stop[1]  = a2f(t)
        sc          = update_scan_settings(wid, sc, 1)
        sc.start[2] = sc.stop[1]
;        print, ' is_kspace, is_rel = ', sc.is_kspace[2], sc.is_rel
        if (sc.is_kspace[2] eq 1) then begin
            if (sc.is_rel eq 0) then sc.start[2] = (sc.start[2] - sc.params[0])>0
            sc.start[2] = sqrt(sc.start[2] * ETOK)
        endif
        ; print, ' sc.start[2]= ', sc.start[2]
        sc          = update_scan_settings(wid, sc, 2)
    end
    'step1': begin
        Widget_Control, wid.step[1],  get_value = t
        sc.step[1]  = a2f(t)
        sc          = update_scan_settings(wid, sc, 1)
    end
    'start2': begin
        Widget_Control, wid.start[2], get_value = t
        sc.start[2] = a2f(t)
        sc          = update_scan_settings(wid, sc, 2)
        sc.stop[1]  = sc.start[2]
        if (sc.is_kspace[2] eq 1) then begin
            if (sc.is_rel eq 0) then sc.stop[2] = (sc.stop[2] - sc.params[0])>0
            sc.stop[1] = sc.stop[1] * sc.stop[1] / ETOK
        endif 
        sc          = update_scan_settings(wid, sc, 1)
    end
    'stop2': begin
        Widget_Control, wid.stop[2],  get_value = t
        sc.stop[2]  = a2f(t)
        sc          = update_scan_settings(wid, sc, 2)
    end
    'step2': begin
        Widget_Control, wid.step[2], get_value = t
        sc.step[2]  = a2f(t)
        sc          = update_scan_settings(wid, sc, 2)
    end
    'npts0': begin
        Widget_Control, wid.npts[0], get_value = t
        sc.npts[0] = ((fix(strtrim(t,2)) > 2) <  MAX_SCAN_POINTS)
        sc.step[0] = (sc.start[0] - sc.stop[0])/(sc.npts[0]-1)
        sc         = update_scan_settings(wid, sc, 0)
    end
    'npts1': begin
        Widget_Control, wid.npts[1], get_value = t
        sc.npts[1] = ((fix(strtrim(t,2)) > 2) <  MAX_SCAN_POINTS)
        sc.step[1] = (sc.start[1] - sc.stop[1])/(sc.npts[1]-1)
        sc         = update_scan_settings(wid, sc, 1)
    end
    'npts2': begin
        Widget_Control, wid.npts[2], get_value = t
        sc.npts[2] = ((fix(strtrim(t,2)) > 2) <  MAX_SCAN_POINTS)
        sc.step[2] = (sc.start[2] - sc.stop[2])/(sc.npts[2]-1)
        sc         = update_scan_settings(wid, sc, 2)
    end
    'time0': begin
        Widget_Control, wid.time[0], get_value = t
        sc.time[0] = a2f(t)
    end
    'time1': begin
        Widget_Control, wid.time[1], get_value = t
        sc.time[1] = a2f(t)
    end
    'time2': begin
        Widget_Control, wid.time[2], get_value = t
        sc.time[2] = a2f(t)
    end
    'units0': print, " K steps ?? No WAY! "
    'units1': print, " K steps ?? No WAY! "
    'units2': begin
        ; print, "kspace: ",  event.index
        if (event.index eq 1) then begin ;  choose 'Ang^-1'
            if (sc.is_kspace[2] eq 0) then begin ; switching from E to k space
                sc.is_kspace[2] = 1
                d = sc.start[2]
                if (sc.is_rel eq 0) then d = d - sc.params[0]
                sc.start[2] = sqrt(d * ETOK)
                d = sc.stop[2]
                if (sc.is_rel eq 0) then d = d - sc.params[0]
                sc.stop[2] = sqrt(d * ETOK)
                sc.step[2] = 0.05
            endif
        endif else begin;  choose 'eV'
            if (sc.is_kspace[2] eq 1) then begin ;  switching from k to E space
                sc.is_kspace[2] = 0
                d = sc.start[2] * sc.start[2] / ETOK
                if (sc.is_rel eq 0) then d = d + sc.params[0]
                sc.start[2] = d
                d = sc.stop[2] * sc.stop[2] / ETOK
                if (sc.is_rel eq 0) then d = d + sc.params[0]
                sc.stop[2] = d
                sc.step[2] = 2.0
            endif
        endelse
        sc         = update_scan_settings(wid, sc, 2)
    end
    else: print, 'exafs_event: unknown!', uval
endcase
u = (*p).es->set_param(_scan, sc)
return
end

pro motor_event, event
@scan_include
Widget_Control, event.id,  get_uval = uval

wid  = (*p).mscan

case uval of
    'use_rel': begin
        do_change = 0
        dx        = motor.curpos
        if ((event.index eq 1) and (sc.is_rel eq 0)) then begin ;
            sc.is_rel = 1
            do_change = 1
            dx        = -dx
        endif else if ((event.index eq 0) and (sc.is_rel eq 1)) then begin
            do_change = 1
            sc.is_rel = 0
        endif 
        if (do_change eq 1) then begin
            for i = 0, 2 do begin
                sc.start[i] = sc.start[i] + dx
                sc.stop[i]  = sc.stop[i]  + dx
                sc          = update_scan_settings(wid, sc, i)
            endfor
        endif
    end
    'nregs': begin
        Widget_Control, wid.nregs, get_value = t
        nregs =  ((fix(strtrim(t[0],2)) > 1) < 3)
        Widget_Control, wid.nregs, set_value = f2a(nregs)
        sc.n_regions = nregs
        u  = (*p).es->set_param(_scan, sc)
        u  = set_sensitive_regions(wid,nregs)
    end
    'motor_name': begin
        motor  = (*p).es->get_motor(event.index)
        sc.drives[0] = event.index
        sc.start[0]  = check_motor_limits(sc.start[0],sc.is_rel,motor)
        sc.stop[0]   = check_motor_limits(sc.stop[0], sc.is_rel,motor)
        sc = update_scan_settings(wid, sc, 0)
        Widget_Control, wid.llim,    set_value = f2a(motor.llim)
        Widget_Control, wid.hlim,    set_value = f2a(motor.hlim)
        Widget_Control, wid.cur_pos, set_value = f2a(motor.curpos)
    end
    'cur_pos': begin
        Widget_Control, wid.cur_pos, get_value = cur
        val  = a2f(cur)
        rbv  = motor.rbv
        pv   = strtrim(motor.pv,2)
        ilen = strlen(pv)
        if (strupcase(strmid(pv,ilen-4,4)) eq '.VAL') then pv = strmid(pv,0,ilen-4)
        if ((val le motor.hlim)  and (val ge motor.llim)) then begin
            s    = caput(pv + '.VAL', val)
            dmov = 0
            while (dmov eq 0) do begin
                s = caget(pv + '.DMOV', dmov)
                s = caget(rbv, val)
                Widget_Control, wid.cur_pos, set_value = f2a(val)
            endwhile
            motor.curpos = val
            u  = (*p).es->set_motor(imotor, motor)
        endif else begin
            print, ' requested position is outside limits'
        endelse
    end
    'time0': begin
        Widget_Control, wid.time[0], get_value = t
        sc.time[0] = a2f(t)
    end
    'start0': begin
        Widget_Control, wid.start[0], get_value = t
        start = a2f(t)
        sc.start[0] = check_motor_limits(start,sc.is_rel,motor)
        sc    = update_scan_settings( wid, sc, 0)
    end
    'stop0': begin
        Widget_Control, wid.stop[0], get_value = t
        stop        = a2f(t)
        sc.stop[0]  = check_motor_limits(stop,sc.is_rel,motor)
        sc          = update_scan_settings( wid, sc, 0)
        sc.start[1] = sc.stop[0]
        sc          = update_scan_settings(wid, sc, 1)
    end
    'step0': begin
        Widget_Control, wid.step[0], get_value = t
        sc.step[0] = a2f(t)
        sc = update_scan_settings( wid, sc, 0)
    end
    'npts0': begin
        Widget_Control, wid.npts[0], get_value = t
        sc.npts[0] = (( fix(strtrim(t,2)) > 2) < MAX_SCAN_POINTS)
        sc.step[0] = (sc.start[0] - sc.stop[0])/(sc.npts[0]  - 1)
        sc = update_scan_settings( wid, sc, 0)
    end
;
    'time1': begin
        Widget_Control, wid.time[1], get_value = t
        sc.time[1] = a2f(t)
    end
    'start1': begin
        Widget_Control, wid.start[1], get_value = t
        start       = a2f(t)
        sc.start[1] = check_motor_limits(start,sc.is_rel,motor)
        sc          = update_scan_settings(wid, sc, 1)
        sc.stop[0]  = sc.start[1]
        sc          = update_scan_settings(wid, sc, 0)
    end
    'stop1': begin
        Widget_Control, wid.stop[1], get_value = t
        stop        = a2f(t)
        sc.stop[1]  = check_motor_limits(stop,sc.is_rel,motor)
        sc          = update_scan_settings( wid, sc, 1)
        sc.start[2] = sc.stop[1]
        sc          = update_scan_settings(wid, sc, 2)
    end
    'step1': begin
        Widget_Control, wid.step[1], get_value = t
        sc.step[1] = a2f(t)
        sc = update_scan_settings( wid, sc, 1)
    end
    'npts1': begin
        Widget_Control, wid.npts[1], get_value = t
        sc.npts[1] = (( fix(strtrim(t,2)) > 2) < MAX_SCAN_POINTS)
        sc.step[1] = (sc.start[1] - sc.stop[1])/(sc.npts[1]  - 1)
        sc = update_scan_settings( wid, sc, 1)
    end
;
    'time2': begin
        Widget_Control, wid.time[2], get_value = t
        sc.time[2] = a2f(t)
    end
    'start2': begin
        Widget_Control, wid.start[2], get_value = t
        start       = a2f(t)
        sc.start[2] = check_motor_limits(start,sc.is_rel,motor)
        sc          = update_scan_settings( wid, sc, 2)
        sc.stop[1]  = sc.start[2]
        sc          = update_scan_settings(wid, sc, 1)
    end
    'stop2': begin
        Widget_Control, wid.stop[2], get_value = t
        stop       = a2f(t)
        sc.stop[2] = check_motor_limits(stop,sc.is_rel,motor)
        sc = update_scan_settings( wid, sc, 2)
    end
    'step2': begin
        Widget_Control, wid.step[2], get_value = t
        sc.step[2] = a2f(t)
        sc = update_scan_settings( wid, sc, 2)
        ; print, ' motor step2 == ', sc.step[2], sc.npts[2]
    end
    'npts2': begin
        Widget_Control, wid.npts[2], get_value = t
        sc.npts[2] = (( fix(strtrim(t,2)) > 2) < MAX_SCAN_POINTS)
        sc.step[2] = (sc.start[2] - sc.stop[2])/(sc.npts[2]  - 1.00)
        sc = update_scan_settings( wid, sc, 2)
    end
    'units': x = 1
    'llim': x = 1
    'hlim': x = 1
    else: print, 'motor_event: unknown!'
endcase
u =  (*p).es->set_param(_scan, sc)
return
end


pro escan_fill_screen, p
;
; fill in escan screens from  data structure
; 
print, 'escan_fill '
cur_dim    = (*p).es->get_param('dimension')
cur_scan   = (*p).es->get_param('current_scan')
allmotors  = (*p).es->get_param('motors')
_scan      = 'scan' + string(strtrim(cur_scan, 2))
sc         = (*p).es->get_param(_scan)
imotor     = sc.drives[0]
motor      = (*p).es->get_motor(imotor)   
cur_type   = 0
wid        = (*p).mscan

if (strlowcase(sc.type) eq 'exafs') then begin
    wid        = (*p).escan
    cur_type = 1
endif
cur_scan = cur_scan-1
Widget_Control, (*p).form.scan_num,  set_droplist_select = cur_scan
Widget_Control, (*p).form.scan_dim,  set_droplist_select = cur_dim-1
Widget_Control, (*p).form.scan_type, set_droplist_select = cur_type

; print, ' cur_scan = ', cur_scan
x_start = (*p).es->get_scan_param(cur_scan, 'start')
x_stop  = (*p).es->get_scan_param(cur_scan, 'stop')
x_step  = (*p).es->get_scan_param(cur_scan, 'step')
x_npts  = (*p).es->get_scan_param(cur_scan, 'npts')
x_time  = (*p).es->get_scan_param(cur_scan, 'time')
x_isk   = (*p).es->get_scan_param(cur_scan, 'is_kspace')

; for i = 0, 2 do begin
;     x_   = (*p).es->get_scan_param(i, 'is_kspace')
;     print, ' IS K-SPACE ', i, x_
; endfor

Widget_Control, wid.nregs,        set_value = f2a(sc.n_regions)
Widget_Control, wid.is_rel,       set_DROPLIST_SELECT = sc.is_rel
m_names = allmotors.name
Widget_Control, (*p).mscan.motor, set_value =m_names

for i = 0, 2 do begin
    Widget_Control, wid.start[i], set_value=f2a(x_start[i,0])
    Widget_Control, wid.stop[i],  set_value=f2a(x_stop[i,0])
    Widget_Control, wid.step[i],  set_value=f2a(x_step[i,0])
    Widget_Control, wid.npts[i],  set_value=f2a(x_npts[i,0])
    Widget_Control, wid.time[i],  set_value=f2a(x_time[i,0])
endfor
if (cur_type eq 0) then begin
    Widget_Control, (*p).mscan.motor,    set_DROPLIST_SELECT= sc.drives[0]
    Widget_Control, (*p).mscan.is_rel,   set_DROPLIST_SELECT= sc.is_rel
    Widget_Control, (*p).mscan.cur_pos,  set_value= f2a(motor.curpos)
    Widget_Control, (*p).mscan.hlim,     set_value= f2a(motor.hlim)
    Widget_Control, (*p).mscan.llim,     set_value= f2a(motor.llim)
    Widget_Control, (*p).form.nb[1], map=0
    Widget_Control, (*p).form.nb[0], map=1
endif else  begin
    Widget_Control, (*p).escan.e0,       set_value = f2a(sc.params[0])
    Widget_Control, (*p).form.nb[0], map=0
    Widget_Control, (*p).form.nb[1], map=1
    Widget_Control, (*p).escan.units[2], SET_DROPLIST_SELECT = x_isk[2]
endelse

for i = 0, 2 do  sc  = update_scan_settings(wid, sc, i)
u   = (*p).es->set_param(_scan, sc)
u   = set_sensitive_regions(wid,  sc.n_regions)

return
end

;
pro escan_event, event
;
@scan_include
Widget_Control, event.id,  get_uval = uval

if (strupcase(strtrim(sc.type,2)) eq 'EXAFS') then begin
    scan_type = 1
    wid  = (*p).escan
endif else begin
    scan_type = 0
    wid  = (*p).mscan
endelse

; print, 'escan_event uval = ', uval

case uval of
    'exit':   Widget_Control, event.top, /destroy
    'save_params':   retval =  (*p).es->save_paramfile(/use_dialog)
    'saveas_params': retval =  (*p).es->save_paramfile(/use_dialog)
    'read_params': begin
        retval       = (*p).es->read_paramfile(/use_dialog)
        escan_fill_screen, p
    end
    'data_file_name': begin
        Widget_Control, (*p).form.data_file_name, get_value = t
        t =  strtrim(t[0],2)
        x = (*p).es->set_param('datafile',t)
    end
    'define_dets':  begin
        r  = define_detectors(p)
        d  = (*p).es->get_param('detectors')
        t  = ['','']
        for i = 0,  n_elements(d.countPV)- 1 do  begin
            if (strpos(d.countPV[i],'scaler') ne -1) then t[0]= 'scaler1.CNT'
            if (strpos(d.countPV[i],'med')    ne -1) then t[1]= 'med:Start.VAL'
        endfor
        x   = (*p).es->set_param('triggers',t)
    end
    'collect_offs': begin
        r  = collect_offsets(p)
    end
    'define_mots': begin
        motor = (*p).es->get_param('motors')
    end
    'setup': begin
        ; print , ' setup '
        r   = define_scan(p)
    end
    'scan_type': begin
        if (event.index eq 0) then begin
            Widget_Control, (*p).form.nb[1], map=0
            Widget_Control, (*p).form.nb[0], map=1
            Widget_Control, (*p).mscan.motor,   set_DROPLIST_SELECT = sc.drives[0]
            wid = (*p).mscan
            sc.type = 'Motor'
        endif else begin
            Widget_Control, (*p).form.nb[0], map=0
            Widget_Control, (*p).form.nb[1], map=1
            Widget_Control, (*p).escan.e0,  set_value = f2a(sc.params[0])
            wid = (*p).escan
            sc.type = 'EXAFS'
        endelse
        u = set_sensitive_regions(wid,  sc.n_regions)         
        Widget_Control, wid.nregs,  set_value = f2a(sc.n_regions)
        Widget_Control, wid.is_rel, set_DROPLIST_SELECT = sc.is_rel
        u   = (*p).es->set_param(_scan, sc)
        for i = 0, 2 do begin
            sc  = update_scan_settings(wid, sc, i)
        endfor
    end
    'scan_dim': begin
        u   = (*p).es->set_param('dimension', event.index+1)
    end
    'scan_num': begin
        current_scan  =  event.index + 1
        x      = (*p).es->set_param('current_scan', current_scan)
        _scan  = 'scan' + string(strtrim(current_scan,2))
        sc     = (*p).es->get_param(_scan)
        motor  = (*p).es->get_motor(sc.drives[0])   
        motor.curpos = (*p).es->get_motor_position(sc.drives[0])   
        pv     = motor.pv
        il     = strlen(pv)
        if (strupcase(strmid(pv,il-4,4)) eq '.VAL') then pv = strmid(pv,0,il-4)
        scan_type = 0
        wid       = (*p).mscan
        if (strupcase(strtrim(sc.type,2)) eq 'EXAFS') then begin
            scan_type = 1
            wid  = (*p).escan
        endif
           
        Widget_Control, (*p).form.nb[0], map=0
        Widget_Control, (*p).form.nb[1], map=0
        Widget_Control, (*p).form.nb[scan_type], map=1
        Widget_Control, (*p).form.scan_type,   set_DROPLIST_SELECT = scan_type
        Widget_Control, wid.nregs,        set_value = f2a(sc.n_regions)
        Widget_Control, wid.is_rel,       set_DROPLIST_SELECT = sc.is_rel
        for i = 0, 2 do begin
            sc  = update_scan_settings(wid, sc, i)
        endfor
        if (scan_type eq 0) then begin
            Widget_Control, wid.motor,    set_DROPLIST_SELECT= sc.drives[0]
            Widget_Control, wid.is_rel,   set_DROPLIST_SELECT= sc.is_rel
            Widget_Control, wid.cur_pos,  set_value= f2a(motor.curpos)
            Widget_Control, wid.hlim,     set_value= f2a(motor.hlim)
            Widget_Control, wid.llim,     set_value= f2a(motor.llim)
        endif else  begin
            Widget_Control, wid.e0,       set_value = f2a(sc.params[0])
        endelse
        u = set_sensitive_regions(wid,  sc.n_regions)
    end
    'load': begin
        x   = (*p).es->load_to_crate()
        sc  = (*p).es->get_param(_scan)
        dim = (*p).es->get_param('dimension')
        tx   = fltarr(3)
        np   = intarr(3)+1
        for i = 0, dim-1 do begin
            x  = (*p).es->get_param('scan'+string(i+1,format='(i1.1)'))
            tx(i) = x.time_est
            np(i) = x.npts_total
        endfor
        total_time = tx(2) + np(2) * ( tx(1) +  np(1) * tx(0) ) 
        tm1 = sec2hms(total_time)
        print, 'time estimate: ', tm1
        widget_control, (*p).form.time_est, set_value = tm1
        x  = (*p).es->set_param('total_time',total_time)
    end
;    'scan_view': begin
;     scan_viewer, (*p).es 
;    end
    else: print , ' unknown event ', uval
endcase
return
end


;
;------------------------------------------------------------------
pro escan, scan_file=scan_file
;
;  
print, ' This is escan v 1.0'
N_SCAN_TYPES = 2
N_REG        = 5
scan_types   = ['Motor', 'EXAFS']
scan_nums    = ['Scan 1', 'Scan 2', 'Scan 3']
rel_choices  = ['Absolute', 'Relative']
scan_dims    = ['1', '2', '3']
cur_dim      = 0
;
; define and setup epics_scan object
s_file   = 'default.scn'
if (keyword_set(scan_file) ne 0 ) then s_file = scan_file
es       = obj_new('epics_scan', scan_file = s_file, /use_dialog)

datafile = es->get_param('datafile')
motor    = es->get_param('motors')
det      = es->get_param('detectors')

; cur_scan = es->get_param('current_scan')
cur_scan = 1

sc       = es->get_param('scan' + string(strtrim(cur_scan, 2)))
cur_dim  = es->get_param('dimension')

cur_scan = cur_scan - 1
m_names  = motor.name

drives   = es->get_scan_param(cur_scan, 'drives')
imot     = drives[0]
_motor   = es->get_motor(imot)
; if (imot eq motor.e_drive) then print, " driving Energy!!"
_energy  = es->get_motor(motor.e_drive)

cur_type = 0
cx_type  = es->get_scan_param(0, 'type')
if (cx_type eq scan_types[1]) then cur_type = 1
; print, '  scan type: ', cx_type , ' scan_types[1] = ', scan_types[1], cur_type

;--------------------------------------------------------------------------------
; nbframe holds the frame ids for the 2 'notebook frames'
nb     = lonarr(N_SCAN_TYPES)
arr0   = lonarr(N_REG)
form   = {scan_num:scan_nums[0], data_file_name:0L, time_est:0L, $
          scan_type:scan_types[0], scan_dim:scan_dims[0], $
          cur_dim:1L, nb:nb}
mscan  = {motor:m_names[0], cur_pos:0L,  llim:0L, hlim:0L, e0:0L,$
          nregs:1L,  is_rel:rel_choices[1], units:arr0, $
          start:arr0,  stop:arr0,  step:arr0,  npts:arr0, time:arr0}
escan  = {e0:0L,           cur_pos:0L, motor:0L, llim:0L, hlim:0L, $
          nregs:3L,  is_rel:rel_choices[1], units:arr0, $
          start:arr0,  stop:arr0,  step:arr0,  npts:arr0, time:arr0 }

info   = {es:es, form:form, mscan:mscan, escan:escan}
;-----------------------
; menus

main   = Widget_Base(title = 'Epics Scan Setup', /col, app_mbar = mbar)
;; Widget_Control, default_font='Fixedsys' 
menu   = Widget_Button(mbar, value= 'File')
x      = Widget_Button(menu, value= 'Read Scan File ...',  uval= 'read_params')
x      = Widget_Button(menu, value= 'Save Scan File ...',  uval= 'save_params')
x      = Widget_Button(menu, value= 'Save As ...',         uval= 'saveas_params')
x      = Widget_Button(menu, value= 'Exit',                uval= 'exit', /sep)

menu   = Widget_Button(mbar, value= 'Detectors')
x      = Widget_Button(menu, value= 'Setup ...',            uval= 'setup')
x      = Widget_Button(menu, value= 'Select Detectors ...', uval= 'define_dets') 
x      = Widget_Button(menu, value= 'Collect Offsets ...',  uval= 'collect_offs') 
; x      = Widget_Button(menu, value= 'Define Motors ...',    uval= 'define_mots') 

; menu   = Widget_Button(mbar, value= 'Help', /menu, /help)
; x      = Widget_Button(menu, value= 'Help on EPICS SCAN',  uval= 'escan_help')
; x      = Widget_Button(menu, value= 'Help on IDL',         uval= 'IDLhelp')
;-----------------------

mframe = Widget_Base(main,   /col)
fr0    = Widget_Base(mframe, /row, /frame)

info.form.scan_num = Widget_Droplist(fr0, value= scan_nums,  uval= 'scan_num', $
                                     title = ' ') 
info.form.scan_dim = Widget_Droplist(fr0, value= scan_dims,  uval= 'scan_dim', $
                                     title = ' of dimension ')
info.form.scan_type= Widget_Droplist(fr0, value= scan_types, uval= 'scan_type', $
                                     title = ' Type ')


Widget_Control, info.form.scan_num,  set_Droplist_SELECT = 0
Widget_Control, info.form.scan_dim,  set_Droplist_SELECT = cur_dim-1
Widget_Control, info.form.scan_type, set_Droplist_SELECT = cur_type


x_start = info.es->get_scan_param(0, 'start')
x_stop  = info.es->get_scan_param(0, 'stop')
x_step  = info.es->get_scan_param(0, 'step')
x_npts  = info.es->get_scan_param(0, 'npts')
x_time  = info.es->get_scan_param(0, 'time')

info.escan.nregs = info.es->get_scan_param(0, 'n_regions')



;
OptBase =  Widget_Base(mframe, /frame)
;-----------------------
; Motor Scan Frame:
info.form.nb[0] = Widget_Base(OptBase, /col, MAP = 0,event_pro='motor_event')
fr01        = Widget_Base(info.form.nb[0],  /row)
x           = Widget_Label(fr01, value = 'Motor')

info.mscan.motor = Widget_Droplist(fr01, value= m_names, uval= 'motor_name', $
                                   title = ' ')
Widget_Control, info.mscan.motor, set_Droplist_SELECT = imot

info.mscan.nregs = CW_FIELD(fr01, /INTEGER,  /ROW,   xsize=4, $
                            title = 'Number of Scan Regions', UVALUE = 'nregs', $
                            VALUE = f2a(info.mscan.nregs), $
                            /return_events)

info.mscan.is_rel = Widget_Droplist(fr01, value= rel_choices, uval= 'use_rel', $
                                    title = 'use ')
Widget_Control, info.mscan.is_rel, set_Droplist_SELECT = 1
x = Widget_Label(fr01,  value = 'Positions')

fr02  = Widget_Base(info.form.nb[0], /row )
info.mscan.cur_pos = CW_Field(fr02,   title = 'Current Position', $
                             xsize=11, uval = 'cur_pos', $
                             value = f2a(_motor.curpos), $
                             /return_events, /floating)

info.mscan.llim = CW_Field(fr02,  title = 'Limits : Low ', $
                          xsize = 11, uval = 'llim', /noedit, $
                          value = f2a(_motor.llim), $
                          /return_events, /floating)
info.mscan.hlim = CW_Field(fr02,  title = ' : High ', $
                           xsize = 11, uval = 'hlim', /noedit, $
                           value = f2a(_motor.hlim), $
                          /return_events, /floating)

fr03   = Widget_Base(info.form.nb[0], /col,/frame)
fr04   = Widget_Base(fr03, /row)
ts  = 85
X = Widget_Label(fr04, XSIZE=  ts,  VALUE = 'Region  ' )
X = Widget_Label(fr04, XSIZE=  ts,  VALUE = 'Start   ' )
X = Widget_Label(fr04, XSIZE=  ts,  VALUE = 'Stop    ' )
X = Widget_Label(fr04, XSIZE=  ts,  VALUE = 'Step    ' )
X = Widget_Label(fr04, XSIZE=  ts,  VALUE = 'Npts    ' )
X = Widget_Label(fr04, XSIZE=  ts,  VALUE = 'Time (s)')
X = Widget_Label(fr04, XSIZE=  ts,  VALUE = 'Units   ' )


reg_title = ['1', '2', '3', '4']
uv_       = ['start',  'stop', 'step', 'npts', 'time'] 
for i = 0, 2 do  begin
    fr05 = Widget_Base(fr03, /row)
    X    = Widget_Label(fr05,  XSIZE=80, VALUE = reg_title[i], /ALIGN_LEFT)
    uvs  = uv_ + strtrim(string(i),2)
    info.mscan.start[i] = CW_FIELD(fr05,  title= ' ', XSIZE = 9,  uvalue = uvs[0], $
                                   value = f2a(x_start[i,0]), $
                                   /return_events, /floating)
    info.mscan.stop[i]  = CW_FIELD(fr05,  title= ' ', XSIZE = 9,  uvalue = uvs[1], $
                                   value = f2a(x_stop[i,0]), $
                                   /return_events, /floating)
    info.mscan.step[i]  = CW_FIELD(fr05,  title= ' ', XSIZE = 9,  uvalue = uvs[2], $
                                   value = f2a(x_step[i,0]), $
                                   /return_events, /floating)
    info.mscan.npts[i]  = CW_FIELD(fr05,  title= ' ', XSIZE = 9,  uvalue = uvs[3], $
                                   value = f2a(x_npts[i]), $
                                   /return_events, /floating)
    info.mscan.time[i]  = CW_FIELD(fr05,  title= ' ', XSIZE = 9,  uvalue = uvs[4], $
                                   value = f2a(x_time[i]), $
                                   /return_events, /floating)
    info.mscan.units[i] = Widget_Label(fr05, uval = 'units', $ 
                               value= strtrim(_motor.units,2) )
endfor


;
;-----------------------
; EXAFS Scan Frame:
info.form.nb[1] = Widget_Base(OptBase, /col, MAP = 0,event_pro='exafs_event')
fr11           =  Widget_Base(info.form.nb[1],  /row)
x              =  Widget_Label(fr11,  value = ' EXAFS ')

info.escan.e0  =  CW_FIELD(fr11, /FLOATING,  /ROW,  XSIZE = 9,  $
                           TITLE = ' E0',  UVALUE = 'e0', $
                           VALUE = f2a(info.escan.e0), $
                           /return_events)

info.escan.nregs = CW_FIELD(fr11, /INTEGER,  /ROW,  XSIZE = 5, $
                            TITLE = '   Number of Scan Regions', UVALUE = 'nregs', $
                            VALUE = f2a(info.escan.nregs), $
                            /return_events)

info.escan.is_rel = Widget_Droplist(fr11, title = 'use ', $
                                   value = Rel_choices, uval = 'use_rel')
Widget_Control, info.escan.is_rel, set_Droplist_SELECT = 1
x = Widget_Label(fr11,  value = 'Energies')



fr12  = Widget_Base(info.form.nb[1], /row )

; info.escan.cur_pos = CW_Field(fr12,   title = 'Current Energy', $
;                              xsize = 12, uval = 'cur_pos', $
;                              value = f2a(_energy.curpos), $
;                              /return_events, /floating)

fr12  = Widget_Base(info.form.nb[1], /row)
fr13  = Widget_Base(info.form.nb[1], /col,/frame)
fr14  = Widget_Base(fr13, /row)

ts = 85
X = Widget_Label(fr14, XSIZE=  ts,  VALUE = 'Region  ' )
X = Widget_Label(fr14, XSIZE=  ts,  VALUE = 'Start   ' )
X = Widget_Label(fr14, XSIZE=  ts,  VALUE = 'Stop    ' )
X = Widget_Label(fr14, XSIZE=  ts,  VALUE = 'Step    ' )
X = Widget_Label(fr14, XSIZE=  ts,  VALUE = 'Npts    ' )
X = Widget_Label(fr14, XSIZE=  ts,  VALUE = 'Time (s)')
X = Widget_Label(fr14, XSIZE=  ts,  VALUE = 'Units   ' )

etitle   = ['Pre-Edge', 'XANES', 'EXAFS', 'EXTRA']
k_spaces = ['eV', STRING(197B)+'^(-1)']
uv_      = ['start',  'stop', 'step', 'npts', 'time','units'] 
for i = 0, 2 do  begin
    fr15 = Widget_Base(fr13, /row)
    X    = Widget_Label(fr15, XSIZE= 80,  VALUE = etitle[i], /ALIGN_LEFT)
    uvs  = uv_ + strtrim(string(i),2)
    info.escan.start[i] = CW_FIELD(fr15,  title= ' ', XSIZE = 9,  uvalue = uvs[0], $
                                   value = f2a(x_start[i,0]), $
                                   /return_events, /floating)
    info.escan.stop[i]  = CW_FIELD(fr15,  title= ' ', XSIZE = 9,  uvalue = uvs[1], $
                                   value = f2a(x_stop[i,0]), $
                                   /return_events, /floating)
    info.escan.step[i]  = CW_FIELD(fr15,  title= ' ', XSIZE = 9,  uvalue = uvs[2], $
                                   value = f2a(x_step[i,0]), $
                                   /return_events, /floating)
    info.escan.npts[i]  = CW_FIELD(fr15,  title= ' ', XSIZE = 9,  uvalue = uvs[3], $
                                   value = f2a(x_npts[i]), $
                                   /return_events, /floating)
    info.escan.time[i]  = CW_FIELD(fr15,  title= ' ', XSIZE = 9,  uvalue = uvs[4], $
                                   value = f2a(x_time[i]), $
                                   /return_events, /floating)
    if (i le 1) then begin
        X    = Widget_Label(fr15, XSIZE= 30,  VALUE = 'eV', /ALIGN_LEFT)
        info.escan.units[i]  = Widget_Base(fr15, /row, Map = 0)
    endif else begin
        info.escan.units[i]  = Widget_Droplist(fr15, value = k_spaces, $
                                               uvalue = uvs[5],    title = ' ')
        ch = es->get_scan_param(0, 'is_kspace')
        Widget_Control, info.escan.units[i], SET_DROPLIST_SELECT = ch[i]
    endelse

endfor

; map the current scan type!
Widget_Control, info.form.nb[cur_type], map=1
Widget_Control, info.escan.e0,      set_value = f2a(sc.params[0])

u = set_sensitive_regions(info.mscan,sc.n_regions)
u = set_sensitive_regions(info.escan,sc.n_regions)


;-----------------------
; Bottom Frame:
base1  = Widget_Base(mframe, /col, /frame)
base2  = Widget_Base(base1,/row)
X      = Widget_Button(base2,  value = 'Load Scan',  uval='load')
; X      = Widget_Button(base2,  value = 'Scan Viewer', uval='scan_view')
X      = Widget_Button(base2,  value = 'EXIT ',      uval='exit')

X      = Widget_Label(base2,  value = 'Estimated time:')
info.form.time_est = Widget_Label(base2,  xsize=190,value = '            ')

sv = obj_new('scanviewer',escan=es)

for i = 0, 2 do  sc  = update_scan_settings(info.escan, sc, i)


; render widgets, load info structure into main
p_info = ptr_new(info,/no_copy)
Widget_Control,    main, set_uval=p_info
Widget_Control,    main, /realize
xmanager, 'escan', main, /no_block
return
end

