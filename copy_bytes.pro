pro copy_bytes, n, source, dest
;+
; NAME:
;       COPY_BYTES.PRO
; PURPOSE:
;       Copies bytes between a source and destination regardless of whether or
;       not they have the same structure. It can be useful for copying, for
;       instance between a byte array and a structure. It must be used
;       with care.
; CALLING SEQUENCE:
;       COPY_BYTES, n_bytes, source, destination
; INPUTS:
;   N_BYTES
;       The number of bytes to copy.
;   SOURCE
;       The location to copy from.
; OUTPUTS:
;   DESTINATION
;       The location to copy to.
; RESTRICTIONS:
;       This routine does not do any error checking. The user must ensure that
;       SOURCE and DESTINATION can each hold N_BYTES.
;       Under UNIX the use must have write permission in the current default
;       directory.
; PROCEDURE:
;       Under VMS uses Run-Time Library routine LIB$MOVC3.
;       Under UNIX opens a file, write out the source, reads back into
;       destination.
; MODIFICATION HISTORY:
;       Created Nov. 1991 by Mark Rivers
;-
if !version.os eq 'vms' then begin
  lib$movc3, n, source, dest
endif else begin
  get_lun, lun
  openw, lun, 'scratch.jnk'
  writeu, lun, source
  close, lun
  openr, lun, 'scratch.jnk'
  readu, lun, dest
  close, lun
  free_lun, lun
endelse
end