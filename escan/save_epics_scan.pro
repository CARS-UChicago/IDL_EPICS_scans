pro save_epics_scan, prefix, file_name

; This procedure reads data from an EPICS scan record and writes it to a disk file.

scan = obj_new('epics_scan', prefix=prefix)
s = scan->set_param('datafile', file_name)
s = scan->open_scanfile()
; s = scan->lookup_detectors()
; s = scan->lookup_positioners()
s = scan->write_scan_data()  ; This calls read_data_from_crate()
s = scan->close_scanfile()
end
