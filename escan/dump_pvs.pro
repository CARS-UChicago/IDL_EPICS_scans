pro dump_pvs , input=input, output=output
;
; simple dump of PV list (as in scan_pvs.dat) to a file
;
if (n_elements(output) eq 0) then output = 'pv_values.out'
if (n_elements(input)  eq 0) then begin
    input  = 'scan_pvs.dat'
endif

; on_ioerror, no_file:


; if (keyword_set (use_dialog)) then begin
;     file = dialog_pickfile(filter='*.scn', get_path=path, $
;                            /write, file = init_file)
; endif
; file  = strtrim(file,2)
; if (file eq '') then return, -1

e = obj_new('EPICS_SCAN')
x = e->set_param('monitorfile', input)
openw, lun, output, /get_lun

x = e->write_pv_list(lun=lun)
close, lun
free_lun, lun
print, 'wrote PVS to ', output
obj_destroy, e
return
end
