function xyz_save_paramfile, p, use_dialog=use_dialog, file=file

s_file = 'xyzstage.def'
if (keyword_set(file) ne 0) then s_file =  file

if (keyword_set (use_dialog)) then begin
    file = dialog_pickfile(filter='*.def', get_path=path, $
                           /write, file = s_file)
endif

openw, lun,  file, /get_lun
printf, lun,  ';XYZ Stage Definition File'
printf, lun,  'motor_x: ', (*p).stage_pv[0]
printf, lun,  'motor_y: ', (*p).stage_pv[1]
printf, lun,  'motor_z: ', (*p).stage_pv[2]
printf, lun,  'sign_x:  ', (*p).xsign
printf, lun,  'sign_y:  ', (*p).ysign
printf, lun,  'sign_z:  ', (*p).zsign
printf, lun,  'verify_move: ',      (*p).verify_move
printf, lun,  'verify_erase: ',     (*p).verify_erase
printf, lun,  'verify_overwrite: ', (*p).verify_overwrite
printf, lun,  'steps: ', f2a( (*(*p).psteps) )

pts = (*(*p).ppos)

n = size(pts)
for i = 0, n[1]-1 do begin
    printf, lun, 'point: ', pts[i].name
    printf, lun, '       ', pts[i].x, pts[i].y, pts[i].z 
endfor

close,lun
free_lun, lun
return, 1
end


function xyz_read_paramfile, use_dialog=use_dialog, file=file
;
;  read scan file to (re)initialize epics_scan object
;  returns 0 for apparent succees, <0 for bad or unfound files
;
s_file = 'xyzstage.def'
if (keyword_set(file) ne 0) then s_file =  file

if (keyword_set (use_dialog)) then begin
    s_file = dialog_pickfile(filter='*.def', get_path=path, $
                             /must_exist, /read, file = s_file)
endif
s_file  = strtrim(s_file,2)

ptr1    = ptr_new(['0.1', '0.2'])
po      = {point, name:'', x:0., y:0.,z:0.}
ptr2    = ptr_new(po)
p       = {mx:'', my:'', mz:'', vmove:0, veras:0, vover:0, $
           xsign:0, ysign:0, zsign:0, $
           psteps:ptr1, ppos:ptr2, valid:1}

ptr_free, ptr1
ptr_free, ptr2
po = ''

if (s_file eq '') then goto, bad_file
on_ioerror, bad_file
openr, lun,  s_file, /get_lun
str     = ' '
line1   =  1
npts    = 0
while not (eof(lun)) do begin
    readf, lun, str
    str  = strtrim(str,2)
    if ((str eq '') or (strmid(str, 0, 1)  eq '#')) then goto, loop_end
    if (line1 eq 1) then begin
        line1 = 0
        s = strmid(str, 0, 26) 
        t = strmid(str, 26, strlen(str)) 
        if (s ne ';XYZ Stage Definition File') then begin
            print, ' File ', s_file,  ' is not a valid scan file'
            p.valid = 0
            goto, ret
        endif
    endif
    icol  = strpos(str, ':')
    ismc  = strpos(str, ';')
    if ((ismc eq -1) and (icol ge 2)) then begin
        key = strmid(str,0, icol)
        val = strtrim(strmid(str,icol+1, strlen(str)), 2)
        case key of 
            'motor_x':      p.mx = val
            'motor_y':      p.my = val
            'motor_z':      p.mz = val
            'sign_x':       p.xsign = val
            'sign_y':       p.ysign = val
            'sign_z':       p.zsign = val
            'verify_move':      p.vmove = val
            'verify_erase':     p.veras = val
            'verify_overwrite': p.vover = val
            'steps':    begin
                n  = string_array(val,arr)
                p.psteps = ptr_new(arr)
                arr     = ''
            end
            'point':  begin
                tmp = {point, name:'', x:0., y:0., z:0. }
                tmp.name = val
                readf, lun, str
                str  = strtrim(str,2)
                n = string_array(str, arr)
                if (n ge 1) then    tmp.x = arr[0]
                if (n ge 2) then    tmp.y = arr[1]
                if (n ge 3) then    tmp.z = arr[2]
                if (npts ge 1) then tmp   = [(*p.ppos), tmp]
                p.ppos = ptr_new(tmp)
                npts   = npts + 1
                tmp    = ''
            end
            else: x = 1
        endcase
    endif
    loop_end:
endwhile
ret:
  close, lun
  free_lun, lun
  tmp = ''
  return, p
bad_file:
  print, '  Warning: XYZ definition file ', s_file,  ' could not be loaded.'
  p.valid = 0
  return, p
end


function xyz_prompt_dialog, type, point
;
; use question-box to prompt for move, erase, or overwriting 
; of saved point
;
;
; returns:
;     1  'yes'
;     0  'no'
;---------------------------------------------
xpt   = point
title = ' ??? Weird XYZ Stage Error ??? '
prep  = ' at '
subt  = 'x,y,z= (' + f2a(xpt.x) + ',' +  f2a(xpt.y) + ',' + f2a(xpt.z) + ')?'
nam   = '"' + strtrim(xpt.name,2) + '"'
case type of
    'move':  title = ' Move to Saved Position  ' 
    'erase': title = ' Erase Saved Position  ' 
    'overwrite': begin
        title = ' Overwrite Earlied Definition of '
        prep  = ' of '
    end
    else: stat = 1
endcase

m   = [title + nam , prep + subt]
ret = dialog_message(m, /question)
stat= 0
if (strlowcase(ret ) eq 'yes') then stat = 1
return, stat
end



function move3_with_wigdet, motors, xpt, pvs, wids
;
; move 3 epics_motors while updating widget display -- kludgy
timeout = caGetTimeout()
retry   = caGetRetryCount()

caSetTimeout,    0.01
caSetRetryCount, 200

tol    = 0.0019
widn   = wids.pos
PVtest = pvs + '.DMOV'
PVrbv  = pvs + '.RBV'
PVvals = pvs + '.VAL'
j      = caput(pvs[0], xpt.x)
j      = caput(pvs[1], xpt.y)
j      = caput(pvs[2], xpt.z)
j      = 0
dmov   = 0
dm     = [0,0,0]
while (dmov eq 0) do begin
    j = j + 1
    for i = 0, 2 do begin
        if (dm[i] eq 0) then begin
            s = caget(PVtest[i], dm[i])
            s = caget(PVrbv[i],   r)
            s = caget(PVvals[i],  v)
            Widget_Control, widn[i], set_value = f2a(r)
            if (abs(v-r) le tol) then dm[i] = 1
        endif
    endfor
    if ((dm[0] eq 1) and (dm[1] eq 1) and (dm[2] eq 1)) then dmov = 1
    if (j le 1)   then dmov = 0
    if (j ge 500) then dmov = 1
endwhile      

for i = 0, 2 do begin
    s = caget(PVrbv[i],  r)
    Widget_Control, widn[i], set_value = f2a(r)
endfor

caSetTimeout,    timeout
caSetRetryCount, retry

return, 1
end



pro xyzstage_event, event
;
; event handler for xyzstage
;

Widget_Control, event.top, get_uval = p
Widget_Control, event.id,  get_uval = uval
ErrorNo = 0
Catch, ErrorNo
if (ErrorNo ne 0) then begin
    Catch, /CANCEL
    ErrA = ['Error!', 'Number' + strtrim(!error, 2), !Err_String]
    a = Dialog_Message(ErrA, /ERROR)
    return
endif

yes_or_no =  [ [' * No ', '   No '] , [ '   Yes', ' * Yes'] ]

stop_wid  = 0
; print, 'xyzstage_event uval: ', uval
will_exit=0
if (tag_names(event, /structure_name) eq 'WIDGET_TIMER') then begin
    dmov  = [0,0,0]
    for i = 0,2 do begin
        s = caget((*p).stage_pv[i]+'.RBV', rbv)
        Widget_Control, (*p).form.pos[i], set_value = f2a(rbv)
        s = caget((*p).stage_pv[i]+'.DMOV',d)
        dmov[i] = d
    endfor
    xtime = 15
    dm    = dmov[0] + dmov[1] + dmov[2]
    if (dm lt 3) then  xtime = 0.10
    Widget_Control, (*p).form.timer, time= xtime
endif else begin
    case uval of
        'exit':  begin
            for i = 0, 2 do obj_destroy, (*p).motors[i]
            will_exit=1
            Widget_Control, event.top, /destroy
        end
        'xypad': begin
            widget_control, (*p).form.timer,     time = 0.10
            x    = (*p).motors[0]->get_position() 
            dx   = (*p).xsign * (*p).step
            xpv  = (*p).stage_pv[0]
            y    = (*p).motors[1]->get_position() 
            dy   = (*p).ysign * (*p).step
            ypv  = (*p).stage_pv[1]
            case 1 of
                event.east:   x  = x + dx
                event.west:   x  = x - dx
                event.north:  y  = y + dy
                event.south:  y  = y - dy
                event.nwest:  begin
                    x  = x - dx
                    y  = y + dy
                end
                event.swest:  begin
                    x  = x - dx
                    y  = y - dy
                end
                event.neast:  begin
                    x  = x + dx
                    y  = y + dy
                end
                event.seast:  begin
                    x  = x + dx
                    y  = y - dy
                end
                else:  x = x
            endcase
            s = caput(xpv + '.VAL', x)
            s = caput(ypv + '.VAL', y)
            widget_control, (*p).form.timer,     time = 0.1
        end
        'zpad': begin
            xpv = (*p).stage_pv[2]
            x   = (*p).motors[2]->get_position() 
            dx  = (*p).zsign * (*p).zstep
            case 1 of
                event.left:  x = x - dx
                event.right: x = x + dx
                else:        x = x 
            endcase
            s = caput(xpv + '.VAL', x)            
            widget_control, (*p).form.timer,     time = 0.1
        end
        'xpos': begin
            pv  = (*p).stage_pv[0]
            Widget_Control, (*p).form.pos[0], get_value = t
            s   = caput(pv + '.VAL', a2f(t))
            Widget_Control, (*p).form.timer, time= 0.1
        end
        'ypos': begin
            pv  = (*p).stage_pv[1]
            Widget_Control, (*p).form.pos[1], get_value = t
            s   = caput(pv + '.VAL', a2f(t))
            Widget_Control, (*p).form.timer, time= 0.1
        end
        'zpos': begin
            pv  = (*p).stage_pv[2]
            Widget_Control, (*p).form.pos[2], get_value = t
            s   = caput(pv + '.VAL', a2f(t))
            Widget_Control, (*p).form.timer, time= 0.1
        end
        'step': begin
            (*p).step  = (*(*p).psteps)[event.index]
        end
        'zstep': begin
            (*p).zstep = (*(*p).psteps)[event.index]
        end
        'save': begin
            Widget_Control, (*p).form.save_name, get_value = str
            astr     = strcompress(str)
            nam1     = strtrim(astr[0],2)
            if (nam1 ne '') then begin
                ppt      = (*p).ppos
                names    = [(*ppt)[*].name]
                nn       = size(names)
                xpt      = (*ppt)[0]
                xpt.name = nam1
                xpt.x    = (*p).motors[0]->get_position()
                xpt.y    = (*p).motors[1]->get_position()
                xpt.z    = (*p).motors[2]->get_position()
                is_repeat= 0
                for i = 0, nn[1]-1 do begin
                    if (strlowcase(nam1) eq strlowcase(names[i])) then begin
                        is_repeat = i
                    endif
                endfor
                if (is_repeat eq 0) then begin
                    tmp = [(*ppt), xpt]
                endif else begin
                    tmp = (*ppt)
                    old = tmp[is_repeat]
                    do_overwrite = xyz_prompt_dialog('overwrite', old)
                    if (do_overwrite eq 1) then tmp[is_repeat] = xpt
                endelse
                                ; ptr_free, ppt
                                ; ptr_free, (*p).ppos
                ptmp     = ptr_new(tmp)
                nn       = size( tmp )
                pos_lis  = tmp[*].name
                (*p).ppos= ptmp
                Widget_Control, (*p).form.pos_list,  set_value= pos_lis
                Widget_Control, (*p).form.pos_list,  set_Droplist_SELECT = i
                Widget_Control, (*p).form.save_name, set_value = ''
                Widget_Control, (*p).form.save_name, xsize = 20
                                ; ptr_free, ptmp
                pmt = xyz_save_paramfile(p, use_dialog=0, file = 'xyz_autosave.def')
            endif
            end
            'erase': begin
            npos    = Widget_Info( (*p).form.pos_list, droplist_select=1)
            npoints = Widget_Info( (*p).form.pos_list, droplist_number=1)
            ppt     = (*p).ppos
            xpt     = (*ppt)[npos]
            do_erase= 1
            if ((*p).verify_erase eq 1) then begin
                do_erase = xyz_prompt_dialog('erase', xpt)
            endif
            if (do_erase eq 1)  then begin
                if (npoints gt 1) then begin
                    case npos of
                        0: tmp = (*ppt)[1:*]
                        npoints-1:  begin
                            if (npoints ge 2) then begin
                                tmp = (*ppt)[0:npoints-2]
                            endif else begin
                                tmp = [(*ppt)[0]]
                            endelse
                        end
                        else: tmp = [(*ppt)[0:npos-1], (*ppt)[npos+1:*] ]
                    endcase
                                ; ptr_free, ppt
                                ; ptr_free, (*p).ppos
                    ptmp     = ptr_new(tmp)
                    nn       = size( tmp )
                    pos_lis  = tmp[*].name
                    (*p).ppos= ptmp
                    Widget_Control, (*p).form.pos_list, set_value= pos_lis
                    Widget_Control, (*p).form.pos_list, set_Droplist_SELECT = nn[1]-1
                                ; ptr_free, ptmp
                endif else begin
                    ret = dialog_message([' Cannot erase all saved points', $
                                          ' Must keep at least 1 point'] )
                endelse
            endif
        end
        'move_to': begin
            npos    = Widget_Info( (*p).form.pos_list, droplist_select=1)
            ppt     = (*p).ppos
            xpt     = (*ppt)[npos]
            do_move = 1
            if ((*p).verify_move eq 1) then begin
                do_move = xyz_prompt_dialog('move', xpt)
            endif
            if (do_move eq 1) then begin
                i   = move3_with_wigdet((*p).motors, xpt, (*p).stage_pv, (*p).form)
            endif
        end
        'vmove_y': begin
            Widget_Control, (*p).form.vmove_y, set_Value=yes_or_no[1,1]
            Widget_Control, (*p).form.vmove_n, set_Value=yes_or_no[1,0]
            (*p).verify_move = 1
        end
        'vmove_n': begin
            Widget_Control, (*p).form.vmove_y, set_Value=yes_or_no[0,1]
            Widget_Control, (*p).form.vmove_n, set_Value=yes_or_no[0,0]
            (*p).verify_move = 0
        end
        'vover_y': begin
            Widget_Control, (*p).form.vover_y, set_Value=yes_or_no[1,1]
            Widget_Control, (*p).form.vover_n, set_Value=yes_or_no[1,0]
            (*p).verify_overwrite = 1
        end
        'vover_n': begin
            Widget_Control, (*p).form.vover_y, set_Value=yes_or_no[0,1]
            Widget_Control, (*p).form.vover_n, set_Value=yes_or_no[0,0]
            (*p).verify_overwrite = 0
        end
        'veras_y': begin
            Widget_Control, (*p).form.veras_y, set_Value=yes_or_no[1,1]
            Widget_Control, (*p).form.veras_n, set_Value=yes_or_no[1,0]
            (*p).verify_erase = 1
        end
        'veras_n': begin
            Widget_Control, (*p).form.veras_y, set_Value=yes_or_no[0,1]
            Widget_Control, (*p).form.veras_n, set_Value=yes_or_no[0,0]
            (*p).verify_erase = 0
        end
        'stop': begin
            for i = 0,2 do begin
                m = (*p).stage_pv[i]
                j = caput(m + '.SPMG', 0)
            endfor
            wait, 2
            for i = 0,2 do begin
                m = (*p).stage_pv[i]
                j = caput(m + '.SPMG', 3)
            endfor
        end
        'save_params':   begin
            pmt = xyz_save_paramfile(p, /use_dialog)
        end
        'saveas_params': begin
            pmt = xyz_save_paramfile(p, /use_dialog)
        end
        'read_params': begin
            pmt = xyz_read_paramfile(/use_dialog)
            if (pmt.valid eq 1) then begin
                (*p).stage_pv[0]   = pmt.mx
                (*p).stage_pv[1]   = pmt.my
                (*p).stage_pv[2]   = pmt.mz
                (*p).xsign         = pmt.xsign
                (*p).ysign         = pmt.ysign
                (*p).zsign         = pmt.zsign
                (*p).verify_move   = pmt.vmove
                (*p).verify_erase  = pmt.veras
                (*p).verify_overwrite = pmt.vover
                (*p).psteps        = pmt.psteps
                (*p).ppos          = pmt.ppos
                                ; look up new motor definitions, recreate motor object
                xo  = objarr(3)
                for i = 0, 2 do begin
                    obj_destroy, (*p).motors[i] 
                    xo[i] = obj_new('EPICS_MOTOR', (*p).stage_pv[i])
                endfor
                (*p).motors = xo
                xx  = (*p).motors[0]->get_position()
                xy  = (*p).motors[1]->get_position()
                xz  = (*p).motors[2]->get_position()
                Widget_Control, (*p).form.pos[0],   set_value = xx
                Widget_Control, (*p).form.pos[1],   set_value = xy
                Widget_Control, (*p).form.pos[2],   set_value = xz
                Widget_Control, (*p).form.step,     set_value = (*pmt.psteps)
                Widget_Control, (*p).form.zstep,    set_value = (*pmt.psteps)
                Widget_Control, (*p).form.pos_list, set_value = (*pmt.ppos)[*].name
                Widget_Control, (*p).form.pos_list, set_value = (*pmt.ppos)[*].name
                i  = 0
                if ( pmt.vmove eq 1) then i = 1
                Widget_Control, (*p).form.vmove_y,  set_Value = yes_or_no[i,1]
                Widget_Control, (*p).form.vmove_n,  set_Value = yes_or_no[i,0]
                i  = 0
                if ( pmt.veras eq 1) then i = 1
                Widget_Control, (*p).form.veras_y,  set_Value = yes_or_no[i,1]
                Widget_Control, (*p).form.veras_n,  set_Value = yes_or_no[i,0]
                i  = 0
                if ( pmt.vover eq 1) then i = 1
                Widget_Control, (*p).form.vover_y,  set_Value = yes_or_no[i,1]
                Widget_Control, (*p).form.vover_n,  set_Value = yes_or_no[i,0]
                
                                ; ptr_free, pmt.psteps
                                ; ptr_free, pmt.ppos
            endif
        end
        'position': x = 1
;         'name':     x = 1
        else:       x = 1
    endcase
endelse   
;

if (will_exit eq 1) then begin
    ptr_free, p        
endif

return
end




pro xyzstage
;
;
; define, create, and begin GUI for XYZ stage with ability to
; save and return to positions by name 
;
;
;-------------------

xpt          = {point,  name: 'Original Position', x:0.0, y: 0.0, z:0.1 }
step_choices = ['0.001', '0.002', '0.005', '0.010', '0.020', $
                '0.050', '0.100', '0.200', '0.500', '1.000']
psteps       = ptr_new(step_choices)
pzsteps      = ptr_new(step_choices)
;
stage_pv     = ['13IDC:m13', '13IDC:m14',  '13IDC:m15']

i_step = 3  ;  start with step at '0.010'

m1     = obj_new('EPICS_MOTOR', stage_pv[0])
m2     = obj_new('EPICS_MOTOR', stage_pv[1])
m3     = obj_new('EPICS_MOTOR', stage_pv[2])
motors = [m1, m2, m3]

xpt.x  = motors[0]->get_position()
xpt.y  = motors[1]->get_position()
xpt.z  = motors[2]->get_position()
xposa  = [xpt]
ppos   = ptr_new(xposa)
ax     = [0L,0L,0L]
form   = {pos:ax, step:0L, zstep:0L, xypad:0L, zpad:0L,$
          save_name:0L, pos_list:0L , stop:0L, timer:0L, $
          vmove_y:0L, vmove_n:0L, $
          vover_y:0L, vover_n:0L, $
          veras_y:0L, veras_n:0L     }

info   = {motors:motors, form:form, stage_pv:stage_pv, $
          xsign:1, ysign:1, zsign:1, step:0.0, zstep:0.0 , $
          verify_move:1, verify_erase:1, verify_overwrite:1, $
          psteps:psteps, ppos:ppos}

;
; note that, by convention, the sign for the 13IDC microprobe has
;  ysign = -1

info.xsign =  1
info.ysign =  1
info.zsign =  1

pmt = xyz_read_paramfile(use_dialog=0)
if (pmt.valid eq 1) then begin
    info.stage_pv[0]   = pmt.mx
    info.stage_pv[1]   = pmt.my
    info.stage_pv[2]   = pmt.mz
    info.xsign         = pmt.xsign
    info.ysign         = pmt.ysign
    info.zsign         = pmt.zsign
    info.verify_move   = pmt.vmove
    info.verify_erase  = pmt.veras
    info.verify_overwrite = pmt.vover
    info.psteps        = pmt.psteps
    xo  = objarr(3)
    for i = 0, 2 do begin
        obj_destroy, info.motors[i] 
        xo[i] = obj_new('EPICS_MOTOR', info.stage_pv[i])
    endfor
    info.motors = xo
    xo  = ''
    xpt.x  = info.motors[0]->get_position()
    xpt.y  = info.motors[1]->get_position()
    xpt.z  = info.motors[2]->get_position()
    xposa  = [xpt]
    ppos   = ptr_new(xposa)
    info.ppos = ppos
endif
xpt    = ''    
;-----------------------
; menus

main   = Widget_Base(title = 'XYZ Sample Stage', /col, app_mbar = mbar)
Widget_Control, default_font='Fixedsys' 

menu   = Widget_Button(mbar, value= 'File')
x      = Widget_Button(menu, value= 'Read Setup File ...', uval= 'read_params')
x      = Widget_Button(menu, value= 'Save Setup File ...', uval= 'save_params')
x      = Widget_Button(menu, value= 'Save As ...',         uval= 'saveas_params')
x      = Widget_Button(menu, value= 'Exit',                uval= 'exit', /sep)

menu   = Widget_Button(mbar, value= 'Options')

mx     = widget_button(menu, value = 'Verify Move To Position ... ', /menu)
info.form.vmove_y = widget_button(mx, value = ' * Yes ', uvalue='vmove_y')
info.form.vmove_n = widget_button(mx, value = '   No  ', uvalue='vmove_n')

mx     = widget_button(menu, value = 'Verify Overwrite Position ... ', /menu)
info.form.vover_y = widget_button(mx, value = ' * Yes ', uvalue='vover_y')
info.form.vover_n = widget_button(mx, value = '   No  ', uvalue='vover_n')


mx     = widget_button(menu, value = 'Verify Erase Position ... ', /menu)
info.form.veras_y = widget_button(mx, value = ' * Yes ', uvalue='veras_y')
info.form.veras_n = widget_button(mx, value = '   No  ', uvalue='veras_n')



; -----------------
; main page
;

frm    = Widget_Base(main, /row)
lfr    = Widget_Base(frm, /column)
rfr    = Widget_Base(frm, /column)

; -----------------
; xy frame

frame00    = Widget_Base(lfr, /col, /frame)
frame01    = Widget_Base(frame00, /row)
info.form.step = Widget_Droplist(frame01, value= step_choices, $
                                 uval= 'step',  title = 'Step Size  ')


Widget_Control, info.form.step, set_Droplist_SELECT = i_step
info.step = step_choices[i_step]
x      = Widget_Label(frame01,  value = 'mm ')



frame01    = Widget_Base(frame00, /row)
frame02    = Widget_Base(frame01, /col)


info.form.pos[0] = CW_Field(frame02,  title = 'X (horiz): ', $
                          xsize = 10, uval = 'xpos', $
                          value = f2a(info.motors[0]->get_position()), $
                          /return_events, /floating)
info.form.pos[1] = CW_Field(frame02,  title = 'Y (vert):  ', $
                          xsize = 10, uval = 'ypos', $
                          value = f2a(info.motors[1]->get_position()), $
                          /return_events, /floating)


info.form.xypad  = CW_CTRLPAD(frame01,   uvalue = 'xypad')

;
; -----------------
; z frame
frame00    = Widget_Base(lfr, /col, /frame)
frame01    = Widget_Base(frame00, /row)
info.form.zstep = Widget_Droplist(frame01, value= step_choices, $
                                  uval= 'zstep',  title = 'Step Size  ')

Widget_Control, info.form.zstep, set_Droplist_SELECT = i_step
info.zstep = step_choices[i_step]
x          = Widget_Label(frame01,  value = 'mm  <In Out>')

frame01    = Widget_Base(frame00, /row)
frame02    = Widget_Base(frame01, /col)


info.form.pos[2] = CW_Field(frame02,  title = 'Z (focus): ', $
                          xsize = 10, uval = 'zpos', $
                          value = f2a(info.motors[2]->get_position()), $
                          /return_events, /floating)

info.form.zpad  = CW_CTRL_LR(frame01,   uvalue = 'zpad')

;
; right-hand side

frame00  = Widget_Base(rfr, /col, /frame)
x        = Widget_Label(frame00,  value = 'Save Current Position as: ')
info.form.save_name = CW_Field(frame00, xsize=20,ysize=1, uval='save',$
                                /return_events, value="",Title="")

; frame01  = Widget_Base(frame00, /row)
; x   = Widget_Button(frame01, value = 'Save',  uval='save')

frame00  = Widget_Base(rfr, /col, /frame)

x   = Widget_Label(frame00,  value = 'Use Saved Positions:      ')

ss = xposa[*].name
info.form.pos_list = Widget_Droplist(frame00, value= ss,  $
                                        uval  = 'position', /dynamic_resize)

Widget_Control, info.form.pos_list, set_Droplist_SELECT = 0

frame01  = Widget_Base(frame00, /row)
x   = Widget_Button(frame01, value = 'Move To', uval='move_to')
x   = Widget_Button(frame01, value = 'Erase',   uval='erase')
info.form.timer = widget_base(frame00)

frame00  = Widget_Base(rfr, /col, /frame)
frame01  = Widget_Base(frame00, /row)
info.form.stop  = Widget_Button(frame01, value = 'Emergency Stop', uval='stop')

;
; render widgets, load info structure into main
;
p_info = ptr_new(info,/no_copy)
Widget_Control,       main, set_uval=p_info
Widget_Control,       main, /realize
xmanager, 'xyzstage', main, /no_block
return
end
