;
; Gui for motor scanning 

pro set_motor_scan, motor= motor, name=name, start=start, stop=stop, step=step, $
                time=time, relative=relative, scanPV=scanPV, list=list

;
; define linear motor scan 
;
; default values
prefix      = '13IDC:'
motorPV     = 'null'
scanPV_     = 'scan1'

scalerPV    = prefix + 'scaler1'
medPV       = prefix + 'med:'
count_time  = 1
is_relative = 0

motor_p = ['m1','m2','m3','m4','m5','m6','m8','m9','m10',$
           'm11', 'm12', 'm13', 'm14', 'm16', 'm15', 'm17',$
           'm18', 'm19', 'm20', 'm21', 'm22', 'm23', 'm24','Energy','1D_pDummy']

motor_n = ["Table Y upstream","Table Y inboard","Table Y outboard",$
           "Table X upstream","Table X downstream","Table Base Y",$
           "Mono angle","TT Slit H Pos","TT Slit H Wid","TT Slit V Pos",$
           "TT Slit V Wid","Stage X", "Stage Y","Stage Z","WDS Stage X ",$
           "KB V x", "KB V angle","KB V Fup","KB V Fdn", $
           "KB H x", "KB H angle","KB H Fup", "KB H Fdn", "Energy","Dummy"] 

; read arguments into local variables
if (keyword_set(scanPV))  then begin
    scanPV_ = scanPV
    if (scanPV eq '1') then begin
        scanPV_ =+ 'scan1'
    endif else if (scanPV eq '2') then begin
        scanPV_ = 'scan2'
    endif else if (scanPV eq '3') then begin
        scanPV_ = 'scan3'
    endif
endif
SPV = prefix + ScanPV_

motorPV = '1D_pDummy'
if (scanPV_ eq 'scan2') then motorPV = '2D_pDummy'
if (scanPV_ eq 'scan3') then motorPV = '1D_pDummy'


if (keyword_set(relative) ne 0)  then  is_relative  = relative
if (n_elements(time)    ne 0)    then  count_time= time
if (n_elements(motor)   ne 0)    then  motorPV  = motor
if (n_elements(name)    ne 0)    then  begin
    if (name eq 'Sample X') then name = 'Stage X'
    if (name eq 'Sample Y') then name = 'Stage Y'
    if (name eq 'Sample Z') then name = 'Stage Z'
    if (name ne 'Dummy') then begin
        n = n_elements(motor_n)
        for i = 0, n-1 do begin
            if (name eq motor_n[i]) then motorPV = motor_p[i]
        endfor
    endif
    if (motorPV eq 'null') then begin
        print, ' unknown motor name: ', name
        print, ' type   set_motor_scan, /list    for list of motor names'
        return
    endif
endif

if (n_elements(list)    ne 0)    then  begin
  n = n_elements(motor_n)
  for i = 0, n-1 do  print, '     ', motor_n[i]  
  return
endif

;
if ((keyword_set(help) ne 0) or (motorPV eq 'null')) then begin
    print, "SET_MOTOR_SCAN:  setup a linear scan (but don't execute)"
    print, '  parameters:'
    print, '   name       motor name  (use /list for list of names)'
    print, "   motor      motor PV name  ('m1', 'm2', ... )"
    print, '   start      starting position'
    print, '   stop       stopping position'
    print, '   step       step size'
    print, '   time       integration time'
    print, '   scan     index of scan record to use (1, 2, or 3)'
    print, '  /relative   use values relative to current postion '
    print, '  /list       print list of motor names'
    return
endif

pos1 = prefix + motorPV + '.VAL'
rbv1 = prefix + motorPV + '.RBV'
if (motorPV eq 'Energy') then begin
    pos1 = '13IDC:Energy.VAL'
    rbv1 = '13IDC:Energy.VAL'
endif

init_pos = 22.000
s        = caget(pos1, init_pos)
Mstart   = init_pos
Mstep    = 1.
Mstop    = init_pos + Mstep

if (n_elements(start) ne 0) then Mstart = start
if (n_elements(stop)  ne 0) then Mstop  = stop
if (n_elements(step)  ne 0) then Mstep  = abs(step)
if (Mstop lt Mstart)        then Mstep  = -Mstep
if (count_time le 0)        then s = caget(scalerPV + 'TP', count_time)

Mstep_extra = abs(Mstep - (Mstep * 0.0001  + 1.d-12))
npts        = fix(1  + (abs(Mstart - Mstop)/abs(Mstep_extra)))

x = caput( SPV   + '.PASM', 2)           ;  'Prior Pos' after scan
x = caput( SPV   + '.P1AR', is_relative)      ;  'Absolute  mode'
x = caput( SPV   + '.P1SM', 0)           ;  'linear mode'
x = caput( SPV   + '.P1PV', pos1)
x = caput( SPV   + '.R1PV', rbv1)
x = caput( SPV   + '.P1SP', Mstart)
x = caput( SPV   + '.P1EP', Mstop)
x = caput( SPV   + '.P1SI', Mstep)
x = caput( SPV   + '.NPTS', npts)
; positioner and detector settling time for SSCAN record: set minima
    x = caget( SPV + '.PDLY', p_delay)
    if (p_delay le 0.10) then begin
        p_delay = 0.10
        x = caput( SPV + '.PDLY', p_delay)
    endif
    x = caget( SPV + '.DDLY', d_delay)
    if (d_delay le 0.05) then begin
        d_delay = 0.05
        x = caput( SPV + '.DDLY', d_delay)
    endif

x = caput( scalerPV + '.CONT', 0)           ; put scaler in one-shot mode
x = caput( scalerPV + '.TP', count_time)    ; set scaler count time
x = caput( medPV    + 'PresetReal', count_time) ; set med count time
x = caput( medPV    + 'StatusSeq.SCAN', 8) ; set med status rate to 0.2sec
x = caput( medPV    + 'ReadSeq.SCAN', 0) ; set med in 'passive read rate'



print, format='(1x,2a,$)', 'Ready to scan  ', pos1
if (is_relative) then begin
    print, '  relative to current position '
endif else print, ' '
print, ' Start, Stop, Step, Npts = ',  Mstart, Mstop, Mstep,  npts


return
end

pro get_motor_settings, prefix=prefix, motor=motor, scanPV=scanPV, $
                        value=value, llimit=llimit, ulimit=ulimit, $
                        pv=pv, rbv=rbv, units=units
  motor_name2pv, name = motor, pv = pv, scanPV=scanPV
  pvo    = pv
  p      = prefix + pv
  print, ' getting motor settings for "', motor, '" ', p
  value  = 0.00
  llimit = -100.
  ulimit =  100.
  units  = ' '
  pv     = p + '.VAL'
  rbv    = p + '.RBV'
  if (motor eq 'Dummy') then begin
      rbv    = p + '.VAL'
  endif else begin
      units  = 'mm'
      s      = caget(p + '.VAL', value)
      s      = caget(p + '.EGU', units)
      if (pvo eq 'Energy') then begin
          rbv = pv
          ulimit = '40000.'
          llimit = '4000.'
      endif else begin
          s  = caget(p + '.LLM', llimit)
          s  = caget(p + '.HLM', ulimit)
      endelse
  endelse
  if (double(llimit) ge double(ulimit)) then begin
      tmp    = ulimit
      ulimit = llimit
      llimit = tmp
  endif
return
end

pro motor_name2pv, name=name, pv=pv, scanPV=scanPV

motor_p = ['m1','m2','m3','m4','m5','m6','m8','m9','m10',$
           'm11', 'm12', 'm13', 'm14', 'm16', 'm15', 'm17',$
           'm18', 'm19', 'm20', 'm21', 'm22', 'm23', 'm24','Energy']

motor_n = ["Table Y upstream","Table Y inboard","Table Y outboard",$
           "Table X upstream","Table X downstream","Table Base Y",$
           "Mono angle","TT Slit H Pos","TT Slit H Wid","TT Slit V Pos",$
           "TT Slit V Wid","Sample X", "Sample Y","Sample Z","WDS Stage X ",$
           "KB V x", "KB V angle","KB V Fup","KB V Fdn", $
           "KB H x", "KB H angle","KB H Fup", "KB H Fdn", "Energy"] 

n = n_elements(motor_n)
pv = '1D_pDummy.VAL'
if (scanPV eq 'scan2') then pv = '2D_pDummy.VAL'
if (scanPV eq 'scan3') then pv = '1D_pDummy.VAL'
if (name   eq 'Stage X') then name = 'Sample X'
if (name   eq 'Stage Y') then name = 'Sample Y'
if (name   eq 'Stage Z') then name = 'Sample Z'
for i = 0, n-1 do begin
    if (name eq motor_n[i]) then pv = motor_p[i]
endfor
if (pv eq 'null') then begin
    print, ' unknown motor name: ', name
    print, ' type   motor_scan, /list    for list of motor names'
endif
return
end

function npts_of_start_stop_step, start, stop, step
MAX_SCAN_POINTS = 1000 ;  maximum number of points in scan record
step = abs(step) 
if (step le 1.d-8) then step = 1.d-8
npts   = 1 + round((abs(stop - start) )/abs(step))
npts   = fix ( (npts > 2) < MAX_SCAN_POINTS)
step   = (stop - start) / (npts-1)
return, npts
end

pro motor_redraw_window, p
; redraw motor screen (say, after loading a scan parameter file)
; note: scan1 is updated, and brought to the foreground

   Widget_Control, (*p).wid.scan,    SET_DROPLIST_SELECT = 0
   Widget_Control, (*p).wid.is_rel,  SET_DROPLIST_SELECT = (*p).scan1.is_rel
   Widget_Control, (*p).wid.time,    SET_VALUE = (*p).scan1.time
   Widget_Control, (*p).wid.units,   SET_VALUE = (*p).scan1.units
   Widget_Control, (*p).wid.start,   SET_VALUE = (*p).scan1.r1start
   Widget_Control, (*p).wid.stop,    SET_VALUE = (*p).scan1.r1stop
   Widget_Control, (*p).wid.step,    SET_VALUE = (*p).scan1.r1step
   Widget_Control, (*p).wid.npts,    SET_VALUE = (*p).scan1.r1npts
;;
   n = n_elements((*p).m_names) 
   name = strtrim((*p).scan1.motor_name,2)
   (*p).scan1.motor_name = name
   for i = 0, n-1 do begin
       if (name eq (*p).m_names[i]) then goto, scan_choice_found
   endfor
   i = 0
   scan_choice_found:
   WIDGET_CONTROL, (*p).wid.motor,  SET_DROPLIST_SELECT = i        
;;   
   get_motor_settings, prefix=(*p).main.prefix, motor=(*p).scan1.motor_name, $
     scanPV=(*p).scan1.scanPV,$
     value=val,  llimit=ll, ulimit=ul, units=ut, pv=pv, rbv=rbv
   (*p).scan1.cur_pos= val
   (*p).scan1.units  = ut
   (*p).scan1.ulimit = ul
   (*p).scan1.llimit = ll
   (*p).scan1.pos1   = pv
   (*p).scan1.rbv1   = rbv
   WIDGET_CONTROL, (*p).wid.llimit,  SET_VALUE = strtrim(string(ll),2)
   WIDGET_CONTROL, (*p).wid.ulimit,  SET_VALUE = strtrim(string(ul),2)
   WIDGET_CONTROL, (*p).wid.cur_pos, SET_VALUE = strtrim(string(val),2)
   WIDGET_CONTROL, (*p).wid.units,   SET_VALUE = strtrim(string(ut),2)
   return
end

pro motor_scan_event, event

WIDGET_CONTROL, event.top, GET_UVALUE = p
WIDGET_CONTROL, event.id,  GET_UVALUE = uval

MAX_SCAN_POINTS = 1000 ;  maximum number of points in scan record
ErrorNo = 0
Catch, ErrorNo
if (ErrorNo ne 0) then begin    ;
    Catch, /CANCEL
    ErrArray = ['Application Error!', $
                'Error Number: '+strtrim(!error,2), !Err_String]
    a = DIALOG_MESSAGE(ErrArray, /ERROR)
    return
endif

update_scans  = 1
current_scan  = fix((*p).main.current_scan)
case current_scan of
    1:  scan = (*p).scan1
    2:  scan = (*p).scan2
    3:  scan = (*p).scan3
    else: print, ' error : current_scan ', current_scan , ' out of range '
endcase

; print , ' see event: "', uval, '" for ', scan.ScanPV

case uval of
    'exit':   WIDGET_CONTROL, event.top, /DESTROY
    'load_cfg': begin
        f   =  (*p).main.file
        retval = read_scan_param_file(p)
        motor_redraw_window, p
        update_scans = 0        ; don't overwrite read-in scans with old values!!
    end
    'save_cfg': begin
        f   =  (*p).main.file
        retval = save_scan_param_file(p,1)
    end
    'saveas_cfg': begin
        f   =  (*p).main.file
        retval = save_scan_param_file(p,1)
    end
    'time': begin
        WIDGET_CONTROL, (*p).wid.time, GET_VALUE = t
        t =  strtrim(t,2)
        scan.time = t
    end
    'start_pos': begin
        WIDGET_CONTROL, (*p).wid.start, GET_VALUE = t
        start =  strtrim(t,2)
        new_pos = double(start)
        ul    = scan.ulimit
        ll    = scan.llimit
        if (scan.is_rel) then new_pos = new_pos  + scan.cur_pos
        if ((new_pos lt ll) or (new_pos gt ul)) then begin
            if (new_pos lt ll) then new_pos = ll
            if (new_pos gt ul) then new_pos = ul
            if (scan.is_rel)   then new_pos = new_pos  - scan.cur_pos
            WIDGET_CONTROL, (*p).wid.start, $
              SET_VALUE = strtrim(string(new_pos),2)
        endif 
        WIDGET_CONTROL, (*p).wid.start, GET_VALUE = t
        start =  double(strtrim(t,2))
        step  = scan.r1step
        stop  = scan.r1stop
        npts  = npts_of_start_stop_step(start,stop,step)
        scan.r1npts  = npts
        scan.r1start = start
        scan.r1stop  = stop
        scan.r1step  = step
        WIDGET_CONTROL, (*p).wid.step, SET_VALUE = strtrim(string(step),2)
        WIDGET_CONTROL, (*p).wid.npts, SET_VALUE = strtrim(string(npts),2)
    end
    'stop_pos': begin
        WIDGET_CONTROL, (*p).wid.stop, GET_VALUE = t
        stop =  strtrim(t,2)
        new_pos = double(stop)
        ul    = scan.ulimit
        ll    = scan.llimit
        if (scan.is_rel) then new_pos = new_pos  + scan.cur_pos
        if ((new_pos lt ll) or (new_pos gt ul)) then begin
            if (new_pos lt ll) then new_pos = ll
            if (new_pos gt ul) then new_pos = ul
            if (scan.is_rel)   then new_pos = new_pos  - scan.cur_pos
            WIDGET_CONTROL, (*p).wid.stop, $
              SET_VALUE = strtrim(string(new_pos),2)
        endif 
        WIDGET_CONTROL, (*p).wid.stop, GET_VALUE = t
        stop =  double(strtrim(t,2))
        step  = scan.r1step
        start = scan.r1start
        npts  = npts_of_start_stop_step(start,stop,step)
        scan.r1npts  = npts
        scan.r1start = start
        scan.r1stop  = stop
        scan.r1step  = step
        WIDGET_CONTROL, (*p).wid.step, SET_VALUE = strtrim(string(step),2)
        WIDGET_CONTROL, (*p).wid.npts, SET_VALUE = strtrim(string(npts),2)
    end
    'step': begin
        WIDGET_CONTROL, (*p).wid.step, GET_VALUE = t
        step  = double(strtrim(t,2))
        start = scan.r1start
        stop  = scan.r1stop
        npts  = npts_of_start_stop_step(start,stop,step)
        scan.r1npts  = npts
        scan.r1start = start
        scan.r1stop  = stop
        scan.r1step  = step
        WIDGET_CONTROL, (*p).wid.step, SET_VALUE = strtrim(string(step),2)
        WIDGET_CONTROL, (*p).wid.npts, SET_VALUE = strtrim(string(npts),2)
    end
    'npts': begin
        WIDGET_CONTROL, (*p).wid.npts, GET_VALUE = t
        npts  = strtrim(t,2)
        start = scan.r1start
        stop  = scan.r1stop
        npts  = ((npts > 2) < MAX_SCAN_POINTS)
        scan.r1npts = npts
        step   = abs(scan.r1start - scan.r1stop)/(npts  - 1)
        if (scan.r1start gt scan.r1stop) then step = -step
        scan.r1step = step
        WIDGET_CONTROL, (*p).wid.step, SET_VALUE = strtrim(string(step),2)
        WIDGET_CONTROL, (*p).wid.npts, SET_VALUE = strtrim(string(npts),2)
    end
    'scan_choice': begin
        case event.index of
            0:  scan = (*p).scan1
            1:  scan = (*p).scan2
            2:  scan = (*p).scan3
            else:
        endcase
        current_scan =  event.index + 1
        (*p).main.current_scan =  current_scan
        pre = (*p).main.prefix
        name = scan.motor_name
        print, 'scan_choice : ', current_scan, ' -> get_motor_settings ', name
        get_motor_settings, prefix=(*p).main.prefix, motor=name, scanPV=scan.scanPV,$
          value=val,  llimit=ll, ulimit=ul, units=ut, pv=pv, rbv=rbv
        scan.cur_pos= val
        scan.units  = ut
        scan.ulimit = ul
        scan.llimit = ll
        scan.pos1   = pv
        scan.rbv1   = rbv
        WIDGET_CONTROL, (*p).wid.llimit,  SET_VALUE = strtrim(string(ll),2)
        WIDGET_CONTROL, (*p).wid.ulimit,  SET_VALUE = strtrim(string(ul),2)
        WIDGET_CONTROL, (*p).wid.cur_pos, SET_VALUE = strtrim(string(val),2)
        WIDGET_CONTROL, (*p).wid.units,   SET_VALUE = strtrim(string(ut),2)
        for i = 0, n_elements((*p).m_names) do begin
            if (name eq (*p).m_names[i]) then goto, scan_choice_found
        endfor
        scan_choice_found:
        WIDGET_CONTROL, (*p).wid.motor,  SET_DROPLIST_SELECT = i        
        start = scan.r1start
        stop  = scan.r1stop
        step  = scan.r1step
        npts  = scan.r1npts
        is_rel = scan.is_rel
        print , ' start stop step  npts is_rel = ', $
          start, stop , step,  npts, is_rel
        WIDGET_CONTROL, (*p).wid.start, SET_VALUE = strtrim(string(start),2)
        WIDGET_CONTROL, (*p).wid.stop, SET_VALUE = strtrim(string(stop),2)
        WIDGET_CONTROL, (*p).wid.step, SET_VALUE = strtrim(string(step),2)
        WIDGET_CONTROL, (*p).wid.npts, SET_VALUE = strtrim(string(npts),2)
        WIDGET_CONTROL, (*p).wid.is_rel, SET_DROPLIST_SELECT = is_rel
    end
    'use_rel': begin
        do_change = 0
        dx = 0
;        print , ' use_rel ', scan.cur_pos, event.index, scan.is_rel
        if ((event.index eq 1) and (scan.is_rel eq 0)) then begin ;
            do_change = 1
            scan.is_rel = 1
            dx  = - scan.cur_pos
        endif else if ((event.index eq 0) and (scan.is_rel eq 1)) then begin
            do_change = 1
            scan.is_rel = 0
            dx  = scan.cur_pos
        endif 
        if (do_change eq 1) then begin
            start = scan.r1start + dx
            stop  = scan.r1stop  + dx
            scan.r1start = start 
            scan.r1stop  = stop
            WIDGET_CONTROL, (*p).wid.start, SET_VALUE = strtrim(string(start),2)
            WIDGET_CONTROL, (*p).wid.stop,  SET_VALUE = strtrim(string(stop),2)
        endif
    end
    'motor_name': begin
        name  = (*p).m_names[event.index]
        get_motor_settings, prefix=(*p).main.prefix, motor=name, scanPV=scan.scanPV, $
          value=val,  llimit=ll, ulimit=ul, units=ut, pv=pv, rbv=rbv
        scan.motor_name   = name
        scan.cur_pos= val
        scan.units  = ut
        scan.ulimit = ul
        scan.llimit = ll
        scan.pos1   = pv
        scan.rbv1   = rbv
        WIDGET_CONTROL, (*p).wid.llimit,  SET_VALUE = strtrim(string(ll),2)
        WIDGET_CONTROL, (*p).wid.ulimit,  SET_VALUE = strtrim(string(ul),2)
        WIDGET_CONTROL, (*p).wid.cur_pos, SET_VALUE = strtrim(string(val),2)
        WIDGET_CONTROL, (*p).wid.units,   SET_VALUE = strtrim(string(ut),2)
    end
    'cur_pos': begin
        WIDGET_CONTROL, (*p).wid.cur_pos, GET_VALUE = cur
        val = double(strtrim(cur,2))
        ll  = scan.llimit 
        ul  = scan.ulimit 
        pos = scan.pos1
        if ((val le ul)  and (val ge ll)) then begin
            rbv = val
            s   = caput(pos, val)
            s   = caget(pos, rbv)
            scan.cur_pos = rbv 
            WIDGET_CONTROL, (*p).wid.cur_pos, SET_VALUE = strtrim(string(rbv),2)
        endif else begin
            print, ' requested position is outside limits'
        endelse
    end
    'llimit': begin
        WIDGET_CONTROL, (*p).wid.llimit, SET_VALUE = string(scan.llimit)
    end
    'ulimit': begin
        WIDGET_CONTROL, (*p).wid.ulimit, SET_VALUE = string(scan.ulimit)
    end
    'load': begin
        name   =  scan.motor_name
        start  =  scan.r1start
        stop   =  scan.r1stop
        step   =  scan.r1step
        time   =  scan.time
        scanPV =  scan.scanPV
        rel    =  scan.is_rel
        set_motor_scan, name=name, start=start, stop=stop, step=step, $
          time=time, relative=rel, scanPV= scanPV
    end
    else: print , ' unknown event ', uval
endcase

;
; put back scan structure into (*p)

; print, 'putting ' , current_scan, ' back into heap'
if (update_scans eq 1) then begin
    case current_scan of
        1:  (*p).scan1 = scan
        2:  (*p).scan2 = scan
        3:  (*p).scan3 = scan
        else: print, 'cannot put current_scan back!!' , current_scan
    endcase
endif
;
return
end

pro motor_scan

m_names = ["Dummy", "Energy", "Sample X", "Sample Y","Sample Z", $
           "Table Y upstream","Table Y inboard",$
           "Table Y outboard", "Table X upstream",$
           "Table X downstream","Table Base Y",$
           "Mono angle","TT Slit H Pos","TT Slit H Wid","TT Slit V Pos",$
           "TT Slit V Wid","WDS Stage X ",$
           "KB V x", "KB V angle","KB V Fup","KB V Fdn", $
           "KB H x", "KB H angle","KB H Fup", "KB H Fdn"]

scan_choices = ['Scan 1', 'Scan 2', 'Scan 3']
Rel_choices =  ['Absolute', 'Relative']

main = {prefix:'13IDC:', file:'unknown.scn', dimension:'1',$
        detectors: 15, current_scan:1,  trigger1:'med:Start.VAL', trigger2:'scaler1.CNT'}

scan1 = {type:'Motor', ScanPV:'scan1', motor_name:m_names[2],$
         pos1: '', rbv1: '', units:'mm', $
         llimit:0.0, ulimit:0.0, cur_pos:0.0, $
         r1start:-10., r1step: 1. , r1stop: 10., r1npts: 21 , $
         e0:7112.,  is_rel:1, is_kspace:0, nregs:3, time:1.0, $
         r2start: -30., r2step: 0.5 , r2stop:  30., r2npts: 61, $
         r3start:  0., r3step: 0.05, r3stop:  15. , r3npts: 300 }

scan2 = {type:'Motor', ScanPV:'scan2', motor_name:m_names[3],$
         pos1: '', rbv1: '',  units:'mm', $
         llimit:0.0, ulimit:0.0, cur_pos:0.0, $
         r1start:-10., r1step: 1. , r1stop: 10., r1npts: 21 , $
         e0:7112.,  is_rel:1, is_kspace:0, nregs:3, time:1.0, $
         r2start: -30., r2step: 0.5 , r2stop:  30., r2npts: 61, $
         r3start:  0., r3step: 0.05, r3stop:  15. , r3npts: 300 }

scan3 = {type:'Motor', ScanPV:'scan3', motor_name:m_names[4],$
         pos1: '', rbv1: '',  units:'mm', $
         llimit:0.0, ulimit:0.0, cur_pos:0.0, $
         r1start:-10., r1step: 1. , r1stop: 10., r1npts: 21 , $
         e0:7112.,  is_rel:1, is_kspace:0, nregs:3, time:1.0, $
         r2start: -30., r2step: 0.5 , r2stop:  30., r2npts: 61, $
         r3start:  0., r3step: 0.05, r3stop:  15. , r3npts: 300 }

wid  = {scan:scan_choices[0], motor:m_names[2], time:0L, $
        is_rel:Rel_choices[1], units:0L, $
        start:0L,  stop:0L, step:0L, npts:0L, $
        cur_pos:0L,  llimit:0L, ulimit:0L}

;  get settings for default motor:

l = -20.
u =  70.
c =  10.5


get_motor_settings, prefix=main.prefix, motor=scan1.motor_name, scanPV=scan1.ScanPV,$
   value=c,  llimit=l, ulimit=u, units=t, pv=pv, rbv=rbv
scan1.llimit  = l
scan1.ulimit  = u
scan1.cur_pos = c
scan1.units   = t
scan1.pos1    = pv
scan1.rbv1    = rbv

get_motor_settings, prefix=main.prefix, motor=scan2.motor_name, scanPV=scan2.ScanPV,$
   value=c,  llimit=l, ulimit=u, units=t, pv=pv, rbv=rbv
scan2.llimit  = l
scan2.ulimit  = u
scan2.cur_pos = c
scan2.units   = t
scan2.pos1    = pv
scan2.rbv1    = rbv

get_motor_settings, prefix=main.prefix, motor=scan3.motor_name, scanPV=scan3.ScanPV,$
   value=c,  llimit=l, ulimit=u, units=t, pv=pv, rbv=rbv
scan3.llimit  = l
scan3.ulimit  = u
scan3.cur_pos = c
scan3.units   = t
scan3.pos1    = pv
scan3.rbv1    = rbv



info = {main:main, scan1:scan1, scan2:scan2, scan3:scan3, wid:wid, m_names:m_names}
;
MAIN      = Widget_Base(TITLE = 'Motor Scan', /COLUMN, APP_MBAR = menubar)
fileMenu  = WIDGET_BUTTON(menubar,  VALUE = 'File', /HELP)
loadMB    = WIDGET_BUTTON(fileMenu, VALUE = 'Read Scan File ...', UVALUE = 'load_cfg')
saveMB    = WIDGET_BUTTON(fileMenu, VALUE = 'Save Scan File ...', UVALUE = 'save_cfg')
saveasMB  = WIDGET_BUTTON(fileMenu, VALUE = 'Save As ...', UVALUE = 'saveas_cfg')
exitMB    = WIDGET_BUTTON(fileMenu, VALUE = 'Exit', UVALUE = 'exit', $
                          /SEPARATOR)
; Help menu
helpMenu  = WIDGET_BUTTON(menubar,  VALUE = 'Help', /MENU, /HELP)
scnhelpMB = WIDGET_BUTTON(helpMenu, VALUE = 'Help on Motor REGIONS',  UVALUE = 'scan_help')
idlhelpMB = WIDGET_BUTTON(helpMenu, VALUE = 'Help on IDL',  UVALUE = 'IDLhelp')
MAINFRAME = WIDGET_BASE(MAIN, /COLUMN)
R0_base   = WIDGET_BASE(MAINFRAME, /ROW)


MAINFRAME = WIDGET_BASE(MAIN, /COLUMN)
R0_base   = WIDGET_BASE(MAINFRAME, /ROW)
info.wid.scan = WIDGET_DROPLIST(R0_base, TITLE = ' Scan ', $
                               VALUE = scan_choices, UVALUE = 'scan_choice')
WIDGET_CONTROL, info.wid.scan, SET_DROPLIST_SELECT = 0

info.wid.motor = WIDGET_DROPLIST(R0_base, TITLE = ' Motor ', $
                               VALUE = m_names, UVALUE = 'motor_name')
WIDGET_CONTROL, info.wid.motor, SET_DROPLIST_SELECT = 2

info.wid.time  = CW_FIELD(R0_base, /FLOATING,  /ROW,  XSIZE = 7, $
                          TITLE = '     Count Time', UVALUE = 'time', $
                          VALUE = strtrim(string(info.scan1.time),2), $
                          /ALL_EVENTS)
X              = WIDGET_LABEL(R0_base, SCR_XSIZE=40,  VALUE = 'sec')


R_base   = WIDGET_BASE(MAINFRAME, /COLUMN)
R1_base  = WIDGET_BASE(R_base, /ROW, /FRAME)

info.wid.cur_pos = CW_FIELD(R1_base,  /FLOATING, Title = 'Current Position', $
                            XSIZE = 11, UVALUE = 'cur_pos', $
                            VALUE = strtrim(string(info.scan1.cur_pos),2), $
                            /RETURN_EVENTS)
info.wid.units  = WIDGET_LABEL(R1_base, XSIZE=80, $ ; /ALIGN_LEFT, $
                               VALUE= strtrim(info.scan1.units,2), $
                               UVALUE = 'units')

info.wid.llimit = CW_FIELD(R1_base,  /FLOATING, Title = 'Limits :', $
                            XSIZE = 11, UVALUE = 'llimit', $
                            VALUE = strtrim(string(info.scan1.llimit),2), $
                            /RETURN_EVENTS)

info.wid.ulimit = CW_FIELD(R1_base,  /FLOATING, Title = ' : ', $
                           XSIZE = 11, UVALUE = 'ulimit', $
                           VALUE = strtrim(string(info.scan1.ulimit),2), $
                           /RETURN_EVENTS)

R2_base   = WIDGET_BASE(R_base, /ROW)
info.wid.is_rel = WIDGET_DROPLIST(R2_base, TITLE = 'use ', $
                               VALUE = Rel_choices, UVALUE = 'use_rel')
WIDGET_CONTROL, info.wid.is_rel, SET_DROPLIST_SELECT = 1
X = WIDGET_LABEL(R2_base, XSIZE=120,  VALUE = ' Positions  ')


R = WIDGET_BASE(MAINFRAME, /COLUMN,/FRAME)
T = WIDGET_BASE(R, /ROW)

X = WIDGET_LABEL(T, XSIZE=100,  VALUE = ' Start  ')
X = WIDGET_LABEL(T, XSIZE=100,  VALUE = ' Stop   ')
X = WIDGET_LABEL(T, XSIZE=100,  VALUE = ' Step   ')
X = WIDGET_LABEL(T, XSIZE=100,  VALUE = ' Npts   ')

S = WIDGET_BASE(R, /ROW)
info.wid.start = CW_FIELD(S,  Title= ' ', XSIZE = 11,  UVALUE = 'start_pos', $
                          VALUE = strtrim(string(info.scan1.r1start),2), $
                          /RETURN_EVENTS, /FLOATING)
info.wid.stop  = CW_FIELD(S, Title= ' ',  XSIZE = 11,  UVALUE = 'stop_pos', $
                          VALUE = strtrim(string(info.scan1.r1stop),2), $
                          /RETURN_EVENTS, /FLOATING)
info.wid.step  = CW_FIELD(S,  Title = ' ', XSIZE = 11,  UVALUE = 'step', $
                          VALUE = strtrim(string(info.scan1.r1step),2), $
                          /RETURN_EVENTS, /FLOATING)
info.wid.npts  = CW_FIELD(S,  Title = ' ', XSIZE = 11,  UVALUE = 'npts', $
                          VALUE = strtrim(string(info.scan1.r1npts),2), $
                          /RETURN_EVENTS, /FLOATING)

R4_base = WIDGET_BASE(MAINFRAME,/ROW)
X     = WIDGET_BUTTON(R4_base,  VALUE = 'Load Scan Parameters', UVALUE='load')
X     = WIDGET_BUTTON(R4_base,  VALUE = 'EXIT ', UVALUE='exit')

; render widgets, load info structure into MAIN
p_info = ptr_new(info,/NO_COPY)
Widget_Control, MAIN, SET_UVALUE=p_info
Widget_Control, MAIN, /REALIZE
xmanager, 'motor_scan', MAIN, /NO_BLOCK

return
end
