pro meta_detectors_event, event

MAX_SCA  = 10
MAX_MED  = 16
MAX_ROI  = 10

Widget_Control, event.top, get_uvalue = p
Widget_Control, event.id,  get_uvalue = uval

mca = '-1'
elem = '-1'
i = strpos(uval, '.')
if (i gt 1) then begin
    elem  = strmid(uval,i+1,strlen(uval))
    uval = strmid(uval,0,i)
    j    = strpos(elem,',')
    if (j ge 1) then begin
        mca = strmid(elem,j+1, strlen(elem))
        elem = strmid(elem,0,j)
    endif
endif

case uval of
    'exit':  begin
        caSetTimeout, (*p).timeout
        caSetRetryCount, (*p).retry
        Widget_Control, event.top, /destroy
    end
    'sca_use_net': (*p).data.sca_use_net = event.index
    'med_use_net': (*p).data.med_use_net = event.index
    'save': begin
        ; print, ' saving results: '
        widget_control, (*p).form.med_tot, get_value = s_med_tot
        widget_control, (*p).form.sca_tot, get_value = s_sca_tot
        med_tot = a2f(s_med_tot)
        sca_tot = a2f(s_sca_tot)
        tot     = med_tot + sca_tot
        if (tot gt 70) then begin
            mes = [' Too Many Detectors Defined. ', ' ', $
                  ' Up to 70 Detectors can be used', ' ', $
                  ' The detector settings have not been saved yet.']
            ret = dialog_message(mes)
        endif else begin
; scalars
            in_use = (*p).data.sca_use
            pr     = (*p).dgrp.prefix[0]
            net    = Widget_Info( (*p).form.sca_use_net, /droplist_select)
            idet   = -1
            for is = 0, MAX_SCA - 1 do begin
                if (in_use[is] eq 1) then begin
                    idet = idet + 1
                    x = get_detnam(prefix=pr,type='scaler',elem=1,roi=is,net=net)
                    (*p).det.countPV[idet] = x.countPV
                    (*p).det.desc[idet]    = x.full_desc
                    ; print, 'det ', idet, ' is scalar: ' , x.full_desc, ' == ', x.countPV
                endif
            endfor
           
; med            
            in_use = (*p).data.med_use
            pr     = (*p).dgrp.prefix[1]
            net    = Widget_Info( (*p).form.med_use_net, /droplist_select)
            for ir = 0, MAX_ROI - 1 do begin
                for id = 0, MAX_MED - 1 do begin
                    if (in_use[ir,id] eq 1) then begin
                        idet = idet + 1
                        nd   = id+1
                        x = get_detnam(prefix=pr,type='med:mca',elem=nd,roi=ir,net=net)
                        (*p).det.countPV[idet] = x.countPV
                        (*p).det.desc[idet]    = x.full_desc
                        ; print, 'det ', idet, ' is mca: ' , x.full_desc, ' == ', x.countPV
                    endif
                endfor
            endfor
            x  = (*p).es->set_param('detectors',(*p).det)
        endelse
    end
    'roi_use_all': begin
        widget_control, (*p).form.med_tot, get_value = s_med_tot
        med_tot = a2f(s_med_tot)
        ; print, ' roi use all ', elem, ' currently ', med_tot , ' in use '
        for i = 0, MAX_MED -1 do begin
            Widget_Control, (*p).form.med_use[elem,i], get_value=t
            in_use =  (*p).data.med_use[elem, i]
            if (in_use eq 0) then begin
                Widget_Control, (*p).form.med_use[elem,i], set_button=1
                med_tot = med_tot + 1
            endif
            s_med_tot = strtrim(fix(med_tot),2)
            widget_control, (*p).form.med_tot, set_value = s_med_tot
        endfor        
    end
    'sca': begin
        (*p).data.sca_use[elem] = event.select
        Widget_Control, (*p).form.sca_tot, get_value=t
        ns = a2f(t)
        ns = fix(ns + event.select*2 - 1)
        Widget_Control, (*p).form.sca_tot, set_value=string(ns)
    end
    'med': begin
        (*p).data.med_use[elem,mca-1] = event.select
        Widget_Control, (*p).form.med_tot, get_value=t
        ns = a2f(t)
        ns = fix(ns + event.select*2 - 1)
        Widget_Control, (*p).form.med_tot, set_value=string(ns)
    end
    else: print, ' unknown event ', uval
endcase

    
;   event.select

return
end

function meta_detectors, p
;
; GUI for selecting detectors by ROI
;
N_MCAS   = 30
MAX_SCA  = 10
MAX_MED  = 16
MAX_ROI  = 10

ret = (*p).es->lookup_detectors()
det = (*p).es->get_param('detectors')

det_save  = det
MAX_DET   = n_elements( det.countPV)

;
mine      = Widget_Base(TITLE = 'Define Detectors', /COLUMN, APP_MBAR = menubar)
fileMenu  = Widget_Button(menubar,  value = 'File')
saveMB    = Widget_Button(fileMenu, value = 'Save',   uvalue = 'save' )
exitMB    = Widget_Button(fileMenu, value = 'Exit',   uvalue = 'exit', /sep)

main      = Widget_Base(mine, /COLUMN)
TMP       = Widget_Base(main, /ROW)
; 
;  gather all valid detector names (why not??)
;
dgrp   = (*p).es->get_param('detgroups')
scanPV = (*p).es->get_scan_param(0,scanPV)
prefix = (*p).es->get_param('prefix')

; 
MAX_DTY   = n_elements(dgrp.name)

form  = {det_choice:0, det_elem:lonarr(MAX_DET), $
         det_desc:lonarr(MAX_DET) , use_net: lonarr(MAX_DET), $
         sca_tot:0L, sca_use_net:1L, $
         med_tot:0L, med_use_net:0L, $
         med_use:lonarr(MAX_ROI,MAX_MED), $
         sca_use:lonarr(MAX_SCA), $
         med_use_all:lonarr(MAX_ROI) }

data = {med_use:lonarr(MAX_ROI, MAX_MED), sca_use:lonarr(MAX_SCA) , $
        med_use_net:0, sca_use_net:1 , med_proto:7}

info  = {es:(*p).es, form:form, $
         det:det,    dgrp:dgrp,  data:data,   $
         timeout:0.01, retry:100 ,$
         snames:strarr(MAX_SCA) }

info.timeout = caGetTimeout()
info.retry   = caGetRetryCount()
t0 =  (info.timeout/ 10.) > 0.001
caSetTimeout,   t0
caSetRetryCount, 300


net_choices = ['Sum' , 'Net']

Widget_Control, default_font='Fixedsys' 

print, ' Detectors: scalers'
;
; Scalers
sframe = Widget_Base(main,   /col, /frame)
lf     = Widget_Base(sframe, /row)
x      = Widget_label(lf, value = ' Scalars:  Use ')
info.form.sca_use_net = Widget_DROPLIST(lf, value = net_choices,  $
                                 uvalue = 'sca_use_net', /dynamic_resize)


x      = Widget_label(lf, value = ' Counts ')
x      = Widget_label(lf, value = '    Total Number Used ')
info.form.sca_tot = Widget_Label(lf, value = ' ')

fr0    = Widget_Base(sframe, /row, /nonexclusive)

if ((dgrp.use_det[0] eq 1) and (dgrp.is_mca[0] eq 0)) then begin
    pr  = dgrp.prefix[0]
    for n = 0, MAX_SCA - 1 do begin
        uvs = 'sca.'  + strtrim(string(n),2)
        x   = get_detnam(prefix=pr,type='scaler',elem=1,roi=n,net=0)
        t   = x.desc
        if (x.desc eq '') then t = 'UNUSED'
        info.form.sca_use[n] = Widget_Button(fr0,  Value = t, uvalue = uvs)
        info.snames[n] = x.desc
    endfor
endif

print, ' Detectors: MCA  ' , MAX_ROI
;
; MCA
sframe = Widget_Base(main,   /col, /frame)
lf     = Widget_Base(sframe, /row)
x      = Widget_label(lf, value = ' MED  Detector:  Use ')
info.form.med_use_net = Widget_DROPLIST(lf, value = net_choices,  $
                                 uvalue = 'med_use_net', /dynamic_resize)
x      = Widget_label(lf, value = ' Counts ')
x      = Widget_label(lf, value = '    Total Number Used ')
info.form.med_tot = Widget_Label(lf, value = ' ')

fr1    = Widget_Base(sframe, /col)

if ((dgrp.use_det[1] eq 1) and (dgrp.is_mca[1] eq 1)) then begin
    mp   = info.data.med_proto
    ; print, ' using MCA ', mp, ' as the master '
    for nr = 0, MAX_ROI - 1 do begin
        fr0  = Widget_Base(fr1, /row)
        uvs  = 'roi_use_all.' + strtrim(string(nr),2)
        pr   = dgrp.prefix[1]
        x = get_detnam(prefix=pr,type='mca',elem=mp,roi=nr,net=0)
        t = x.desc
        if (x.desc eq '') then t = 'UNUSED'
        x    = Widget_Label(fr0,  xsize=60, Value = t)
        info.form.med_use_all[nr] = Widget_Button(fr0, value = 'Use All', uvalue = uvs)
        fr00  = Widget_Base(fr0, /row, /nonexclusive)
        
        for nm = 0, MAX_MED-1 do begin
            xim   = strtrim(string(nm+1),2)
            uvs  = 'med.' + strtrim(string(nr),2) + ','  + xim
            info.form.med_use[nr,nm] = Widget_Button(fr00,  value = xim, uvalue= uvs)
        endfor
    endfor
endif


print, ' Detectors: defaults'
;
; set defaults by what is actually in use
ns_x = 0
nm_x = 0
medpr  = dgrp.prefix[1]
scapr  = dgrp.prefix[0]

for i = 0, MAX_DET -1 do begin
    if ( det.countPV[i] ne '') then  begin
        if (strpos(det.countPV[i],'scaler') ge 1) then begin 
            for n = 0, MAX_SCA -1 do begin
                if (det.desc[i] eq info.snames[n]) then begin
                    ns_x = ns_x + 1
                    info.data.sca_use[n] = 1
                    Widget_Control, info.form.sca_use[n] , set_button=1
                endif
            endfor
        endif else if (strpos(det.countPV[i],'mca') ge 1) then begin 
            for nm = 0, MAX_MED -1 do begin
                xdet = medpr + 'mca' + strtrim(string(nm+1),2) + '.R'
                for nr = 0, MAX_ROI -1 do begin
                    d  = xdet + strtrim(string(nr),2) 
                    if (det.countPV[i] eq d) then begin
                        nm_x = nm_x + 1
                        info.data.med_use[nr,nm] = 1
                        Widget_Control, info.form.med_use[nr,nm] , set_button=1
                    endif
                endfor
            endfor
        endif
    endif           
endfor

widget_control, info.form.sca_tot, set_value = string(ns_x)
widget_control, info.form.med_tot, set_value = string(nm_x)


base2  = Widget_Base(main,/row)
X      = Widget_Button(base2,  value = 'Save Changes',    uval='save')
X      = Widget_Button(base2,  value = 'Exit',            uval='exit')


M_COLS =  4
M_ROWS =  (MAX_DET/M_COLS) + 1
net_choices = ['Sum' , 'Net']

Widget_Control, info.form.sca_use_net, set_droplist_select=info.data.sca_use_net 
Widget_Control, info.form.med_use_net, set_droplist_select=info.data.med_use_net 

i = -1

Grid = Widget_Base(main, /ROW)
tcol = lonarr(M_COLS+1)

form_end:
Widget_Control, mine, /update

p_info = ptr_new(info,/NO_COPY)
Widget_Control, mine, set_uvalue=p_info
Widget_Control, mine, /REALIZE
xmanager, 'meta_detectors', mine, /NO_BLOCK


return, 0
end










