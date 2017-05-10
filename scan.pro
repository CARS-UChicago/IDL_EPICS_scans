; ************************************************************
pro abort_scan, event
;  This routine gets called when the ABORT_SCAN button is pressed
; It sets the abort_scan flag in the scan descriptor, which the scan
; routines look at after each point and abort the scan
@scan_common

sd.abort_scan = 1
end


; ************************************************************
pro scan, setup=setup, $
          file=file, $
          time=time, $
          motor=motor, $
          start=start, $
          stop=stop, $
          step=step, $
          title=title, $
          plot=plot, $
          confirm=confirm, $
          relative=relative

;+
; NAME:
;       SCAN.PRO
; PURPOSE:
;       To scan motors and collect data.
; CALLING SEQUENCE:
;       SCAN, [keywords]
; INPUTS:
;       None
; KEYWORD PARAMETERS:
;   FILE=filename
;       Used to specify the name of a file in which to save the scan data.
;       Data are saved in Brookhaven Standard Image Format (BSIF).
;       If the file name extension is numeric (e.g. MY_SCAN.001) then the
;       extension number will be automatically incremented after the file is
;       written, so the next scan will be MY_SCAN.002, etc.
;   TIME=time
;       Used to specify the collection time per point in seconds.
;   MOTOR=[motor1, motor2, ...]
;       Used to specify the name(s) of the motors to be scanned.
;   START=start
;   START=[start1, start2, ...]
;       The start position(s) of the motor(s) being scanned.
;       The order of the elements is the same as the scanning regions of each
;       of the motors.
;   STOP=stop
;   STOP=[stop1, stop2, ...]
;       The stop positions(s) of the motor(s) being scanned.
;       The order of the elements is the same as the scanning regions of each
;       of the motors.
;   STEP=step
;   STEP=[step1, step2, ...]
;       The step size(s) of the motor(s) being scanned.
;       The order of the elements is the same as the scanning regions of each
;       of the motors.
;   /RELATIVE
;       If /RELATIVE is specified then the START and STOP positions are
;       positions relative to the current motor position(s). If /RELATIVE
;       is not specified then the START and STOP position(s) are absolute 
;       motor position(s).
;   TITLE=title
;       A string containing the title of the scan.
;   PLOT=plot_values
;       A vector of data values to be plotted in real time as data are
;       collected. The default is not to plot any values on the first scan
;       after entering IDL. Subsequent scans will plot the same data as
;       the previous scan so the PLOT keyword need only be given once.
;       Examples:
;
;       Assume a scaler scan with data being collected from 3 scalers:
;         PLOT=[0,2]  ; will plot the first and third scalers as data are
;                     ; collected.
;       Assume an ROI scan with data being collected from 2 ROIs and 2 scalers:
;         PLOT=[0,1,2]  ; will plot both ROIs and the first scaler.
;
;       Use PLOT=-1 to turn off real-time plotting.
;   /SETUP
;       If set then routine SETUP_SCAN is called before beginning the scan.
;       This allows the user to modify scan parameters with prompting.
;   /CONFIRM
;       If set then routine CONFIRM_SCAN is called before beginning the scan.
;       This echoes the scan parameters and allows the user to abort if they 
;       are not acceptable.
; OUTPUTS:
;       None
; COMMON BLOCKS:
;       BSIF_COMMON  The variables in this common block are modified to reflect
;       the scan parameters.
;       SCAN_COMMON  The scan descriptor structure (SD) is used to control
;       the scan. It is modified by the keywords passed to this routine and
;       by SETUP_SCAN.
; SIDE EFFECTS:
;       Modifies values in above common blocks.
;       Moves motors, reads CAMAC scalers, reads Nuclear Data configruations,
;       etc.
; RESTRICTIONS:
;       The keyword parameters scan only be used to control a subset of the
;       scan parameters. Other parameters can only be modified by calling
;       SETUP_SCAN.
; PROCEDURE:
;       This routine calls SETUP_SCAN and CONFIRM_SCAN if the appropriate
;       keywords are specified. It then does some bookeeping and calls the
;       appropriate scan routine (SCAN_SCALER, SCAN_ROI, SCAN_SPECTRUM,
;       SCAN_MCS, SCAN_GE13).
; MODIFICATION HISTORY:
;       Created January 1992 by Mark Rivers
;       Feb. 22, 1995. Made routine check that scan increment was an integral
;               number of motor steps. Mark Rivers
;       March 1995 Modified for piecewise linear scans. Harvey Rarback
;       October 1997   Mark Rivers Converted to IDL objects
;       November 1997  Mark Rivers Added ABORT_SCAN
;       January 16, 2001  Mark Rivers Added code (from BNL version) to save
;                         positions in piecewise linear scans
;-


@bsif_common
@scan_common
;on_error, 2

if (n_elements(sd) eq 0) or (keyword_set(setup)) then begin
  setup_scan
  confirm = 1
endif

if keyword_set(file) then sd.file_name = file

if keyword_set(time) then sd.dwell_time = time

if n_elements(motor) ne 0 then begin
  for i=0, n_elements(motor)-1 do begin
    m = obj_new('epics_motor', motor)
    if (not obj_valid(m)) then message, 'Unknown motor= ' + motor
    sd.motors[i] = m
    md[i].name = sd.motors[i]->get_name()
  endfor
endif

; Get the current (home) positions of each motor
for i=0, sd.n_motors-1 do begin
  md[i].home = sd.motors[i]->get_position()
endfor

if n_elements(start) ne 0 then begin
  n = -1
  for i=0, sd.n_motors-1 do begin
    for j=0, md[i].n_parts-1 do begin
      n = n + 1
      if n lt n_elements(start) then begin
        if keyword_set(relative) then begin 
          md[i].start(j) = md[i].home + start(n)
        endif else begin
          md[i].start(j) = start(n)
        endelse
      endif
    endfor
  endfor
endif

if n_elements(stop) ne 0 then begin
  n = -1
  for i=0, sd.n_motors-1 do begin
    for j=0, md[i].n_parts-1 do begin
      n = n + 1
      if n lt n_elements(stop) then begin
        if keyword_set(relative) then begin 
          md[i].stop(j) = md[i].home + stop(n)
        endif else begin
          md[i].stop(j) = stop(n)
        endelse
      endif
    endfor
  endfor
endif

if n_elements(step) ne 0 then begin
  n = -1
  for i=0, sd.n_motors-1 do begin
    for j=0, md[i].n_parts-1 do begin
      n = n + 1
      if n lt n_elements(step) then md[i].inc(j) = step(n)
    endfor
  endfor
endif

; Make sure the motor increments are an integral nonzero number of motor steps
for i=0, sd.n_motors-1 do begin
  scale = sd.motors[i]->get_scale()
  for j=0, md[i].n_parts-1 do begin
    t = round(md[i].inc(j) * scale) / scale
    if t eq 0. then t = 1. / scale 
    if (abs(t) ne abs(md[i].inc(j))) then begin
      message, string('Step size of motor ' + md[i].name +' changed from ', $
                      md[i].inc(j), ' to ', t, format = '(a,g0.0,a,g0.0)'), $
                      /continue
      md[i].inc(j) = t
    endif
  endfor
endfor

; Correct the sign of the motor increments if necessary
for i=0, sd.n_motors-1 do begin
  for j=0, md[i].n_parts-1 do begin
    if (md[i].stop(j) gt md[i].start(j)) then begin
      md[i].inc(j) = abs(md[i].inc(j)) 
    endif else begin
      md[i].inc(j) = -abs(md[i].inc(j))
    endelse
  endfor
endfor
     
if n_elements(plot) ne 0 then begin
  sd.plot=-1
  for i=0, n_elements(plot)-1 do sd.plot(plot[i]) = 1
endif

if n_elements(title) ne 0 then sd.title = title

; Compute number of points and target locations in scan
x_dist     = [0.]
sd.dims(0) = 0
for l = 0, md(0).n_parts-1 do begin
  xstart     = md(0).start(l)
  xstop      = md(0).stop(l)
  xstep      = md(0).inc(l)
  ; Underestimate number of scanning steps to minimize chance of "backtracking"
  ; for multiple region scans
  nx         = fix( abs( (xstart - xstop) / xstep)) + 1
  sd.dims(0) = sd.dims(0) + nx
  x_dist     = [x_dist, xstart + findgen( nx) * xstep]
endfor
x_dist = x_dist(1 : *)
if (sd.n_dims eq 2) then begin  ; 2-D scan
  y_dist     = [0.]
  sd.dims(1) = 0
  for l = 0, md(1).n_parts-1 do begin
    ystart     = md(1).start(l)
    ystop      = md(1).stop(l)
    ystep      = md(1).inc(l)
    ny         = fix( abs( (ystart - ystop) / ystep)) + 1
    sd.dims(1) = sd.dims(1) + ny
    y_dist     = [y_dist, ystart + findgen( ny) * ystep]
  endfor
  y_dist = y_dist(1 : *)
endif else begin
  sd.dims(1) = 1
  y_dist     = [0.]
endelse

if keyword_set(confirm) then confirm_scan

if sd.n_dims eq 1 then begin
    n_cols = sd.dims(0)
    n_rows = 1
endif else begin
    n_cols = sd.dims(0)
    n_rows = sd.dims(1)
endelse 
case sd.scan_type of
  SCALER_SCAN:   begin
        ; The number of data at each pixel is the number of scalers
        n_data = sd.n_scalers
        data_title = strarr(n_data)
        for i=0, sd.n_scalers-1 do data_title[i] = sd.scalers[i].title
    end
  ROI_SCAN:      begin
        ; The number of data at each pixel is the number of ROIs plus the number of
        ; scalers plus 2, for live time and real time.
        n_data = sd.n_rois + sd.n_scalers + 2
        data_title = strarr(n_data)
        for i=0, sd.n_rois-1 do data_title[i] = sd.roi[i].name
        for i=0, sd.n_scalers-1 do data_title(sd.n_rois+i) = sd.scalers[i].title
        data_title(sd.n_rois + sd.n_scalers) = 'Real time (msec)'
        data_title(sd.n_rois + sd.n_scalers + 1) = 'Live time (msec)'
    end
  SPECTRUM_SCAN: begin
        ; Dummy value for n_data
        n_data = 1
        data_title = strarr(n_data)
    end
  MCS_SCAN:      message, 'scan_mcs is not supported now.'
endcase
if (md(0).inc(0) gt 0.) then x_normal = 1 else x_normal = 0
if (md(1).inc(0) gt 0.) then y_normal = 1 else y_normal = 0
rotated = 0
x_start = md(0).start(0)
x_stop  = md(0).stop(md(0).n_parts-1)
y_start = md(1).start(0)
y_stop  = md(1).stop(md(1).n_parts-1)

image_title = sd.title
x_title = md(0).name
y_title = md(1).name

image_data = lonarr(n_cols, n_rows, n_data)
user_buffer = [0B]

; Tell user how to abort scan
print, 'Type ^P to pause scan after next pixel'

; Move motors to beginning of scan
for i=0, sd.n_motors-1 do sd.motors[i]->move, md[i].start(0)
for i=0, sd.n_motors-1 do sd.motors[i]->wait

; Reset abort scan flag
sd.abort_scan=0

; Now call the appropriate scan routine
case sd.scan_type of
  SCALER_SCAN:   scan_scaler
  ROI_SCAN:      scan_roi
  SPECTRUM_SCAN: scan_spectrum
  MCS_SCAN:      message, 'scan_mcs is not supported now.'
endcase

; Reset abort scan flag in case scan was aborted
sd.abort_scan=0
; Move all of the motors back to the start of the scan
for i=0, sd.n_motors-1 do sd.motors[i]->move, md[i].home
for i=0, sd.n_motors-1 do sd.motors[i]->wait

if ((md(0).n_parts gt 1) or (md(1).n_parts gt 1)) then begin
    nbytes = 4 * (n_rows + n_cols)
    user_buffer = bytarr(nbytes)
    copy_bytes, nbytes, float( [x_dist, y_dist]), user_buffer
endif

; All done, save the data
if (sd.scan_type ne SPECTRUM_SCAN) then begin
    write_bsif, sd.file_name
    print, 'Data saved in file ', sd.file_name
endif

; Increment the file extension number if it is numeric
sd.file_name = increment_filename(sd.file_name)

; Set X and Y back to autorange (they are reset in plot routine)
!x.range=0
!y.range=0

end
