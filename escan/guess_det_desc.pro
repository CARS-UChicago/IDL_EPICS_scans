function guess_det_desc, pv=pv, net=net
;
;  given a detector PV, guess the detector description
;
;  supported detector types:
;     ...scaler?.S??
;     ...scaler?_calc??.VAL   
;     ...aim_adc?.R??
;     ...aim_adc?.R??N
;     ...med:mca??.R??
;     ...med:mca??.R??N
;
;  net = 1 for 'Net Counting' of MCA or scaler?_calc??.VAL
;---------------------------------------------------------------

net  = 0
det  = strtrim(pv,2)
desc = det
dpv  = ''
;
; first, test for scaler string
isca = strpos(det,'scaler')
if (isca ge 2) then begin
    pre = strmid(det,0,isca+7)
    tmp = strmid(det,isca+7,strlen(det))
    icl = strpos(tmp,'_calc')
    ids = strpos(tmp,'.S')
    suf = ''
    if (ids ge 0) then begin
        suf = strmid(tmp,ids+2,strlen(tmp))
    endif else if (icl ge 0) then begin
        net = 1
        ids = strpos(tmp,'.')
        suf = strmid(tmp,icl+5,ids-(icl+5))
    endif 
    dpv = pre+ '.NM' + suf
    x   = caget(dpv,desc)
    desc= strtrim(desc,2)
    if ((x lt 0)  or (desc eq '')) then desc  = det
endif else begin
; MED or adc
    imed = strpos(det,'med:mca')
    iadc = strpos(det,'aim_adc')
    if ((imed ge 2) or (iadc ge 2)) then begin
        iel = imed > iadc
        pre = strmid(det,0,iel+8)
        tmp = strmid(det,iel+8,strlen(det))
        if  ( strmid(tmp,strlen(tmp)-1,1)  eq 'N') then begin
            net = 1
            tmp = strmid(tmp,0,strlen(tmp)-1)
        endif
        dpv = pre+ tmp + 'NM'
        x   = caget(dpv,desc)
        desc = strtrim(desc,2)
        if ((x lt 0)  or (desc eq '')) then desc  = det
        if (imed eq iel) then begin
            tmp = strmid(det,iel+4,strlen(det))
            ids = strpos(tmp,'.')
            if ((desc ne dpv) and (ids ge 1)) then $
              desc = strmid(tmp,0,ids) + ': ' + desc
;;;               desc = desc + ' [' + strmid(tmp,0,ids) + ']'
        endif
    endif else begin
        ival = strpos(det,'.VAL')
        if (ival ge 2) then begin
            dpv = strmid(det,0,ival) + '.DESC'
            x   = caget(dpv,desc)
            desc = strtrim(desc,2)
            if ((x lt 0)  or (desc eq '')) then desc  = det
        endif
    endelse
endelse
return, desc
end


