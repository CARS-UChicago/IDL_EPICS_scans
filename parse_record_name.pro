pro parse_record_name, name, record, field

; This routine accepts a PV name and returns the name of the record and the
; field if there was one.
pos = strpos(name, '.')
if (pos eq -1) then begin
   record = name
   field = ''
endif else begin
   record = strmid(name, 0, pos)
   field = strmid(name, pos, 100)
endelse
end
