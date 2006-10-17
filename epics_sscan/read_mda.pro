function read_mda, file
;+
; NAME:
;   read_mda
;
; PURPOSE:
;   This function:
;      - Creates an EPICS_SSCAN object
;      - Reads an EPICS MDA scan file
;      - Returns an object reference to the EPICS_SSCAN object
;
; CATEGORY:
;   EPICS scanning tools.
;
; CALLING SEQUENCE:
;   scan = read_mda(Filename)
;
; INPUTS:
;   Filename:  The name of the MDA file to read.
;
; OUTPUTS:
;   This function returns an object reference to the EPICS_SSCAN object.
;
; PROCEDURE:
;   This is a very simple function.  It simply does the following:
;      s = obj_new('epics_sscan')
;      s->read_mda, file
;      return, s
;
; RESTRICTIONS:
;   While this function is easy to use, users need to be aware that
;   calling this function repeatedly without destroying the returned
;   objects will lead to memory leaks.  This may be acceptable for
;   interactive use, but software written to use the EPICS_SSCAN class
;   should create objects sparingly and use the epics_sscan::read_mda
;   method directly, rather than calling this function.
;
; EXAMPLE:
;   IDL> s=read_mda('2idd_0087.mda')
;   IDL> s->display, detector=[4,5,6,7], /grid
;
; MODIFICATION HISTORY:
;   Written by:  Mark Rivers, Nov. 8, 2003
;-
   s = obj_new('epics_sscan')
   s->read_mda, file
   return, s
end
