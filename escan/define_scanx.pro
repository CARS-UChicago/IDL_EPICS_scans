pro define_scan_event, event

@scan_include
Widget_Control, event.id,  get_uval = uval
; 
dgr  = (*p).es->get_param('detgroups')
;

sc   = (*p).es->get_param('scan1')

uva  = strmid(uval, 0, strlen(uval)-1)
dnum = 0
if ((uva eq 'name') or (uva eq 'trig') or (uva  eq 'count') or $
    (uva eq 'prefix') or (uva  eq 'use') or (uva  eq 'mca')) then begin
    dnum = fix(strmid(uval, strlen(uval)-1, strlen(uval)))
    uval = uva
endif

case uval of
    'exit': begin
        dgr = (*p).es->get_param('detgroups')
        Widget_Control, event.top, /DESTROY
    end
    'save': begin
    end
    'exit': begin
        dgr = (*p).es->get_param('detgroups')
        Widget_Control, event.top, /DESTROY
    end
    'scan_prefix': begin
        Widget_Control, (*p).wid.pref, get_value=t
        x = (*p).es->set_param('prefix', strtrim(t,2))
    end
    'pdly': begin
        Widget_Control, (*p).wid.pdly, get_value=t
        sc.pdly  = double(strtrim(t,2))
    end
    'ddly': begin
        Widget_Control, (*p).wid.ddly, get_value=t
        sc.ddly  = double(strtrim(t,2))
    end
    'mfile': begin
        Widget_Control, (*p).wid.mfile, get_value=t
        x = (*p).es->set_param('monitorfile', strtrim(t,2) )
    end
    'sh_pv': begin
        Widget_Control, (*p).wid.sh_pv, get_value=t
        x = (*p).es->set_param('shutter_pv', strtrim(t,2) )
    end
    'name': begin
        Widget_Control, (*p).wid.dname[dnum], get_value=t
        dgr.name[dnum] = strtrim(t,2)
    end
    'trig': begin
        Widget_Control, (*p).wid.dtrig[dnum], get_value=t
        dgr.triggerpv[dnum] = strtrim(t,2)
    end
    'nelems': begin
        Widget_Control, (*p).wid.delems[dnum], get_value=t
        dgr.max_elems[dnum] = strtrim(t,2)
    end
    'count':  begin
        Widget_Control, (*p).wid.dcount[dnum], get_value=t
        dgr.counterpv[dnum] = strtrim(t,2)
    end
    'prefix': begin
        Widget_Control, (*p).wid.dpref[dnum], get_value=t
        dgr.prefix[dnum] = strtrim(t,2)
    end
    'mca': begin
        dgr.is_mca[dnum] = event.select
    end
    'use': begin
        dgr.use_det[dnum] = event.select
    end
endcase

u  = (*p).es->set_param(_scan, sc)
u  = (*p).es->set_param('detgroups', dgr)

return
end

function define_scan, p
;
; gui for defining 'other' scan parameters
;
MAX_DET = 10
main    = Widget_Base(TITLE = 'Scan Parameters', /COLUMN, APP_MBAR = menubar)
fMenu   = Widget_Button(menubar,  value = 'File')
exitMB  = Widget_Button(fMenu, value = 'Exit',   uvalue = 'exit', /sep)
mFRAME  = Widget_Base(main, /COLUMN)


current_scan = (*p).es->get_param('current_scan')
_scan   = 'scan' + string(strtrim(current_scan, 2))
sc      = (*p).es->get_param(_scan)

ddly    =  sc.ddly
pdly    =  sc.pdly
dgr     =  (*p).es->get_param('detgroups')
mfile   =  (*p).es->get_param('monitorfile')
sh_pv   =  (*p).es->get_param('shutter_pv')

prefix  = (*p).es->get_param('prefix')
n_dgr   = n_elements(dgr.name)
nzero   = lonarr(n_dgr)
wid     = {det_choice:0L, pref:0L,mfile:0L, sh_pv:0L, $
           det_elem:lonarr(MAX_DET), det_desc:lonarr(MAX_DET), $
           ddly:0L, pdly:0L, dtrig:nzero, dname:nzero, delems:nzero, $
           dcount:nzero,dpref:nzero,duse:nzero, dmca:nzero  } 
info    = {es:(*p).es, wid:wid}


base    = Widget_Base(mFrame, /row)
tt      = Widget_Base(base,/row)
info.wid.pref  = CW_FIELD(tt,  title= 'Scan Prefix:', uvalue = 'scan_prefix',$
                         value = prefix, xsize=13,$
                         /return_events)

info.wid.mfile = CW_FIELD(tt,  title= 'PV Save List:', $
                          uvalue = 'mfile',$
                          value = strtrim(string(mfile),2), xsize=20,$
                          /return_events)

info.wid.sh_pv = CW_FIELD(tt,  title= 'Shutter PV:', $
                          uvalue = 'sh_pv',$
                          value = strtrim(string(sh_pv),2), xsize=20,$
                          /return_events)

base    = Widget_Base(mFrame, /row)
tt      = Widget_Base(base,/row,/frame)

info.wid.pdly = CW_FIELD(tt,  title= 'Positioner Settling Time', uvalue = 'pdly',$
                         value = strtrim(string(pdly),2), xsize=13,$
                         /return_events, /floating)

info.wid.ddly = CW_FIELD(tt,  title= 'Detector Settling Time', uvalue = 'ddly',$
                         value = strtrim(string(ddly),2), xsize=13,$

                         /return_events, /floating)

base    = Widget_Base(mFrame, /row)
col     = Widget_Base(base,/col,/frame)
tt      = Widget_Base(col,/row)
xx       = Widget_Label(tt, xsize = 130, value = 'Detector Group') 
x       = Widget_Label(tt, xsize = 130, value = 'Prefix') 
x       = Widget_Label(tt, xsize = 130, value = 'Trigger') 
x       = Widget_Label(tt, xsize = 130, value = 'Counter') 
x       = Widget_Label(tt, xsize =  80, value = '# Elements') 
x       = Widget_Label(tt, xsize =  50, value = 'MCA?')
x       = Widget_Label(tt, xsize =  50, value = 'Use?')

uva     = ['name', 'prefix', 'trig', 'count', 'nelems', 'mca', 'use']
for i = 0, n_elements(dgr.name)-1 do begin
    f = Widget_Base(col, /row)
    uvs  = uva + strtrim(string(i),2)
    info.wid.dname[i] = CW_FIELD(f,  title= ' ', XSIZE = 18,  uvalue = uvs[0], $
                                 value = strtrim(dgr.name[i],2), $
                                 /return_events)
    info.wid.dpref[i] = CW_FIELD(f,  title= ' ', XSIZE = 18,  uvalue = uvs[1], $
                                 value = strtrim(dgr.prefix[i],2), $
                                 /return_events)
    info.wid.dtrig[i] = CW_FIELD(f,  title= ' ', XSIZE = 12,  uvalue = uvs[2], $
                                 value = strtrim(dgr.triggerpv[i],2), $
                                 /return_events)
    info.wid.dcount[i] = CW_FIELD(f,  title= ' ', XSIZE =12,  uvalue = uvs[3], $
                                  value = strtrim(dgr.counterpv[i],2), $
                                  /return_events)
    info.wid.delems[i] = CW_FIELD(f,  title= ' ', XSIZE =12,  uvalue = uvs[4], $
                                  value = strtrim(dgr.max_elems[i],2), $
                                  /return_events)
    bbase = Widget_Base(f, /row,/nonexclusive)
    info.wid.dmca[i] = Widget_Button(bbase,  xsize=60, Value = ' ', uvalue = uvs[5])
    info.wid.duse[i] = Widget_Button(bbase,  xsize=60, Value = ' ', uvalue = uvs[6])
    Widget_Control, info.wid.dmca[i] , SET_BUTTON = dgr.is_mca[i]
    Widget_Control, info.wid.duse[i] , SET_BUTTON = dgr.use_det[i]
endfor


base2  = Widget_Base(mFrame,/row)
X      = Widget_Button(base2,  value = 'Save',    uval='save')
X      = Widget_Button(base2,  value = 'Exit',    uval='exit')

p_info = ptr_new(info,/NO_COPY)
Widget_Control, main, set_uvalue=p_info, /REALIZE
xmanager, 'define_scan', main, /NO_BLOCK
return, 0
end

