pro display_mda, file, s, _extra=extra
;+
; NAME:
;   display_mda
;
; PURPOSE:
;   This procedure:
;      - Creates an EPICS_SSCAN object
;      - Reads an EPICS MDA scan file with epics_sscan::read_mda
;      - Displays the data in the file with epics_sscan::display
;      - Optionally returns an object reference to the EPICS_SSCAN object
;
; CATEGORY:
;   EPICS scanning tools.
;
; CALLING SEQUENCE:
;   display_mda, Filename, Scan
;
; INPUTS:
;   Filename:  The name of the MDA file to read.
;
; KEYWORDS:
;   Passes all keywords to the epics_sscan::display procedure,
;   and/or to the iPlot or iImage tool via _EXTRA.
;
; OPTIONAL OUTPUTS:
;   Scan
;      An object reference to the EPICS_SSCAN object.
;
; PROCEDURE:
;   This is a very simple procedure.  It simply does the following:
;      Scan = obj_new('epics_sscan')
;      Scan->read_mda, file
;      Scan->display, _extra=extra
;
; RESTRICTIONS:
;   While this procedure is easy to use, users need to be aware that
;   calling it repeatedly without destroying the returned
;   objects will lead to memory leaks.  This may be acceptable for
;   interactive use, but software written to use the EPICS_SSCAN class
;   should create objects sparingly and use the epics_sscan::read_mda
;   and epics_sscan::display methods directly, rather than calling
;   this procedure.
;
; EXAMPLE:
;   IDL> display_mda, s, '2idd_0087.mda', detector=[4,5,6,7], /grid
;   IDL> s->print, /all
;
; MODIFICATION HISTORY:
;   Written by:  Mark Rivers, Nov. 8, 2003
;-
   s = obj_new('epics_sscan')
   s->read_mda, file
   s->display, _extra=extra
end
