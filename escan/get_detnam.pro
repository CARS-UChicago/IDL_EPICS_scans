function get_detnam, prefix=prefix, type=type, elem=elem,roi=roi,$
                     net=net
;
;  given a detector type ('scaler', 'med:mca', or 'aim_adc'), an element # 
;  ( '1' for scaler1 or aim_adc1, or the med channel), and an roi (scaler
;  channel or aim_adc or med ROI),  
;  return a structure with
;     countPV:    PV to count
;     descPV:     PV for description
;     desc:       brief description field 'Mn Ka'
;     full_desc:  full description field  'mca6: Mn Ka'
;
;  notes: 
;  1   for all detectors, rois start at 0, even though scaler PV 
;      names really start with 1.   That is  
;           type= scaler, elem=1, roi=0
;      will yield 
;           13IDC:scaler1.S1
;  2   net will get the 'net' version of the detector:
;      XXXyyy.R3N             for aim_adc and med:mca (roi 3)
;      XXXscaler1_calc3.VAL   for scaler (elem 1, roi 2)
;---------------------------------------------------------------
pre_  = '13IDC:'
type_ = ''
elem_ = 1
roi_  = 0
net_  = 0
if (keyword_set(prefix)  ne 0)  then pre_  = prefix
if (keyword_set(type)    ne 0)  then type_ = type
if (keyword_set(elem)    ne 0)  then elem_ = elem
if (keyword_set(roi)     ne 0)  then roi_  = roi
if (keyword_set(net) ne 0)      then net_  = net
out    = {desc:'', full_desc:'', descPV:'', countPV:''}
s_elem = strtrim(string(elem_,format='(i1.1)'),2)
if (elem_ gt 9) then s_elem = strtrim(string(elem_,format='(i2.2)'),2)


pref = pre_ 
; pref = pre_ + type_ + s_elem
; _now_ (and only after pref is made!) rewrite type_ to make all mca-like 
; detectors look the same
if ((type_ eq 'aim_adc') or (type_ eq 'med:mca')) then type_ = 'mca'
; print, ' GET_DETNAM: ', pre_ ,   ' :: ',  type_ , '::', s_elem, roi, net_
case type_ of 
    'scaler': begin
        s_roi     = strtrim(string(roi_ + 1,format='(i1.1)'),2) 
        if (roi_ ge 9) then s_roi  = strtrim(string(roi_+1 ,format='(i2.2)'),2) 
        out.descPV  = pref + '.NM' + s_roi
        out.countPV = pref + '.S'  + s_roi
        if (net_ eq 1) then out.countPV = pref + '_calc' + s_roi + '.VAL'
    end
    'mca': begin
        s_roi     = strtrim(string(roi_ ,format='(i1.1)'),2) 
        if (roi_ gt 9) then s_roi  = strtrim(string(roi_ ,format='(i2.2)'),2) 
        out.descPV  = pref + 'mca' + s_elem + '.R'  + s_roi + 'NM'
        out.countPV = pref + 'mca' + s_elem + '.R'  + s_roi 
        if (net_ eq 1) then out.countPV = out.countPV + 'N'
    end
endcase
; look up description
; print, ' OUT  : ', out.descPV
if (out.descPV ne '') then  begin
    x = 'not available'
    y = caget(out.descPV, x)
    out.desc = x
endif
; full description
out.full_desc  =  out.desc
if (type_ eq 'mca') then out.full_desc = 'mca '+s_elem+': '+out.desc

; print, ' GETDETNAM : ', out.countPV, ' OUT  : ', out.descPV, ' : ', out.desc
return, out
end

