pro meta_detectors_event, event

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

print, uval, ' , ', elem, ' , ', mca

case uval of
    'save': begin
        print, ' save results'
    end
    'exit': begin
        print, ' exit '
    end
    'sca_use_net': begin
        print, ' sca_use_net '
    end
    'med_use_net': begin
        print, ' med_use_net '
    end
    'sca_use': begin
        print, ' sca_use element: ', elem
    end
    'roi_use_all': begin
        print, ' roi use all ', elem
    end
    'med': begin
        print, ' sca_use element: ', elem
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
print, ' define_meta_detectors '

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
         sca_used:0L, sca_use_net:0L, $
         med_used:0L, med_use_net:0L, $
         med_use_mca:lonarr(MAX_ROI,MAX_MED) }

info  = {es:(*p).es, form:form, det_save:det_save, $
         det:det,   $
         timeout:0.001, retry:50 ,$
         sbutton:lonarr(MAX_SCA), s_use_net:1L, snames:strarr(MAX_SCA) , $
         sca_inuse:0 , med_inuse:0 , $
         mbutton:lonarr(MAX_ROI), m_use_all:lonarr(MAX_ROI), $
         m_use_net:1L, mnames:strarr(MAX_ROI) }


info.timeout = caGetTimeout()
info.retry   = caGetRetryCount()
t0 =  (info.timeout/ 10.) > 0.001
caSetTimeout,   t0
caSetRetryCount, 25


net_choices = ['Sum' , 'Net']

; Widget_Control, default_font='Fixedsys' 


;
; Scalars
sframe = Widget_Base(main,   /col,/frame)
lf     = Widget_Base(sframe, /row)
x      = Widget_label(lf, value = ' Scalars:  Use ')
info.form.sca_use_net = Widget_DROPLIST(lf, value = net_choices,  $
                                 uvalue = 'sca_use_net', /dynamic_resize)
x      = Widget_label(lf, value = ' Counts ')
x      = Widget_label(lf, value = '    Total Number Used ')
info.form.sca_used = Widget_Label(lf, value = ' ')

fr0    = Widget_Base(sframe, /row, /nonexclusive)


if ((dgrp.use_det[0] eq 1) and (dgrp.is_mca[0] eq 0)) then begin
    pr  = dgrp.prefix[0]
    for n = 0, MAX_SCA - 1 do begin
        uvs = 'sca.'  + strtrim(string(n),2)
        x   = get_detnam(prefix=pr,type='scaler',elem=1,roi=n,net=0)
        t   = x.desc
        if (x.desc eq '') then t = 'UNUSED'
        info.sbutton[n] = Widget_Button(fr0,  xsize=60, Value = t, uvalue = uvs)
        info.snames[n]  = x.desc
    endfor
endif

;
; MCA

sframe = Widget_Base(main,   /col,/frame)
lf     = Widget_Base(sframe, /row)
x      = Widget_label(lf, value = ' MED  Detector:  Use ')
info.form.med_use_net = Widget_DROPLIST(lf, value = net_choices,  $
                                 uvalue = 'med_use_net', /dynamic_resize)
x      = Widget_label(lf, value = ' Counts ')
x      = Widget_label(lf, value = '    Total Number Used ')
info.form.med_used = Widget_Label(lf, value = ' ')

fr1    = Widget_Base(sframe, /col)


if ((dgrp.use_det[1] eq 1) and (dgrp.is_mca[1] eq 1)) then begin
    for nr = 0, MAX_ROI - 1 do begin
        fr0  = Widget_Base(fr1, /row)
        uvs  = 'roi_use_all.' + strtrim(string(nr),2)
        pr  = dgrp.prefix[1]
        x = get_detnam(prefix=pr,type='mca',elem=1,roi=nr,net=0)
        t = x.desc
        if (x.desc eq '') then t = 'UNUSED'
        info.mbutton[nr] = Widget_Label(fr0,  xsize=60, Value = t)
        info.mnames[nr]  = x.desc
        info.m_use_all[nr] = Widget_Button(fr0, value = 'Use All', uvalue = uvs)
        fr00  = Widget_Base(fr0, /row, /nonexclusive)
        
        for nm = 0, MAX_MED-1 do begin
            xim   = strtrim(string(nm+1),2)
            uvs  = 'med.' + strtrim(string(nr),2) + ','  + xim
            info.form.med_use_mca[nr,nm] = Widget_Button(fr00,  value = xim, uvalue= uvs)
        endfor
    endfor
endif



;
; set defaults by what is actually in use
ns_x = 0
nm_x = 0
medpr  = dgrp.prefix[1]
print, ' prefix = ', medpr

for i = 0, MAX_DET -1 do begin
    if ( det.countPV[i] ne '') then  begin
        ; look for 'scaler' if (det.counPV[i] 
        ; print , i , ' -> ', det.desc[i]
        if (strpos(det.countPV[i],'scaler') ge 1) then begin 
            for n = 0, MAX_SCA -1 do begin
                if (det.desc[i] eq info.snames[n]) then begin
                    ns_x = ns_x + 1
                    Widget_Control, info.sbutton[n] , set_button=1
                endif
            endfor
        endif else if (strpos(det.countPV[i],'mca') ge 1) then begin 
            for nm = 0, MAX_MED -1 do begin
                xdet = medpr + 'mca' + strtrim(string(nm+1),2) + '.R'
                for nr = 0, MAX_ROI -1 do begin
                    d  = xdet + strtrim(string(nr),2) 
                    if (det.countPV[i] eq d) then begin
                        ; print, 'det ', d, ' is seen ! '
                        nm_x = nm_x + 1
                        Widget_Control, info.form.med_use_mca[nr,nm] , set_button=1
                    endif
                endfor
            endfor
        endif
        ; else look for med

    endif           

endfor
info.sca_inuse = ns_x
info.med_inuse = nm_x

print, '   ', ns_x, nm_x
widget_control, info.form.sca_used, set_value = string(info.sca_inuse)
widget_control, info.form.med_used, set_value = string(info.med_inuse)


;         endif else begin
;             ; look up proto-typical detector (#7)
;             groupx = [groupx, i+1]
;             for n = 0, N_ROIS-1 do begin
;                 x = get_detnam(prefix=pr,type='med:mca',elem=7,roi=n,$
;                                net=0)
;                 print, ' MCA: n, ielems, x = ', n, i_elems, x.desc
;             endfor
;         endelse
;     endif
; endfor

; Widget_Control, TMP, /destroy
base2  = Widget_Base(main,/row)
X      = Widget_Button(base2,  value = 'Save Changes',    uval='save')
X      = Widget_Button(base2,  value = 'Cancel',          uval='cancel')
X      = Widget_Button(base2,  value = 'Done',            uval='exit')


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
xmanager, 'define_meta_detectors', mine, /NO_BLOCK


return, 0
end










