pro scan_roi

@bsif_common
@scan_common
@camdef

sd.config_chan = cam_open(sd.config_name)
real_time_buff = [0L, 0L]
live_time_buff = [0L, 0L]
if (sd.timing_mode eq LIVE_TIME_MODE) then begin
  live_time_buff = secs_to_delta(sd.dwell_time)
endif else begin
  real_time_buff = secs_to_delta(sd.dwell_time)
endelse
cam_putp, sd.config_chan, CAM_X_PREAL, real_time_buff
cam_putp, sd.config_chan, CAM_X_PLIVE, live_time_buff


k = sd.active_motors ; Shorthand
line_scan = (sd.n_dims eq 1)
real_time = 0. 
live_time = 0.
time_buff=lonarr(2)
if (sd.n_rois gt 0) then background = lonarr(sd.n_rois)
spect_data = lonarr(sd.n_chans)
print_time = 0.
decay=1.0

for row=0, n_rows-1 do begin
  for col=0, n_cols-1 do begin

    ; The motors are in the correct position. Tell the ND9900 to
    ; clear data, begin acquisition
    ; THE FOLLOWING PRINT STATEMENT IS NECESSARY TO SOLVE A TIMING BUG WHICH HAS
    ; SURFACED EITHER IN THE NEW VERSION OF THE NUCLEAR DATA SOFTWARE OR THE NEW
    ; VERSION OF MOTOR_WAIT. IT NEEDS TO BE FIXED
wait_for_beam: 
    print, 'Erasing ND9900'
    status = cam_command(sd.config_chan, 'ERASE')
    for i=0, sd.n_scalers-1 do clear_scaler, sd.scaler(i).sys_number
    status = cam_command(sd.config_chan, 'ON')

    ; Wait for ND9900 acquisition to complete.
    nd_wait, sd.config_chan

    if (sd.beam_scaler ge 0) then begin  ; check beam dump
      beam_check = read_scaler(sd.scaler(sd.beam_scaler).sys_number)
      ; Get real time
      cam_getp, sd.config_chan, CAM_X_EREAL, time_buff
      real_time = delta_to_secs(time_buff)
      ; Get live time
      cam_getp, sd.config_chan, CAM_X_ELIVE, time_buff
      live_time = delta_to_secs(time_buff)
      
      if (real_time GT 0.) then beam_check = beam_check / real_time
      print, beam_check
      ; If this is the first measurement then save this initial value
      if (col eq 0) and (row eq 0) then begin
        initial_beam_check = beam_check
        if (initial_beam_check EQ 0.) then message, 'Zero beam check counts'
      endif

      decay = beam_check / initial_beam_check
      ; If beam check is <10% of initial value, beam has dumped
      if (decay lt 0.1) then begin
        if systime(1) - print_time ge 900. then begin
          print, 'Beam has dumped, waiting at ' + strmid( systime(), 11,5) + '.'
          print_time = systime(1)
        endif
        wait, 5
        goto, wait_for_beam
      endif else if print_time ne 0. then begin
        print_time = 0.
        print, 'Beam restored at ' + strmid( systime(), 11, 5) + '.'
      endif
    endif

    ; Read spectrum from ND9900
    cam_read, sd.config_chan, spect_data, 1, 1, sd.n_chans

    for i=0, sd.n_rois-1 do begin
      background(i) = 0
      l = sd.roi(i).left_chan 
      r = sd.roi(i).right_chan
      w = sd.roi(i).bgd_width
      if (w GT 0) then begin
        background(i) = (r-l+1) * $
                         (total(spect_data((l-w):(l-1))) + $
                         total(spect_data((r+1):(r+w)))) / (2.*w)
      endif
      image_data(col, row, i) = total(spect_data(l:r)) - background(i)
    endfor

    ; Save scaler counts
    offset = sd.n_rois
    for i=0, sd.n_scalers-1 do begin
      image_data(col, row, offset+i) = read_scaler(sd.scaler(i).sys_number)
    endfor

    ; Save elapsed live and real time in msec
    offset = sd.n_rois + sd.n_scalers
    image_data(col, row, offset) = real_time*1000.
    image_data(col, row, offset+1) = live_time*1000.

    ; Call the routine to display this pixel
    display_point, row, col, decay, background

    ; Move to next point - skip if last point
    if (col ne n_cols-1) then begin
      move_motor_to, k(0), x_dist(col+1)
      ; If this is line scan move any other motors
      if line_scan then $
        for i=1, sd.n_motors-1 do move_motor_by, k(i), md(k(i)).inc(0)
      for i=0, sd.n_motors-1 do motor_wait, k(i)
    endif

  endfor ; Fast motor loop

  ; Move slow axis, skip if last point or if line scan
  if (row ne n_rows-1) and (not line_scan) then begin
    move_motor_to, k(1), y_dist(row+1)
    motor_wait, k(1)

    ; Move fast motor back to beginning of scan
    move_motor_to, k(0), md(k(0)).start(0)
    motor_wait, k(0)
  endif

endfor ; Slow motor loop

; Set preset live and real times back to 0 so we can collect by hand
cam_putp, sd.config_chan, CAM_X_PREAL, [0L, 0L]
cam_putp, sd.config_chan, CAM_X_PLIVE, [0L, 0L]

; Close the ND configuration so other processes can access it
cam_close

return
end
