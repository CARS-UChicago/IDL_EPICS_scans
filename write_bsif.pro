pro WRITE_BSIF, file, xdr=xdr

;+
; NAME: 
;       WRITE_BSIF.PRO
; PURPOSE: 
;       Writes a Brookhaven Standard Image Format file. 
;       The default on all systems except VMS is to write an XDR format file which is 
;       computer independent. On VMS only the default is to write the old-style 
;       non-XDR file format.
; CALLING SEQUENCE: 
;       WRITE_BSIF, filename
; INPUTS: 
;       filename; The name of the file to write
; KEYWORD PARAMETERS:
;   XDR
;       Set this keyword to specify that the file is to be written in XDR, 
;       a portable binary format.  This keyword is only necessary on VMS.
; OUTPUTS:
;       None
; COMMON BLOCKS: 
;       BSIF_COMMON, defined in BSIF_COMMON.PRO.
; SIDE EFFECTS: 
;       Writes the data and parameters stored in common block BSIF_COMMON to
;       the specified file.
; RESTRICTIONS: 
;
; PROCEDURE: 
;       For XDR files WRITE_BSIF opens the file and writes out the data.
;       For VMS BSIF files WRITE_BSIF.PRO simply calls WRITE_BSIF_I, which is 
;       a procedure which is written in C. It must be made known via the 
;       LINKIMAGE command. This is normally done in the startup file.
; MODIFICATION HISTORY
;       Written in 1990 by Mark Rivers
;       Modified October 1991 to ensure that DATA_TITLE is a string array.
;       4/21/94 MLR Create user_buffer if it doesn't exist. Was crashing in
;           write_bsif_i.c if it was not defined.
;       Modified September 1996 by Harvey Rarback to use user_buffer for
;          [x_dist,y_dist] for XDR files
;       Jan 17, 2001 MLR  Made XDR the default for non-VMS systems.  Merged BNL and 
;                         APS versions.
;-
;
@bsif_common

n_cols = n_elements(image_data(*, 0, 0))
n_rows = n_elements(image_data(0, *, 0))
n_data = n_elements(image_data(0, 0, *))
data_min = dblarr(n_data)
data_max = dblarr(n_data)
temp = strarr(n_data)
for i=0, n_data-1 do begin
  mn = min(image_data(*,*,i), max=mx)
  data_min(i) = mn
  data_max(i) = mx
  temp(i) = data_title(i)
endfor
data_title = temp

; Make sure the user buffer exists. write_bsif_i crashes if it doesn't.
ub_len = n_elements(user_buffer)
if (ub_len eq 0) then begin
  ub_len = 1
  user_buffer = bytarr(ub_len)
endif

if (keyword_set(xdr) or (!version.os ne 'vms')) then begin
  get_lun, lun
  openw, lun, file, /xdr
  ub_len = n_elements(user_buffer)
  if (ub_len eq 0) then begin
    ub_len = 1
    user_buffer = bytarr(ub_len)
  endif else if ub_len eq 4*(n_rows+n_cols) then begin ; multiple scan regions
    new_buffer = fltarr( n_rows + n_cols)
    copy_bytes, ub_len, user_buffer, new_buffer
    user_buffer = new_buffer
  endif 

  type = size(image_data)
  type = type(type(0)+1)
  ; Convert from IDL data types to BSIF data types
  case type of
    1: data_type = 1
    2: data_type = 3
    3: data_type = 5
    4: data_type = 6
    5: data_type = 7
  endcase
  writeu, lun, long(n_rows), long(n_cols), long(n_data), long(x_normal), $
             long(y_normal), long(rotated), float(x_start), float(x_stop), $
             float(y_start), float(y_stop), $
             string(image_title), string(x_title), string(y_title), $
             data_title, long(data_type), long(ub_len),$
             image_data, user_buffer
  close, lun
  free_lun, lun
endif else begin
  write_bsif_i, file, n_rows, n_cols, n_data, x_normal, $
             y_normal, rotated, x_start, x_stop, y_start, y_stop, $
             image_title, x_title, y_title, data_title, data_type, $
             compression_type, data_min, data_max, user_buffer, image_data
endelse
return
end
