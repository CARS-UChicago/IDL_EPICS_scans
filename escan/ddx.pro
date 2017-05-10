pro define_detectors_event, event

MAX_SCA  =  8
MAX_ROI  = 10

Widget_Control, event.top, get_uvalue = p
Widget_Control, event.id,  get_uvalue = uval

mca = '-1'
roi = '-1'
i = strpos(uval, '.')
if (i gt 1) then begin
    roi = strmid(uval,i+1,strlen(uval))
    uval = strmid(uval,0,i)
    j    = strpos(roi,',')
    if (j ge 1) then begin
        mca  = strmid(roi,j+1, strlen(roi))
        roi = strmid(roi,0,j)
    endif
endif

; print, 'def det   uval = ', uval, ' | mca ', mca, ' | roi ', roi
case uval of
    'exit':  begin
        caSetTimeout, (*p).timeout
        caSetRetryCount, (*p).retry
        Widget_Control, event.top, /destroy
    end
    'sca_use_net': (*p).data.sca_use_net = event.index
    'med_use_net': (*p).data.med_use_net = event.index

    'save_med': begin
        (*p).data.save_med = event.select
    end
    'save_dead': begin
        (*p).data.save_dead = event.select
        Widget_Control, (*p).form.med_tot, get_value=t
        med_tot = a2f(t)
        for i = 0, (*p).form.med_max_elems-1 do begin
            if ((*p).data.mca_enable[i] eq 1) then  med_tot = med_tot + 2*event.select -1
        endfor
        if (med_tot gt 70) then begin
            mes = [' Too Many Detectors Defined. ', ' ', $
                  ' Up to 70 Detectors can be used', ' ', $
                  ' The detector settings have not been saved yet.']
            ret = dialog_message(mes)
            Widget_Control, (*p).form.save_dead, set_button=0
        endif else begin
            Widget_Control, (*p).form.med_tot, set_value=strtrim(string(fix(med_tot)),2)
            (*p).data.save_dead = event.select
            Widget_Control, (*p).form.save_dead, set_button=(*p).data.save_dead
        endelse
    end
    'save': begin
        print, ' saving results: '
        med_tot = 0
        if ((*p).data.use_med) then begin
            widget_control, (*p).form.med_tot, get_value = s_med_tot
            med_tot = a2f(s_med_tot)
        endif
        widget_control, (*p).form.sca_tot, get_value = s_sca_tot
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
            MAX_DET   = n_elements( (*p).det.countPV)
            isca   = idet
            in_use = (*p).data.med_use
            pr     = (*p).dgrp.prefix[1]
            net    = Widget_Info( (*p).form.med_use_net, /droplist_select)
            xtype='mca'
            if (strpos(pr,'aim_adc') ge 1) then xtype = 'aim_adc'
            for ir = 0, MAX_ROI - 1 do begin
                for id = 0, (*p).form.med_max_elems - 1 do begin
                    if (in_use[ir,id] eq 1) then begin
                        idet = idet + 1
                        nd   = id+1
                        x = get_detnam(prefix=pr,type=xtype,elem=nd,roi=ir,net=net)
                        (*p).det.countPV[idet] = x.countPV
                        (*p).det.desc[idet]    = x.full_desc
                        print, 'det ', idet, ' is mca: ' , x.full_desc, ' == ', x.countPV
                    endif
                endfor
            endfor
            if ((*p).data.save_dead eq 1) then begin
                for i = 0, (*p).form.med_max_elems - 1 do begin
                    if ((*p).data.mca_enable[i] eq 1) then begin                
                        idet = idet+1
                        if (idet lt MAX_DET) then begin
                            s_elem = strtrim(string(i+1,format='(i1.1)'),2)
                            if (i ge 9) then s_elem = strtrim(string(i+1,format='(i2.2)'),2)
                            (*p).det.countPV[idet] = pr + 'dxp' + s_elem + ':icrocr.VAL'
                            (*p).det.desc[idet]    = 'mca' + s_elem + ': Dead Time'
                        endif
                    endif
                endfor
            endif
            print, ' set ', idet+1 , ' detectors.'
            widget_control, (*p).form.med_tot, set_value = strtrim(fix(idet-isca),2)
            widget_control, (*p).form.sca_tot, set_value = strtrim(fix(isca+1),2)
            for ir = idet+1, 69 do begin
                (*p).det.countPV[ir] = ''
                (*p).det.desc[ir]    = ''
            endfor
            x  = (*p).es->set_param('save_med',(*p).data.save_med)
            x  = (*p).es->set_param('save_dead',(*p).data.save_dead)
            x  = (*p).es->set_param('detectors',(*p).det)
        endelse
    end
    'roi_use_all': begin
        widget_control, (*p).form.med_tot, get_value = s_med_tot
        med_tot = a2f(s_med_tot)
        ; print, ' roi use all ', roi, ' currently ', med_tot , ' in use '
        for i = 0, (*p).form.med_max_elems-1 do begin
            if ((*p).data.mca_enable[i] eq 1) then  begin
                in_use =  (*p).data.med_use[roi, i]
                if (in_use eq 0) then  med_tot = med_tot + 1
            endif
        endfor        

        if (med_tot gt 70) then begin
            mes = [' Too Many Detectors Defined. ', ' ', $
                   ' Up to 70 Detectors can be used', ' ', $
                   ' The detector settings have not been saved yet.']
            ret = dialog_message(mes)
        endif else begin
            for i = 0, (*p).form.med_max_elems-1 do begin
                if ((*p).data.mca_enable[i] eq 1) then  begin
                    Widget_Control, (*p).form.med_use[roi,i], get_value=t
                    in_use =  (*p).data.med_use[roi, i]
                    if (in_use eq 0) then begin
                        Widget_Control, (*p).form.med_use[roi,i], set_button=1
                        (*p).data.med_use[roi,i] = 1
                    endif
                endif
            endfor        
            widget_control, (*p).form.med_tot, set_value = strtrim(fix(med_tot),2)
        endelse

    end
    'roi_clr_all': begin
        widget_control, (*p).form.med_tot, get_value = s_med_tot
        med_tot = a2f(s_med_tot)
        ; print, ' roi clear all ', roi, ' currently ', med_tot , ' in use '
        for i = 0, (*p).form.med_max_elems-1 do begin
            Widget_Control, (*p).form.med_use[roi,i], get_value=t
            in_use =  (*p).data.med_use[roi, i]
            if (in_use eq 1) then begin
                Widget_Control, (*p).form.med_use[roi,i], set_button=0
                (*p).data.med_use[roi,i] = 0
                med_tot = med_tot - 1
            endif
        endfor        
        widget_control, (*p).form.med_tot, set_value = strtrim(fix(med_tot),2)
    end
    'sca': begin
        (*p).data.sca_use[roi] = event.select
        Widget_Control, (*p).form.sca_tot, get_value=t
        ns = a2f(t)
        ns = fix(ns + event.select*2 - 1)
        Widget_Control, (*p).form.sca_tot, set_value=string(ns)
    end
    'med': begin
        (*p).data.med_use[roi,mca-1] = event.select
        Widget_Control, (*p).form.med_tot, get_value=t
        ns = a2f(t)
        med_tot = fix(ns + event.select*2 - 1)
        if (med_tot gt 70) then begin
            mes = [' Too Many Detectors Defined. ', ' ', $
                   ' Up to 70 Detectors can be used', ' ', $
                   ' The detector settings have not been saved yet.']
            ret = dialog_message(mes)
        endif else begin
            widget_control, (*p).form.med_tot, set_value = strtrim(fix(med_tot),2)
        endelse
    end
    'elem': begin
        mca = roi-1
        (*p).data.mca_enable[mca] = event.select
        save_dead = (*p).data.save_dead
        widget_control, (*p).form.med_tot, get_value = s_med_tot
        med_tot = a2f(s_med_tot)

        if (save_dead eq 1) then begin
            if (event.select eq 1) then med_tot = med_tot + 1
            if (event.select eq 0) then med_tot = med_tot - 1
        endif

        if (event.select eq 0) then begin
            for ir = 0, MAX_ROI - 1 do begin
                in_use =  (*p).data.med_use[ir,mca]
                if (in_use eq 1) then begin
                    Widget_Control, (*p).form.med_use[ir,mca], set_button=0
                    (*p).data.med_use[ir,mca] = 0
                    med_tot = med_tot - 1
                endif
            endfor
        endif
        if (med_tot gt 70) then begin
            mes = [' Too Many Detectors Defined. ', ' ', $
                   ' Up to 70 Detectors can be used', ' ', $
                   ' The detector settings have not been saved yet.']
            ret = dialog_message(mes)
        endif else begin
            widget_control, (*p).form.med_tot, set_value = strtrim(fix(med_tot),2)
        endelse
    end
    else: tmp = 1 ; print, ' unknown event ', uval
endcase

    
;   event.select

return
end

function define_detectors, p
;
; GUI for selecting detectors by ROI
;
; print, ' This is define_detectors v 1.0'
N_MCAS   = 30
MAX_SCA  =  8
MAX_MED  = 16
MAX_ROI  = 10

ret = (*p).es->lookup_detectors()
det = (*p).es->get_param('detectors')
save_med  = (*p).es->get_param('save_med')
save_dead = (*p).es->get_param('save_dead')

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
         save_med:0L, save_dead:0L, $ 
         det_desc:lonarr(MAX_DET) , use_net: lonarr(MAX_DET), $
         sca_tot:0L, sca_use_net:1L, $
         elem_use:lonarr(MAX_MED), $
         med_tot:0L, med_use_net:0L, $
         med_use:lonarr(MAX_ROI,MAX_MED), $
         sca_use:lonarr(MAX_SCA), $
         med_max_elems:MAX_MED, $ 
         med_use_all:lonarr(MAX_ROI), $
         med_clr_all:lonarr(MAX_ROI)  }

data = {med_use:lonarr(MAX_ROI, MAX_MED), sca_use:lonarr(MAX_SCA) , $
        mca_enable:lonarr(MAX_MED), $
        med_use_net:0, sca_use_net:1 , med_proto:1, use_med:0, $
        use_sca:0, save_med:save_med, save_dead:save_dead}

info  = {es:(*p).es, form:form, $
         det:det,    dgrp:dgrp,  data:data,   $
         timeout:0.01, retry:100 ,$
         snames:strarr(MAX_SCA) }

info.timeout = caGetTimeout()
info.retry   = caGetRetryCount()
t0  = (info.timeout/ 20.) > 0.001
caSetTimeout,   t0
caSetRetryCount, 300


net_choices = ['Sum' , 'Net']

; Widget_Control, default_font='Fixedsys' 

; print, 'DEFINE DETECTORS'
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
    ; print,  'DET GROUP 0 ',  dgrp.max_elems[0], MAX_SCA
    for n = 0, MAX_SCA - 1 do begin
        uvs = 'sca.'  + strtrim(string(n),2)
        x   = get_detnam(prefix=pr,type='scaler',elem=1,roi=n,net=0)
        t   = x.desc
        if (x.desc eq '') then t = 'UNUSED'
        info.form.sca_use[n] = Widget_Button(fr0,  Value = t, uvalue = uvs)
        info.snames[n] = x.desc
    endfor
endif

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
;

; save full spectra
lf    = Widget_Base(sframe, /row)
x     = Widget_label(lf, value = 'Save Full MED spectra at each point?')
bbase = Widget_Base(lf, /row,/nonexclusive)
info.form.save_med = Widget_Button(bbase, xsize=60, value=' ', $
                                 uvalue = 'save_med')
Widget_Control, info.form.save_med, SET_BUTTON = save_med

; save dead time
lf    = Widget_Base(sframe, /row)
x     = Widget_label(lf, value = 'Save Percent Dead Time?')
bbase = Widget_Base(lf, /row,/nonexclusive)
info.form.save_dead = Widget_Button(bbase, xsize=60, value=' ', $
                                 uvalue = 'save_dead')
Widget_Control, info.form.save_dead, SET_BUTTON = save_dead

fr1    = Widget_Base(sframe, /col)

if ((dgrp.use_det[1] eq 1) and (dgrp.is_mca[1] eq 1)) then begin
    mp   = info.data.med_proto
    ; print, ' using MCA ', mp, ' as the master '
    pr   = dgrp.prefix[1]
    max_elems =  dgrp.max_elems[1]-1
    xtype='mca'
    if (strpos(pr,'aim_adc') ge 1) then xtype = 'aim_adc'

    if (max_elems ge 2) then begin
        fr0  = Widget_Base(fr1, /row)
        x    = Widget_Label(fr0,  xsize=110, Value = 'Use Element:')
        fr00 = Widget_Base(fr0, /row, /nonexclusive)
        for nm = 0, dgrp.max_elems[1]-1 do begin
            xim   = strtrim(string(nm+1),2)
            uvs  = 'elem.' + xim
            info.form.elem_use[nm] = Widget_Button(fr00, value = xim, uvalue= uvs)
            Widget_Control, info.form.elem_use[nm], set_button=1
            info.data.mca_enable(nm) = 1
        endfor
    endif

    for nr = 0, MAX_ROI - 1 do begin
        fr0  = Widget_Base(fr1, /row)
        uvs  = 'roi_use_all.' + strtrim(string(nr),2)
        x = get_detnam(prefix=pr,type=xtype,elem=mp,roi=nr,net=0)
        t = x.desc
        if (x.desc eq '') then t = 'UNUSED'
        ; print, '  label ', nr, pr,  t
        ; help,  x, /struc
        x    = Widget_Label(fr0,  xsize=60, Value = t)
        if (max_elems ge 2) then begin
            info.form.med_use_all[nr] = Widget_Button(fr0, value = 'Use All',   uvalue = uvs)
        endif
        fr00  = Widget_Base(fr0, /row, /nonexclusive)
        
        ; print,  'DET GROUP 1 ', dgrp.max_elems[1]
        for nm = 0, dgrp.max_elems[1]-1 do begin
            xim   = strtrim(string(nm+1),2)
            uvs  = 'med.' + strtrim(string(nr),2) + ','  + xim
            info.form.med_use[nr,nm] = Widget_Button(fr00,  value = xim, uvalue= uvs)
        endfor
        if (max_elems ge 2) then begin
            uvs  = 'roi_clr_all.' + strtrim(string(nr),2)
            info.form.med_clr_all[nr] = Widget_Button(fr0, value = 'Clear All', uvalue = uvs)
        endif
    endfor
endif

;
; set defaults by what is actually in use
ns_x = 0
nm_x = 0
medpr  = dgrp.prefix[1]
scapr  = dgrp.prefix[0]
info.form.med_max_elems = dgrp.max_elems[1]
info.data.use_sca= dgrp.use_det[0]
info.data.use_med= dgrp.use_det[1]

for i = 0, MAX_DET -1 do begin
    if ( det.countPV[i] ne '') then  begin
        if (info.data.use_sca and (strpos(det.countPV[i],'scaler') ge 1)) then begin 
            for n = 0, MAX_SCA -1 do begin
                if (det.desc[i] eq info.snames[n]) then begin
                    ns_x = ns_x + 1
                    info.data.sca_use[n] = 1
                    Widget_Control, info.form.sca_use[n] , set_button=1
                endif
            endfor
        endif else if (info.data.use_med and (strpos(det.countPV[i],'mca') ge 1)) then begin 
            for nm = 0, info.form.med_max_elems-1 do begin
                xdet = medpr + 'mca' + strtrim(string(nm+1),2) + '.R'
                for nr = 0, MAX_ROI -1 do begin
                    d  = xdet + strtrim(string(nr),2) 
                    dnet = strtrim(d,2) + 'N'
                    if ((det.countPV[i] eq d) or (det.countPV[i] eq dnet)) then begin
                        nm_x = nm_x + 1
                        info.data.med_use[nr,nm] = 1
                        Widget_Control, info.form.med_use[nr,nm] , set_button=1
                    endif
                endfor
            endfor
        endif
    endif           
endfor

if (info.data.use_sca) then begin
    widget_control, info.form.sca_tot, set_value = string(ns_x)
    Widget_Control, info.form.sca_use_net, set_droplist_select=info.data.sca_use_net 
endif
if (info.data.use_med) then begin
    widget_control, info.form.med_tot, set_value = string(nm_x)
    Widget_Control, info.form.med_use_net, set_droplist_select=info.data.med_use_net 
endif

base2  = Widget_Base(main,/row)
X      = Widget_Button(base2,  value = 'Save Changes',    uval='save')
X      = Widget_Button(base2,  value = 'Exit',            uval='exit')


M_COLS =  4
M_ROWS =  (MAX_DET/M_COLS) + 1
net_choices = ['Sum' , 'Net']

i = -1

Grid = Widget_Base(main, /ROW)
tcol = lonarr(M_COLS+1)

form_end:
Widget_Control, mine, /update

p_info = ptr_new(info,/NO_COPY)
Widget_Control, mine, set_uvalue=p_info
Widget_Control, mine, /REALIZE
xmanager, 'define_detectors', mine, /NO_BLOCK


return, 0
end
