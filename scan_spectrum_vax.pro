pro scan_spectrum, file_name

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

k = sd.active_motors  ; Shorthand
n_cols = sd.roi(0).right_chan - sd.roi(0).left_chan + 1
n_rows = sd.dims(0)
; The number of data at each pixel is always 1 for now
n_data = sd.dims(1)
image_data = lonarr(n_cols, n_rows, n_data)
y_start = x_start
y_stop  = x_stop
y_dist  = x_dist
x_start = sd.eoffset + sd.roi(0).left_chan*sd.eslope
x_stop  = sd.eoffset + sd.roi(0).right_chan*sd.eslope
x_dist  = findgen(n_cols)/((n_cols-1)>1)*(x_stop-x_start) + x_start

x_title = 'Energy'
y_title = md(k(0)).name
data_title = strarr(n_data)
data_title(0) = string(sd.n_scalers)+ $
       ' Scalers; Real time; Live time; Spectral counts('+ $
       string(n_cols)+' channels)'
for i=1, n_data-1 do data_title(i) = 'Row '+string(i)
image_data = lonarr(n_cols, n_rows, n_data)

line_scan = (sd.n_dims eq 1)
real_time = 0. 
live_time = 0.
time_buff=lonarr(2)
spect_data = lonarr(n_cols)
decay = 1.
print_time = 0.

for row=0, n_data-1 do begin
  for col=0, n_rows-1 do begin

    ; The motors are in the correct position. Tell the ND9900 to
    ; clear data, begin acquisition
    ; THE FOLLOWING PRINT STATEMENT IS NECESSARY TO SOLVE A TIMING BUG WHICH HAS
    ; SURFACED EITHER IN THE NEW VERSION OF THE NUCLEAR DATA SOFTWARE OR THE NEW
    ; VERSION OF MOTOR_WAIT. IT NEEDS TO BE FIXED
    print, 'Erasing ND9900'
wait_for_beam: 
    status = cam_command(sd.config_chan, 'ERASE')
    for i=0, sd.n_scalers-1 do clear_scaler, sd.scaler(i).sys_number
    status = cam_command(sd.config_chan, 'ON')

    ; Wait for ND9900 acquisition to complete.
    nd_wait, sd.config_chan

    if (sd.beam_scaler ge 0) then begin   ; check beam dump
      beam_check = read_scaler(sd.scaler(sd.beam_scaler).sys_number)
      ; Get real time
      cam_getp, sd.config_chan, CAM_X_EREAL, time_buff
      real_time = delta_to_secs(time_buff)
      ; Get live time
      cam_getp, sd.config_chan, CAM_X_ELIVE, time_buff
      live_time = delta_to_secs(time_buff)
    
      if (real_time GT 0.) then beam_check = beam_check / real_time

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
  cam_read, sd.config_chan, spect_data, sd.roi(0).left_chan, 1, n_cols

  image_data(0, col, row) = spect_data

  ; Save scaler counts
  offset = 0
  for i=0, sd.n_scalers-1 do begin
    image_data(offset+i, col, row) = read_scaler(sd.scaler(i).sys_number)
  endfor

    ; Save elapsed live and real time in msec
  offset = sd.n_scalers
  image_data(offset, col, row) = real_time*1000.
  image_data(offset+1, col, row) = live_time*1000.

    ; Call the routine to display this pixel
    display_point, row, col, decay, background

    ; The scan could have been aborted at this point
    if (sd.abort_scan ne 0) then return

    ; Move to next point - skip if last point
    if (col ne n_rows-1) then begin
      move_motor_to, k(0), y_dist(col+1)
      ; If this is line scan move any other motors
      if line_scan then $
        for i=1, sd.n_motors-1 do move_motor, /relative, k(i), md(k(i)).inc(0)
      for i=0, sd.n_motors-1 do motor_wait, k(i)
    endif

  endfor ; Fast motor loop

  ; Move slow axis, skip if last point or if line scan
  if (row ne n_data-1) and (not line_scan) then begin
    move_motor, /relative, k(1), md(k(1)).inc(0) ; no piecewise linear available here
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

; Close the Fortran output lun if open
if (n_elements(fortran_lun) ne 0) then close, fortran_lun

return
end
