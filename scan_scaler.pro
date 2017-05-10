pro scan_scaler

@bsif_common
@scan_common

line_scan = (sd.n_dims eq 1)

for row=0, n_rows-1 do begin
  for col=0, n_cols-1 do begin

    ; The motors are in the correct position. 
    ; Clear data, begin acquisition
    ; For now we assume that all scalers are on one module
    sd.scaler->start, sd.dwell_time

    ; Wait for scaler to start then to complete.
    sd.scaler->wait, /start, /stop

    ; Save scaler counts
    counts = sd.scaler->read()
    for i=0, sd.n_scalers-1 do begin
      image_data(col, row, i) = counts[i]
    endfor

    ; Call the routine to display this pixel
    display_point, row, col

    ; The scan could have been aborted at this point
    if (sd.abort_scan ne 0) then return

    ; Move to next point - skip if last point
    if (col ne n_cols-1) then begin
      sd.motors[0]->move, x_dist(col+1)
      ; If this is line scan move any other motors
      if line_scan then $
        for i=1, sd.n_motors-1 do sd.motors[i]->move, /relative, $
                                                            md[i].inc[0]
      for i=0, sd.n_motors-1 do sd.motors[i]->wait
    endif

  endfor ; Fast motor loop

  ; Move slow axis, skip if last point or if line scan
  if (row ne n_rows-1) and (not line_scan) then begin
    sd.motors[1]->move, y_dist(row+1)
    sd.motors[1]->wait

    ; Move fast motor back to beginning of scan
    sd.motors[0]->move, md[0].start[0]
    sd.motors[0]->wait
  endif

endfor  ; Slow scan loop

return
end
