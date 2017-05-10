pro load_epics_settings, file
;
; read saved epics parameters from a simple file, 
; and load those values
;
; file looks like this:
;
;   #EPICS parameter file
;   pv=value
;   pv=value
; ....

openr, lun, file, /get_lun
print, lun
file_valid = 0
str = ''
print, 'restoring epics settings from file ', file
while not (eof(lun)) do begin
    readf, lun, str
    ; print, ':: ', str
    if (file_valid eq 0) then  begin
        s = strmid(str,0,21)
        if (s eq '#EPICS parameter file') then begin
           file_valid=1
        endif
    endif
    
    str  = strtrim(str,2)
    if ((file_valid eq 1) and (str ne '') and $
        (strmid(str, 0, 1) ne '#')) then begin
        ieq = strpos(str,'=')
        if (ieq gt 1) then begin
            pv = strmid(str,0,ieq)
            val= float(strmid(str,ieq+1,strlen(str)))
            print, 'caput : ', pv, ' : ', val
            s = caput(pv, val)            
        endif
    endif
endwhile

close, lun
free_lun, lun
return
end
