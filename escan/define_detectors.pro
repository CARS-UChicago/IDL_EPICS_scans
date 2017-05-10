pro define_detectors_event, event

MAX_SCA  =  8
MAX_ROI  =  20
MAX_DET  =  70
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

Widget_Control, (*p).form.det_total, get_value=t
det_total        = a2f(t)
det_total_save   = a2f(t)
med_use_net = (*p).data.med_use_net
need_exit = 0
; print, 'DEF det: def det   uval = ', uval, ' | mca ', mca, ' | roi ', roi
case uval of
    'exit':  need_exit = 1
    'sca_use_net': (*p).data.sca_use_net = event.index
    'med_use_net': (*p).data.med_use_net = event.index

    'save_med': begin
        (*p).data.save_med = event.select
    end
    'save_dead': begin
        (*p).data.save_dead = event.select
        for i = 0, (*p).form.med_max_elems-1 do begin
            if ((*p).data.mca_enable[i] eq 1) then  det_total = det_total + 2*(2*event.select - 1)
        endfor
    end
    'save': begin
        ; print, ' saving results: '
        if (det_total le MAX_DET) then begin
            in_use = (*p).data.sca_use
            pr     = (*p).dgrp.prefix[0]
            sca_net= Widget_Info( (*p).form.sca_use_net, /droplist_select)
            idet   = -1
            if sca_net eq 2 then begin
                for is = 0, MAX_SCA - 1 do begin
                    if (in_use[is] eq 1) then begin
                        idet = idet + 1
                        x = get_detnam(prefix=pr,type='scaler',elem=1,roi=is,net=0)
                        (*p).det.countPV[idet] = x.countPV
                        (*p).det.desc[idet]    = x.full_desc
                    endif
                endfor
                for is = 0, MAX_SCA - 1 do begin
                    if (in_use[is] eq 1) then begin
                        idet = idet + 1
                        x = get_detnam(prefix=pr,type='scaler',elem=1,roi=is,net=1)
                        (*p).det.countPV[idet] = x.countPV
                        (*p).det.desc[idet]    = x.full_desc
                    endif
                endfor
            endif else begin
                for is = 0, MAX_SCA - 1 do begin
                    if (in_use[is] eq 1) then begin
                        idet = idet + 1
                        x = get_detnam(prefix=pr,type='scaler',elem=1,roi=is,net=sca_net)
                        (*p).det.countPV[idet] = x.countPV
                        (*p).det.desc[idet]    = x.full_desc
                    endif
                endfor
                    ; print, 'det ', idet, ' is scalar: ' , x.full_desc, ' == ', x.countPV
            endelse
; med            
            MAX_DET   = n_elements( (*p).det.countPV)
            isca   = idet
            in_use = (*p).data.med_use
            pr     = (*p).dgrp.prefix[1]
            med_net= Widget_Info( (*p).form.med_use_net, /droplist_select)
            ; print, 'med NET ', med_net, pr
            xtype='mca'
            if (strpos(pr,'med') ge 0)  then xtype = 'med'
            if (strpos(pr,'XMAP') ge 0) then xtype = 'med'
            if (strpos(pr,'SDD') ge 0) then xtype = 'med'
            if (strpos(pr,'Merc') ge 0) then xtype = 'med'
            if (strpos(pr,'aim_adc') ge 1) then xtype = 'aim_adc'
            ; print, 'med:: ', pr, xtype

            if med_net eq 2 then begin
                for ir = 0, MAX_ROI - 1 do begin
                    for id = 0, (*p).form.med_max_elems - 1 do begin
                        if (in_use[ir,id] eq 1) then begin
                            idet = idet + 1
                            nd   = id+1
                            x = get_detnam(prefix=pr,type=xtype,elem=nd,roi=ir,net=0)
                            (*p).det.countPV[idet] = x.countPV
                            (*p).det.desc[idet]    = x.full_desc
                            ; print, 'det ', idet, ' is mca: ' , x.full_desc, ' == ', x.countPV
                        endif
                    endfor
                endfor
                for ir = 0, MAX_ROI - 1 do begin
                    for id = 0, (*p).form.med_max_elems - 1 do begin
                        if (in_use[ir,id] eq 1) then begin
                            idet = idet + 1
                            nd   = id+1
                            ; print, ' event :: ', pr, ' : ', xtype, ' : ', idet
                            x = get_detnam(prefix=pr,type=xtype,elem=nd,roi=ir,net=1)
                            (*p).det.countPV[idet] = x.countPV
                            (*p).det.desc[idet]    = x.full_desc
                            ; print, 'det ', idet, ' is mca: ' , x.full_desc, ' == ', x.countPV
                        endif
                    endfor
                endfor
            endif else begin            
                ;print, 'med_net ', med_net, MAX_ROI,  (*p).form.med_max_elems 
                help, in_use
                for ir = 0, MAX_ROI - 1 do begin
                    for id = 0, (*p).form.med_max_elems - 1 do begin
                        if (in_use[ir,id] eq 1) then begin
                            idet = idet + 1
                            nd   = id+1
                            x = get_detnam(prefix=pr,type=xtype,elem=nd,roi=ir,net=med_net)
                            ; print, 'idet == ', idet
                            (*p).det.countPV[idet] = x.countPV
                            (*p).det.desc[idet]    = x.full_desc
                            ; print, 'det ', idet, ' is mca: ' , x.full_desc, ' == ', x.countPV
                        endif
                    endfor
                endfor
            endelse
            if ((*p).data.save_dead eq 1) then begin
                for i = 0, (*p).form.med_max_elems - 1 do begin
                    if ((*p).data.mca_enable[i] eq 1) then begin                
                        if (idet lt MAX_DET) then begin
                            s_elem = strtrim(string(i+1,format='(i1.1)'),2)
                            if (i ge 9) then s_elem = strtrim(string(i+1,format='(i2.2)'),2)
                            testpv = pr + 'dxp' + s_elem + ':InputCountRate'
                            s = caget(testpv, testval)
                            if s eq 0 then begin                      
                                idet = idet+1
                                (*p).det.desc[idet]    = 'dxp' + s_elem + ':ICR'
                                (*p).det.countPV[idet] = testpv
                            endif
                        endif
                    endif
                endfor
                for i = 0, (*p).form.med_max_elems - 1 do begin
                    if ((*p).data.mca_enable[i] eq 1) then begin                
                        if (idet lt MAX_DET) then begin
                            s_elem = strtrim(string(i+1,format='(i1.1)'),2)
                            if (i ge 9) then s_elem = strtrim(string(i+1,format='(i2.2)'),2)
                            testpv = pr + 'dxp' + s_elem + ':OutputCountRate'
                            s = caget(testpv, testval)
                            if s eq 0 then begin                      
                                idet = idet+1
                                (*p).det.desc[idet]    = 'dxp' + s_elem + ':OCR'
                                (*p).det.countPV[idet] = testpv
                            endif
                        endif
                    endif
                endfor
            endif
            ; print, ' set ', idet+1 , ' detectors.'
            det_total = idet+1
            for ir = idet+1, 69 do begin
                (*p).det.countPV[ir] = ''
                (*p).det.desc[ir]    = ''
            endfor
            x  = (*p).es->set_param('save_med',(*p).data.save_med)
            x  = (*p).es->set_param('save_dead',(*p).data.save_dead)
            x  = (*p).es->set_param('detectors',(*p).det)
        endif
    end
    'roi_use_all': begin
        ; print, ' roi use all ', roi, ' # det = ', tot, 'use net = ', use_net
        for i = 0, (*p).form.med_max_elems-1 do begin
            if ((*p).data.mca_enable[i] eq 1) then  begin
                in_use =  (*p).data.med_use[roi, i]
                if (in_use eq 0) then  begin
                    incr = 1
                    if med_use_net eq 2 then incr = 2
                    det_total = det_total + incr
                endif
            endif
        endfor        

        if (det_total le MAX_DET) then begin
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
        endif

    end
    'roi_clr_all': begin
        ; print, ' roi clear all ', roi, ' currently '
        for i = 0, (*p).form.med_max_elems-1 do begin
            Widget_Control, (*p).form.med_use[roi,i], get_value=t
            in_use =  (*p).data.med_use[roi, i]
            if (in_use eq 1) then begin
                Widget_Control, (*p).form.med_use[roi,i], set_button=0
                (*p).data.med_use[roi,i] = 0
                decr = 1
                if med_use_net eq 2 then decr = 2
                det_total = det_total - decr
            endif
        endfor        
    end
    'sca': begin
        (*p).data.sca_use[roi] = event.select
    end
    'med': begin
        ; print, 'med event  ', event.select, roi, mca, med_use_net
        (*p).data.med_use[roi,mca-1] = event.select
        factor = 2*event.select - 1
        incr   = 1
        if med_use_net eq 2 then incr = 2
        det_total = det_total + factor * incr
    end
    'elem': begin
        mca = roi-1
        (*p).data.mca_enable[mca] = event.select
        save_dead = (*p).data.save_dead
        if (save_dead eq 1) then begin
            if (event.select eq 1) then det_total = det_total + 2
            if (event.select eq 0) then det_total = det_total - 2
        endif

        if (event.select eq 0) then begin
            for ir = 0, MAX_ROI - 1 do begin
                in_use =  (*p).data.med_use[ir,mca]
                if (in_use eq 1) then begin
                    Widget_Control, (*p).form.med_use[ir,mca], set_button=0
                    (*p).data.med_use[ir,mca] = 0
                    decr = 1
                    if med_use_net eq 2 then decr = 2
                    det_total = det_total - decr

                endif
            endfor
        endif
    end
    else: tmp = 1 ; print, ' unknown event ', uval
endcase

; set number of detectors if it has changed
if det_total ne det_total_save then  begin
    Widget_Control, (*p).form.det_total, set_value = strtrim(fix(det_total),2)
    if (det_total gt MAX_DET) then begin
        mes = [' Too Many Detectors Defined. ', ' ', $
               ' Up to 70 Detectors can be used', ' ', $
               ' The detector settings have not been saved yet.']
        ret = dialog_message(mes)
    endif 
endif

if need_exit eq 1 then begin
    caSetTimeout, (*p).timeout
    caSetRetryCount, (*p).retry
    Widget_Control, event.top, /destroy
endif

return
end

function define_detectors, p
;
; GUI for selecting detectors by ROI
;

print, ' This is define_detectors v 1.0 b'

N_MCAS  = 30
MAX_SCA  =  8
MAX_MED  = 16
MAX_ROI  = 20

MAX_DET   = 70

net_choices = ['Sum' , 'Net', 'Sum and Net']

ret = (*p).es->lookup_detectors()
det = (*p).es->get_param('detectors')
save_med  = (*p).es->get_param('save_med')
save_dead = (*p).es->get_param('save_dead')

det_save  = det

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
         det_total:0L, sca_use_net:1L, $
         elem_use:lonarr(MAX_MED), $
         med_use_net:0L, $
         med_use:lonarr(MAX_ROI,MAX_MED), $
         sca_use:lonarr(MAX_SCA), $
         med_max_elems:MAX_MED, $ 
         med_use_all:lonarr(MAX_ROI), $
         med_clr_all:lonarr(MAX_ROI)  }

data = {med_use:lonarr(MAX_ROI, MAX_MED), sca_use:lonarr(MAX_SCA) , $
        mca_enable:lonarr(MAX_MED),   det_total:0L, $
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



;Widget_Control, default_font='Fixedsys' 
;print, 'DEFINE DETECTORS'
;
; Scalers
sframe = Widget_Base(main,   /col, /frame)

lf     = Widget_Base(sframe, /row)
x      = Widget_label(lf, value = '    Total Number of Detectors Used (max = 70): ')
info.form.det_total = Widget_Label(lf, value = '   ',xsize=90)

lf     = Widget_Base(sframe, /row)
x      = Widget_label(lf, value = ' Scalars:  Use ')
info.form.sca_use_net = Widget_DROPLIST(lf, value = net_choices,  $
                                 uvalue = 'sca_use_net', /dynamic_resize)


x      = Widget_label(lf, value = ' Counts ')

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

;
; MCA
sframe = Widget_Base(main,   /col, /frame)
lf     = Widget_Base(sframe, /row)
x      = Widget_label(lf, value = ' MED  Detector:  Use ')
info.form.med_use_net = Widget_DROPLIST(lf, value = net_choices,  $
                                 uvalue = 'med_use_net', /dynamic_resize)
x      = Widget_label(lf, value = ' Counts ')


; save full spectra
lf    = Widget_Base(sframe, /row)
x     = Widget_label(lf, value = 'Save Full MED spectra at each point?')
bbase = Widget_Base(lf, /row,/nonexclusive)
info.form.save_med = Widget_Button(bbase, xsize=60, value=' ', $
                                 uvalue = 'save_med')
Widget_Control, info.form.save_med, SET_BUTTON = save_med

; save dead time
x     = Widget_label(lf, value = 'Save ICR and OCR?')
bbase = Widget_Base(lf, /row,/nonexclusive)
info.form.save_dead = Widget_Button(bbase, xsize=60, value=' ', uvalue = 'save_dead')
Widget_Control, info.form.save_dead, SET_BUTTON = save_dead

fr1    = Widget_Base(sframe, /col)

; print,  'in define detectors ' , dgrp.prefix[1], dgrp.use_det[1], dgrp.is_mca[1]

if ((dgrp.use_det[1] eq 1) and (dgrp.is_mca[1] eq 1)) then begin
    mp   = info.data.med_proto
    ; print, ' using MCA ', mp, ' as the master '
    pr   = dgrp.prefix[1]
    max_elems =  dgrp.max_elems[1]-1
    xtype='mca'
    if (strpos(pr,'mca') ge 0)  then xtype = 'mca'
    if (strpos(pr,'med') ge 0)  then xtype = 'med'
    if (strpos(pr,'XMAP') ge 0) then xtype = 'med'
    if (strpos(pr,'SDD') ge 0)  then xtype = 'med'
    if (strpos(pr,'Merc') ge 0) then xtype = 'med'

    ; print, 'YO xtype=',xtype, max_elems, MAX_ROI

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
        t = strtrim(x.desc,2)
        ; print, 'GET DETNAM ', pr, xtype, mp, nr, t

        if 1 eq 1 then begin ; if (t ne '') then begin
            ; print, '  label ', nr, ' : ',  pr,   ' : ', t
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
        endif
    endfor
endif

;
; set defaults by what is actually in use
ndet_used = 0
medpr  = dgrp.prefix[1]
scapr  = dgrp.prefix[0]
info.form.med_max_elems = dgrp.max_elems[1]
info.data.use_sca= dgrp.use_det[0]
info.data.use_med= dgrp.use_det[1]

; print, 'Reading Current Detector Settings'

tmp_med_sum = 0
tmp_med_net = 0

for i = 0, MAX_DET-1 do begin
    ; print , ' ==== ', i,det.countPV[i]
    if (det.countPV[i] ne '') then  begin
        ndet_used = ndet_used + 1
        ;print, 'det ', i, ' => ', det.countPV[i]
        if (info.data.use_sca and (strpos(det.countPV[i],'scaler') ge 1)) then begin 
            for n = 0, MAX_SCA -1 do begin
                if (det.desc[i] eq info.snames[n]) then begin
                    info.data.sca_use[n] = 1
                    Widget_Control, info.form.sca_use[n] , set_button=1
                endif
            endfor
        endif else if (info.data.use_med and (strpos(det.countPV[i],'mca') ge 1)) then begin 
            im   = strpos(det.countPV[i],'mca')
            key  = strmid(det.countPV[i],im+3,strlen(det.countPV[i]))
            ;print, 'should check box for MCA ROI => ', det.countPV[i], ' / ', key
            idot = strpos(key,'.')
            nmca = fix(strmid(key,0,idot)) - 1
            if (strmid(key,strlen(key)-1,strlen(key)) eq 'N') then  begin
                key = strmid(key,0, strlen(key)-1)
                tmp_med_net = 1
            endif else begin
                tmp_med_sum = 1
            endelse

            nroi = fix(strmid(key,idot+2,strlen(key))) 
            info.data.med_use[nroi,nmca] = 1
            ;print, 'med use ', key, nroi, nmca,  MAX_DET, MAX_ROI, MAX_MED

            Widget_Control, info.form.med_use[nroi,nmca] , set_button=1


        endif
    endif           
endfor

info.data.med_use_net = 0  ; use sum
if (tmp_med_net eq 1) then begin
    if (tmp_med_sum eq 1) then info.data.med_use_net = 2 
    if (tmp_med_sum eq 0) then info.data.med_use_net = 1
endif

base2  = Widget_Base(main,/row)
X      = Widget_Button(base2,  value = 'Save Changes',    uval='save')
X      = Widget_Button(base2,  value = 'Exit',            uval='exit')
info.data.det_total = ndet_used
widget_control, info.form.det_total, set_value = strtrim(string(ndet_used),2)

if (info.data.use_sca) then begin
    Widget_Control, info.form.sca_use_net, set_droplist_select=info.data.sca_use_net 
endif
if (info.data.use_med) then begin
    Widget_Control, info.form.med_use_net, set_droplist_select=info.data.med_use_net 
endif


M_COLS =  4
M_ROWS =  (MAX_DET/M_COLS) + 1

i = -1

Grid = Widget_Base(main, /ROW)
tcol = lonarr(M_COLS+1)

form_end:
Widget_Control, mine, /update

p_info = ptr_new(info,/NO_COPY)
Widget_Control, mine, set_uvalue=p_info
Widget_Control, mine, /REALIZE
xmanager, 'define_detectors', mine, /NO_BLOCK
print,'c'

return, 0
end
