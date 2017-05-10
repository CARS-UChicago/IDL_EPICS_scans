pro collect_offsets_event, event

Widget_Control, event.top, get_uvalue = p
Widget_Control, event.id,  get_uvalue = uval

case uval of
    'exit':   begin
        obj_destroy, (*p).scaler_obj
        Widget_Control, event.top, /destroy
    end
    'collect': begin
        sc   = (*p).scaler_pv
        ctime= (*p).ctime
        t    = caput((*p).sh_clos,1)
        t    = caget((*p).shutter, sh_status)
        wait, 0.5
        t    = caget(sc  + '.CONT', save_mode)
        t    = caget(sc  + '.TP'  , save_time)
        t    = caput(sc + '.TP'  , ctime)
        ;print, 'collect for ', ctime
        ;print, 'scaler pv  =' , sc
        (*p).scaler_obj->start, ctime
        wait, ctime+2
;;;        (*p).scaler_obj->wait

        counts  = (*p).scaler_obj->read()
; 
        sx  = size(counts)
        tx   = strtrim(string(counts[0],format='(i11)')) 
        ;print, 'counts size ', sx
        ;print, counts
        for i = 1, sx[1]-1 do begin 
            ax   = string(byte(i+65))
            ix   = strtrim(string(i+1,format='(i1.1)')) 
            cx   = strtrim(string(counts[i],format='(i10)')) 
            cpv  = sc + '_calc' + ix + '.CALC'
            ;print, i, ' ', ax, cx, ix, tx
            calc = ax + '-' + cx + '*(A/' + tx + ')'
            calc = strcompress(calc,/remove_all)
            j    = caput(cpv, calc)
            ;print, 'caput ', cpv, ' -> ', calc
        endfor
        ;print, 'collect offset done'

        Widget_Control, event.top, /destroy
;done: return scaler mode, count time, and re-open shutter
        t    = caput(sc + '.CONT', save_mode)
        t    = caput(sc + '.TP'  , save_time)
        t    = caput((*p).sh_open, 1)
        (*p).scaler_obj->start, 1
        (*p).scaler_obj->wait        
        obj_destroy, (*p).scaler_obj
    end
    'ctime': begin    
        Widget_Control, (*p).form.ctime, get_value=s
        x  = a2f(s)
        if (x le 0) then x = 10.0
        (*p).ctime = x
        Widget_Control, (*p).form.ctime, set_value=f2a(x)
    end
endcase
return
end

function collect_offsets, p
;
; gui for selecting detectors
mine      = Widget_Base(TITLE = 'Collect Scaler Offsets', /COLUMN, APP_MBAR = menubar)
fileMenu  = Widget_Button(menubar,  value = 'File')
exitMB    = Widget_Button(fileMenu, value = 'Exit',   uvalue = 'exit', /sep)

mainFRAME = Widget_Base(mine, /COLUMN)
 
;  gather all valid detector names (why not??)
;
dgrp   = (*p).es->get_param('detgroups')
scanPV = (*p).es->get_scan_param(0,scanPV)
prefix = (*p).es->get_param('prefix')
sh_clos= (*p).es->get_param('shutter_clos')
sh_open= (*p).es->get_param('shutter_open')
shutter= (*p).es->get_param('shutter_pv')

collect_time= 10.0

MAX_DTY   = n_elements(dgrp.name)
for i = 0,MAX_DTY-1 do begin
    pr = dgrp.prefix[i]
    if ((dgrp.use_det[i] eq 1) and (dgrp.is_mca[i] eq 0)) then begin
        scaler_pv = pr
    endif
endfor

so    = obj_new('EPICS_SCALER',scaler_pv)
form  = {ctime:0L, scan_pv:0L,dialog:0L}
info  = {es:(*p).es, form:form,ctime:collect_time, $
         shutter:shutter, sh_open:sh_open, sh_clos:sh_clos, $
         prefix:prefix, scaler_pv:scaler_pv, scaler_obj:so}

base   = Widget_Base(mainFrame,/col)
base2  = Widget_Base(base,/row)
str = 'Collect Offsets for ' + scaler_pv
x = Widget_Label(base2,  value =str)
base2  = Widget_Base(base,/row)
info.form.ctime = CW_FIELD(base2, /FLOAT,  /ROW,  XSIZE =7, $
                            title = 'Collection Time', UVALUE = 'ctime', $
                            VALUE = f2a(info.ctime), $
                            /return_events)
x = Widget_Label(base2,  value = 's')

base2  = Widget_Base(base,/row)
X      = Widget_Button(base2,  value = 'Collect Offsets',  uval='collect')
X      = Widget_Button(base2,  value = 'Quit',             uval='exit')

Widget_Control, mine, /update
p_info = ptr_new(info,/NO_COPY)
Widget_Control, mine, set_uvalue=p_info
Widget_Control, mine, /REALIZE
xmanager, 'collect_offsets', mine, /NO_BLOCK


return, 0
end










