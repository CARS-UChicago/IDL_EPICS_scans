; munge detector names 
function split_det_name, group, ending, is_mca
;
;  given a detector group, ending,  and mca flag return a struct containing
;     elem: 
;     roi: 
;

s   = {elem:0, roi:0}

; print, 'Split Det Name 2: ',  s.use_net, s.desc
return, s
end


; str = strtrim(detPV,2)
; ; print, 'Split Det Name 1: ', detPV
; if  (str ne '')  then begin
;     len   = strlen(str)
;     iscal = strpos(str, 'scaler')
;     imca  = strpos(str, 'med:mca')
; ;     print, ' S_D_N: ', iscal, imca
;     if (iscal gt 0) then begin
;         s.type = 'scaler'
; ;         print, ' SCALER: ', str , iscal-1
;         s.prefix = strmid(str, 0, iscal+7)
; ;        print, ' prefix ', s.prefix
;         tmp = strmid(str, iscal+6, len) 
;         ix  = strpos(tmp, '.S')
;         s.elem = fix(strmid(tmp, 0, ix) )
;         s.roi  = fix(strmid(tmp,ix+2, strlen(tmp))) - 1
;     endif else if (imca gt 0) then begin
;         s.type = 'med:mca'
;         s.prefix = strmid(str, 0, imca-1)
;         tmp   = strmid(str, imca+7, len) 
;         idot  = strpos(tmp, '.')
;         s.elem= strmid(tmp,0, idot)
;         s.roi= strmid(tmp,idot+2, 1)
;     endif
; endif
; ; print, 'Split Det Name 2: ',  s.prefix, s.type, s.elem, s.roi
; return, s
; end





