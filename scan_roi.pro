pro scan_roi

; Modified:
; March 2, 2001  MLR  Added support for "gated" mode in which EPICS scaler is gated
;                     by EPICS MCA
; March 5, 2001  MLR  Fixed bugs in "gated" mode.  Added 0.1 second delays in 2
;                     places.

@bsif_common
@scan_common

line_scan = (sd.n_dims eq 1)

; Set the preset live or real time on the MCA
presets = sd.mca->get_presets()
old_presets = presets
if (sd.timing_mode eq REAL_TIME_MODE) then begin
   presets.real_time = sd.dwell_time
   presets.live_time = 0.
endif else begin
   presets.real_time = 0. 
   presets.live_time = sd.dwell_time
endelse
sd.mca->set_presets, presets

for row=0, n_rows-1 do begin
  for col=0, n_cols-1 do begin

    ; The motors are in the correct position. 
    ; Clear data, begin acquisition
    ; For now we assume that all scalers are on one module
    ; and that there is only one MCA record involved
    ; Erase MCA
    sd.mca->erase
    ; Start MCA. It will not actually start counting until the scaler is
    ; started, since it is gated by the scaler (not true with EPICS)
    ; Erase and start scaler.
    if (sd.gated) then begin
        ; If we are gated then the scaler should count for as long as possible
        sd.scaler->start, sd.dwell_time*10
        ; Wait 0.1 seconds so that we can be sure the scaler has
        ; actually started counting before turning on MCA
        wait, 0.1
    endif else begin
        sd.scaler->start, sd.dwell_time
    endelse
    sd.mca->acquire_on

    ; Wait for MCA to complete.  Wait 0.1 seconds so that we can be sure the MCA has
    ; actually started before we test if it is done.
    wait, 0.1
    sd.mca->acquire_wait, sd.dwell_time
    ; If in gated mode then stop the scaler
    ; If not in gated mode then wait for the scaler
    if (sd.gated) then begin
        sd.scaler->scaler_stop
    endif else begin
        sd.scaler->wait
    endelse

    ; Save ROI counts
    sd.mca->get_roi_counts, total, net
    for i=0, sd.n_rois-1 do begin
      image_data(col, row, i) = net[i]
    endfor
    ; Save scaler counts
    counts = sd.scaler->read()
    for i=0, sd.n_scalers-1 do begin
      j = i + sd.n_rois
      image_data(col, row, j) = counts[i]
    endfor

    elapsed = sd.mca->get_elapsed()
    offset = sd.n_rois + sd.n_scalers
    image_data(col, row, offset) = elapsed.real_time*1000.
    image_data(col, row, offset+1) =elapsed.live_time*1000.

    ; Call the routine to display this pixel
    display_point, row, col

    ; The scan could have been aborted at this point
    if (sd.abort_scan ne 0) then goto, done

    ; Move to next point - skip if last point
    if (col ne n_cols-1) then begin
      sd.motors(0)->move, x_dist(col+1)
      ; If this is line scan move any other motors
      if line_scan then $
        for i=1, sd.n_motors-1 do sd.motors(i)->move, /relative, $
                                                            md(i).inc(0)
      for i=0, sd.n_motors-1 do sd.motors(i)->wait
    endif

  endfor ; Fast motor loop

  ; Move slow axis, skip if last point or if line scan
  if (row ne n_rows-1) and (not line_scan) then begin
    sd.motors(1)->move, y_dist(row+1)
    sd.motors(1)->wait

    ; Move fast motor back to beginning of scan
    sd.motors(0)->move, md(0).start(0)
    sd.motors(0)->wait
  endif

endfor  ; Slow scan loop

done:
    sd.mca->set_presets, old_presets
return
end
