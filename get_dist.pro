pro get_dist 

; Temporary kludge to to get x_dist, y_dist from BSIF files with multiple
; scanning regions.  Assumes READ_BSIF has already been called.

@bsif_common

if n_elements( user_buffer) gt 1 then begin
  nbytes = 4 * (n_rows + n_cols)
  if (user_buffer(0) eq 87) and (user_buffer(1) eq 25) and $
    (n_elements(user_buffer) eq 2) then goto, over
  if n_elements( user_buffer) ne nbytes then message, 'User buffer is wrong size
  new_buffer = fltarr( n_rows + n_cols)
  copy_bytes, nbytes, user_buffer, new_buffer
  x_dist = double (new_buffer(0 : n_cols-1))
  y_dist = double (new_buffer(n_cols : *))
endif

over:

end
