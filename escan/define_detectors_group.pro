pro define_detectors_event, event

Widget_Control, event.top, get_uvalue = p
Widget_Control, event.id,  get_uvalue = uval

if (uval eq 'cancel') then begin
    x  = (*p).es->set_param('detectors',(*p).det_save)
endif 
if ((uval eq 'save') or (uval eq 'exit')) then begin
;     print, ' info.group = ', (*p).group
    dgrp   = (*p).es->get_param('detgroups')
    ;print, ' Saving Detectors ' 
    M_DET = n_elements( (*p).det.countPV )
    for i = 0,  M_DET - 1 do  begin
        j   = Widget_Info( (*p).form.det_elem[i], /droplist_select)
        net = Widget_Info( (*p).form.use_net[i], /droplist_select)
        if (j gt 0) then begin
            k = Widget_Info( (*p).form.det_desc[i], /droplist_select)
            (*p).det.countPV[i] = ''
            igr = (*p).group[j] - 1
            pr  = dgrp.prefix[igr]
            if (igr eq 0) then begin
                x = get_detnam(prefix=pr,type='scaler',elem=1,roi=k,net=net)
                (*p).det.countPV[i] = x.countPV
                (*p).det.desc[i]    = x.full_desc
            endif else if (igr eq 1) then  begin
                x = get_detnam(prefix=pr,type='med:mca',elem=j-1,roi=k,net=net)
                (*p).det.countPV[i] = x.countPV
                (*p).det.desc[i]    = x.full_desc
            endif
        endif else begin
            (*p).det.countPV[i] = ''
        endelse
        ; print, i, ' PV = ', (*p).det.countPV[i]
    endfor
    x  = (*p).es->set_param('detectors',(*p).det)
endif 
iu = strpos(uval,'_')
if ((uval eq 'cancel') or (uval eq 'exit')) then begin
    caSetTimeout, (*p).timeout
    caSetRetryCount, (*p).retry
    Widget_Control, event.top, /DESTROY
endif else if (uval  ne 'save') then begin
    thing = strmid(uval,0,iu)
    _elem_ = fix(strmid(uval,iu+1,strlen(uval)))-1
;;     print, ' uval = ', thing, _elem_, event.index
    if (thing eq 'elem') then begin
        ; print, ' event_index = ', event.index
        Widget_Control, (*p).form.det_desc[_elem_], $
          set_value =   (*p).elem_list[event.index,*]
        Widget_Control, (*p).form.det_desc[_elem_], set_droplist_select = 0
;         if (_elem_ eq 1) then $
;           Widget_Control, (*p).form.use_net[_elem_], set_droplist_select = 1
    endif
endif

return
end

function define_detectors, p
;
; gui for selecting detectors
;
N_MCAS   = 30
N_ROIS   = 10

ret = (*p).es->lookup_detectors()
det = (*p).es->get_param('detectors')

det_save  = det
MAX_DET   = n_elements( det.countPV)
;
mine      = Widget_Base(TITLE = 'Define Detectors', /COLUMN, APP_MBAR = menubar)
fileMenu  = Widget_Button(menubar,  value = 'File')
saveMB    = Widget_Button(fileMenu, value = 'Save',   uvalue = 'save' )
exitMB    = Widget_Button(fileMenu, value = 'Exit',   uvalue = 'exit', /sep)

mainFRAME = Widget_Base(mine, /COLUMN)
TMP       = Widget_Base(mainFRAME, /ROW)
tx1       = Widget_Label(TMP, value = ' Looking up available detectors ... ')
Widget_Control, mine, /REALIZE
Widget_Control, mine, update = 0
; 
;  gather all valid detector names (why not??)
;
dgrp   = (*p).es->get_param('detgroups')
scanPV = (*p).es->get_scan_param(0,scanPV)
prefix = (*p).es->get_param('prefix')

; 

MAX_DTY   = n_elements(dgrp.name)
elem_list = strarr(N_MCAS, N_ROIS)

group     = intarr(N_MCAS + N_ROIS)
elemx     = strarr(N_MCAS + N_ROIS )
elems     = ['None' ]
groupx    = [0]
form  = {det_choice:0, det_elem:lonarr(MAX_DET), $
         det_desc:lonarr(MAX_DET) , use_net: lonarr(MAX_DET) }
info  = {es:(*p).es, form:form, det_save:det_save, $
        det:det, elems:elemx, elem_list: elem_list, group:group, $
        timeout:0.001, retry:50 }

print, ' a' 

info.timeout = caGetTimeout()
info.retry   = caGetRetryCount()
t0 =  (info.timeout/ 10.) > 0.001
caSetTimeout,   t0
caSetRetryCount, 25

print,  ' ----------- DEFINE DETECTORS ----------------', info.timeout
i_elems = 0
for i = 0,MAX_DTY-1 do begin
    pr = dgrp.prefix[i]
    print, '  ' , i,  '  ', pr 
    if (dgrp.use_det[i] eq 1) then begin
        ; print, ' using ' , dgrp.name[i], ' is mca? = ', $
        ;   dgrp.is_mca[i],  ' # elems = ',dgrp.max_elems[i] , pr
        if (dgrp.is_mca[i] eq 0) then begin
            groupx = [groupx, i+1]
            elems  = [elems, dgrp.name[i]] 
            i_elems = i_elems + 1
            for n = 0, dgrp.max_elems[i]-1 do begin
                x = get_detnam(prefix=pr,type='scaler',elem=1,roi=n,net=0)
                ;print, ' n, ielems, x = ', n, i_elems, x.desc
                elem_list[i_elems,n] = x.desc
            endfor
        endif else begin
            for j = 0, dgrp.max_elems[i] - 1 do begin
                groupx = [groupx, i+1]
                elems = [elems, dgrp.name[i]+' MCA' + strtrim(string(j+1),2)]
                i_elems = i_elems + 1
                for n = 0, N_ROIS-1 do begin
                    x = get_detnam(prefix=pr,type='med:mca',elem=j,roi=n,$
                                   net=0)
                    elem_list[i_elems,n] = x.desc
                    ;print, ' n, ielems, x = ', n, i_elems, x.desc
                endfor
            endfor
        endelse
    endif
endfor

; info.group = group
info.group = groupx
info.elems = elems
info.elem_list = elem_list

print, ' info.elems = ', info.elems
print, ' info.group = ', info.group

Widget_Control, TMP, /destroy
base2  = Widget_Base(mainFrame,/row)
X      = Widget_Button(base2,  value = 'Save Changes',    uval='save')
X      = Widget_Button(base2,  value = 'Cancel',          uval='cancel')
X      = Widget_Button(base2,  value = 'Done',            uval='exit')


M_COLS =  4
M_ROWS =  (MAX_DET/M_COLS) + 1
net_choices = ['Sum' , 'Net']


i = -1

Grid = Widget_Base(mainFRAME, /ROW)
tcol = lonarr(M_COLS+1)
for icol = 1, M_COLS do begin
    tcol[icol] = Widget_Base(Grid, /col)
    tc  = Widget_Base(tcol[icol], /row)
    X   = Widget_Label(TC, XSIZE=80,  value = ' Detector  ')
    X   = Widget_Label(TC, XSIZE=80,  value = ' Sum  / Net')
    X   = Widget_Label(TC, XSIZE=80,  value = ' Element   ')
    X   = Widget_Label(TC, XSIZE=80,  value = ' Selection ')
    for irow = 0, M_ROWS-1 do begin
        i = i + 1
        if (i ge MAX_DET) then goto, form_end
        index = strtrim(string(i+1,format='(i2.2)'),2)
        T     = Widget_Base(tcol[icol], /row)
        uvalu = 'elem_' + index
        T1     = Widget_Label(T, XSIZE=40,  value = index )
        uvalu = 'net_' + index
        info.form.use_net[i] = Widget_DROPLIST(T, value = net_choices,  $
                                               uvalue = uvalu, /dynamic_resize)
        
        uvalu = 'elem_' + index
        info.form.det_elem[i] = Widget_DROPLIST(T, value = elems,  uvalue = uvalu, /dynamic_resize)
        Widget_Control, info.form.det_elem[i], set_droplist_SELECT = 0
        uvalu = 'desc_' + index
        info.form.det_desc[i] = Widget_DROPLIST(T, value = elem_list[1,*],  uvalue = uvalu, /dynamic_resize)
        
        elem_choice  = 03
        ending       = ''
        print, ' I = ' , i, uvalu, det.countPV[i]
        if (det.countPV[i] ne '') then begin
            igr = det.group[i]
            gr  = dgrp.prefix[igr]
            ending = strmid(det.countPV[i], strlen(dgrp.prefix[igr]), strlen(det.countPV[i]))
            x = split_det_name(gr, ending, dgrp.is_mca[igr])
            print,  i, ' ', det.countPV[i],  ' | ', gr, ' | ', det.desc[i], ' | ', ending
            
            Widget_Control, info.form.use_net[i], set_droplist_select = det.use_net[i]
            
            roi = ''
            if (dgrp.is_mca[igr] eq 1) then begin
                i_elem = strmid(ending,3,strpos(ending,'.')-3)
                elem   = 'MCA ' + strtrim(i_elem,2)
                i_elem =  fix(i_elem)  + 1
                roi    = strmid(ending, strpos(ending,'.R')+2)
                if (strmid(roi,strlen(roi)-1) eq 'N') then roi = strmid(roi,0,strlen(roi)-1)
                i_roi  = fix(roi)
                ; print, ' MCA ', i_elem, i_roi,  ' from ' , ending
                Widget_Control, info.form.det_elem[i], set_droplist_select = i_elem
                Widget_Control, info.form.det_desc[i], set_value = elem_list[i_elem,*]
                Widget_Control, info.form.det_desc[i], set_droplist_select = i_roi
            endif else  begin
                i_elem = 1
                if (strmid(ending,0,5) eq '_calc') then begin
                    roi    = strmid(ending, 5, strpos(ending,'.')-5)
                endif else if (strmid(ending,0,2) eq '.S') then begin
                    roi    = strmid(ending,2)
                endif
                i_roi  = fix(roi)-1
                Widget_Control, info.form.det_elem[i], set_droplist_select = i_elem
                Widget_Control, info.form.det_desc[i], set_value = elem_list[i_elem,*]
                Widget_Control, info.form.det_desc[i], set_droplist_select = i_roi
            endelse
        endif else begin
            Widget_Control, info.form.det_elem[i], set_droplist_select = 0
            Widget_Control, info.form.det_desc[i], set_value = elem_list[elem_choice,*]
            Widget_Control, info.form.det_desc[i], set_value = elem_list[0,*]
        endelse
    endfor
endfor
form_end:
Widget_Control, mine, /update

p_info = ptr_new(info,/NO_COPY)
Widget_Control, mine, set_uvalue=p_info
Widget_Control, mine, /REALIZE
xmanager, 'define_detectors', mine, /NO_BLOCK


return, 0
end










