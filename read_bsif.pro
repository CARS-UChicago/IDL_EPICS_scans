pro READ_BSIF, file, xdr=xdr, user=user, header_only=header_only, $
                              get_dist=get_dist

;+
; NAME: 
;       READ_BSIF.PRO
; PURPOSE: 
;       Reads a Brookhaven Standard Image Format file.
;       The default on all systems except VMS is to read an XDR format file which is 
;       computer independent. On VMS only the default is to read the old-style 
;       non-XDR file format written on a VAX/VMS system.
; CALLING SEQUENCE: 
;       READ_BSIF, filename
; INPUTS: 
;       filename; The name of the file to read
; KEYWORD PARAMETERS:
;   XDR
;       Set this keyword to specify that the file is in XDR, a portable binary
;       format.  This keyword is only necessary on VMS.
;   USER
;	Returns the user_buffer
;   HEADER_ONLY
;	Set this keyword to only read the image header stuff and the user_buffer.
;   GET_DIST
;       Set this keyword to get x_dist and y_dist arrays for multiple scan regions
; OUTPUTS: 
;       The image data and parameters are read into common block BSIF_COMMON.
;       All of the values in this common block are modified. See the file
;       BSIF_COMMON.PRO for a description of each of the variables in this
;       common block.
; COMMON BLOCKS: 
;       BSIF_COMMON, defined in BSIF_COMMON.PRO.
; SIDE EFFECTS: 
;       Modifies the variables in common block BSIF_COMMON.
; RESTRICTIONS: 
;       All of the data values at each pixel must be of the same data type,
;       since the data are read into a 3-dimensional array.
;
;       Calling READ_BSIF again overwrites any existing data, since the same
;       common block is used. What we really need is the ability to read
;       images into structures. 
; PROCEDURE: 
;       For XDR files READ_BSIF opens the file and reads the data.
;       For VMS BSIF files READ_BSIF.PRO simply calls READ_BSIF_I, which is 
;       a procedure which is written in C. It must be made known via the 
;       LINKIMAGE command. This is normally done in the startup file.
; MODIFICATION HISTORY
;       Written in 1990 by Mark Rivers
;       September 1996  Harvey Rarback. Added get_dist keyword.
;       January 2001    Mark Rivers. Made XDR the default on non-VMS systems.
;                       Merged BNL version (with get_dist) with the APS version.
;-

@bsif_common
on_error, 2

if n_elements(file) eq 0 then message, 'Must specify a file name'
file = string(file)

if (keyword_set(xdr) or (!version.os ne 'vms')) then begin
  get_lun, lun
  openr, lun, file, /xdr
  n_rows = 0L
  n_cols = 0L
  n_data = 0L
  x_normal = 0L
  y_normal = 0L
  rotated = 0L
  x_start = 0.
  x_stop = 0.
  y_start = 0.
  y_stop = 0.
  image_title = ' '
  x_title = ' '
  y_title = ' '
  readu, lun, n_rows, n_cols, n_data, x_normal, $
             y_normal, rotated, x_start, x_stop, y_start, y_stop, $
             image_title, x_title, y_title
  data_title = strarr(n_data)
  data_type = 0L
  ub_len = 0L
  readu, lun, data_title, data_type, ub_len
  nregions = keyword_set( get_dist) and ub_len ge 8  
  if keyword_set(header_only) then begin
    image_data=0
    case data_type of
      0: image_data_bytes = 1 * n_cols * n_rows * n_data
      1: image_data_bytes = 1 * n_cols * n_rows * n_data
      2: image_data_bytes = 2 * n_cols * n_rows * n_data
      3: image_data_bytes = 2 * n_cols * n_rows * n_data
      4: image_data_bytes = 4 * n_cols * n_rows * n_data
      5: image_data_bytes = 4 * n_cols * n_rows * n_data
      6: image_data_bytes = 4 * n_cols * n_rows * n_data
      7: image_data_bytes = 8 * n_cols * n_rows * n_data
    endcase
    tmp=fstat(lun)
    offset=image_data_bytes+tmp.cur_ptr
    point_lun,lun,offset
  endif else begin
    case data_type of
      0: image_data = bytarr(n_cols, n_rows, n_data)
      1: image_data = bytarr(n_cols, n_rows, n_data)
      2: image_data = intarr(n_cols, n_rows, n_data)
      3: image_data = intarr(n_cols, n_rows, n_data)
      4: image_data = lonarr(n_cols, n_rows, n_data)
      5: image_data = lonarr(n_cols, n_rows, n_data)
      6: image_data = fltarr(n_cols, n_rows, n_data)
      7: image_data = dblarr(n_cols, n_rows, n_data)
    endcase
    readu, lun, image_data
  endelse
  if n_elements(user) ne 0 then begin
    readu, lun, user
    user_buffer = user 
  endif else if nregions then begin
    temp = fltarr( n_rows + n_cols)
    readu, lun, temp
    user_buffer = temp
  endif else begin
    user_buffer = bytarr(ub_len)
    readu, lun, user_buffer
  endelse
  if nregions then begin
    x_dist = user_buffer(0 : n_cols-1)
    y_dist = user_buffer(n_cols : *)
  endif else begin
    x_dist = findgen(n_cols)/((n_cols-1)>1)*(x_stop-x_start) + x_start
    y_dist = findgen(n_rows)/((n_rows-1)>1)*(y_stop-y_start) + y_start
  endelse
  close, lun
  free_lun, lun

endif else begin
  if keyword_set(header_only) then begin
    read_bsif_h_i, file, n_rows, n_cols, n_data, x_normal, $
             y_normal, rotated, x_start, x_stop, y_start, y_stop, $
             image_title, x_title, y_title, data_title, data_type, $
             compression_type, user_buffer, image_data
  endif else begin
    read_bsif_i, file, n_rows, n_cols, n_data, x_normal, $
             y_normal, rotated, x_start, x_stop, y_start, y_stop, $
             image_title, x_title, y_title, data_title, data_type, $
             compression_type, user_buffer, image_data
  endelse

  if keyword_set( get_dist) and n_elements( user_buffer) ge 8 then begin
    new_buffer = fltarr( n_rows + n_cols)
    copy_bytes, nbytes, user_buffer, new_buffer
    x_dist = double (new_buffer(0 : n_cols-1))
    y_dist = double (new_buffer(n_cols : *))
  endif else begin
    x_dist = findgen(n_cols)/((n_cols-1)>1)*(x_stop-x_start) + x_start
    y_dist = findgen(n_rows)/((n_rows-1)>1)*(y_stop-y_start) + y_start
  endelse
endelse

return
end
