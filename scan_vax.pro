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
;-


@bsif_common
@scan_common
on_error, 2
camac_open

if (n_elements(sd) eq 0) or (keyword_set(setup)) then begin
  setup_scan
  confirm = 1
endif

if keyword_set(file) then sd.file_name = file

if keyword_set(time) then sd.dwell_time = time

if n_elements(motor) ne 0 then begin
  for i=0, n_elements(motor)-1 do begin
    k = lookup_motor(motor(i))
    if k eq 0 then message, 'Unknown motor= '+motor(i)
    md(k).name = motor(i)
    sd.active_motors(i) = k
  endfor
endif

k = sd.active_motors ; Shorthand

; Get the current (home) positions of each motor
for i=0, sd.n_motors-1 do begin
  get_mot_pos, k(i), temp
  md(k(i)).home = temp
endfor

if n_elements(start) ne 0 then begin
  n = -1
  for i=0, sd.n_motors-1 do begin
    for j=0, md(k(i)).n_parts-1 do begin
      n = n + 1
      if n lt n_elements(start) then begin
        if keyword_set(relative) then begin 
          md(k(i)).start(j) = md(k(i)).home + start(n)
        endif else begin
          md(k(i)).start(j) = start(n)
        endelse
      endif
    endfor
  endfor
endif

if n_elements(stop) ne 0 then begin
  n = -1
  for i=0, sd.n_motors-1 do begin
    for j=0, md(k(i)).n_parts-1 do begin
      n = n + 1
      if n lt n_elements(stop) then begin
        if keyword_set(relative) then begin 
          md(k(i)).stop(j) = md(k(i)).home + stop(n)
        endif else begin
          md(k(i)).stop(j) = stop(n)
        endelse
      endif
    endfor
  endfor
endif

if n_elements(step) ne 0 then begin
  n = -1
  for i=0, sd.n_motors-1 do begin
    for j=0, md(k(i)).n_parts-1 do begin
      n = n + 1
      if n lt n_elements(step) then md(k(i)).inc(j) = step(n)
    endfor
  endfor
endif

; Make sure the motor increments are an integral nonzero number of motor steps
for i=0, sd.n_motors-1 do begin
  get_motor_info, k(i), scale=scale
  for j=0, md(k(i)).n_parts-1 do begin
    t = round(md(k(i)).inc(j) * scale) / scale
    if t eq 0. then t = 1. / scale 
    if (abs(t) ne abs(md(k(i)).inc(j))) then begin
      message, string('Step size of motor ' + md(k(i)).name +' changed from ', $
                      md(k(i)).inc(j), ' to ', t, format = '(a,g0.0,a,g0.0)'), $
                      /continue
      md(k(i)).inc(j) = t
    endif
  endfor
endfor

; Correct the sign of the motor increments if necessary
for i=0, sd.n_motors-1 do begin
  for j=0, md(k(i)).n_parts-1 do begin
    if (md(k(i)).stop(j) gt md(k(i)).start(j)) then begin
      md(k(i)).inc(j) = abs(md(k(i)).inc(j)) 
    endif else begin
      md(k(i)).inc(j) = -abs(md(k(i)).inc(j))
    endelse
  endfor
endfor
     
if n_elements(plot) ne 0 then begin
  sd.plot=-1
  for i=0, n_elements(plot)-1 do sd.plot(i) = plot(i)
endif

if n_elements(title) ne 0 then sd.title = title

; Compute number of points and target locations in scan
x_dist     = [0.]
sd.dims(0) = 0
for l = 0, md(k(0)).n_parts-1 do begin
  xstart     = md(k(0)).start(l)
  xstop      = md(k(0)).stop(l)
  xstep      = md(k(0)).inc(l)
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
  for l = 0, md(k(1)).n_parts-1 do begin
    ystart     = md(k(1)).start(l)
    ystop      = md(k(1)).stop(l)
    ystep      = md(k(1)).inc(l)
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

; Copy scan parameters to BSIF common block variables
if sd.n_dims eq 1 then begin
  n_cols = sd.dims(0)
  n_rows = 1
endif else begin
  n_cols = sd.dims(0)
  n_rows = sd.dims(1)
endelse
if sd.scan_type eq ROI_SCAN then begin
  ; The number of data at each pixel is the number of ROIs plus the number of
  ; scalers plus 2, for live time and real time.
  n_data = sd.n_rois + sd.n_scalers + 2
endif
if (sd.scan_type eq SCALER_SCAN) then begin
  ; The number of data at each pixel is the number of scalers
  n_data = sd.n_scalers
endif
if (md(k(0)).inc(0) gt 0.) then x_normal = 1 else x_normal = 0
if (md(k(1)).inc(0) gt 0.) then y_normal = 1 else y_normal = 0
rotated = 0
x_start = md(k(0)).start(0)
x_stop  = md(k(0)).stop(md(k(0)).n_parts-1)
y_start = md(k(1)).start(0)
y_stop  = md(k(1)).stop(md(k(1)).n_parts-1)

image_title = sd.title
x_title = md(k(0)).name
y_title = md(k(1)).name
data_title = strarr(n_data)
if (sd.scan_type eq ROI_SCAN) then begin
  for i=0, sd.n_rois-1 do data_title(i) = sd.roi(i).name
  for i=0, sd.n_scalers-1 do data_title(sd.n_rois+i) = sd.scaler(i).name
  data_title(sd.n_rois + sd.n_scalers) = 'Real time (msec)'
  data_title(sd.n_rois + sd.n_scalers + 1) = 'Live time (msec)'
endif
if (sd.scan_type eq SCALER_SCAN) then begin
  for i=0, sd.n_scalers-1 do data_title(i) = sd.scaler(i).name
endif

image_data = lonarr(n_cols, n_rows, n_data)
USER_BUFFER = [0B]

; Tell user how to abort scan
print, 'Type ^P to pause scan after next pixel'

; Move motors to beginning of scan
for i=0, sd.n_motors-1 do move_motor_to, k(i), md(k(i)).start(0)
for i=0, sd.n_motors-1 do motor_wait, k(i)

; Now call the appropriate scan routine
case sd.scan_type of
  SCALER_SCAN:   scan_scaler
  ROI_SCAN:      scan_roi
  SPECTRUM_SCAN: scan_spectrum
  MCS_SCAN:      message, 'scan_mcs is not supported now.'
  GE13_SCAN:     scan_ge13
endcase

; Move all of the motors back to the start of the scan
for i=0, sd.n_motors-1 do move_motor_to, k(i), md(k(i)).home
for i=0, sd.n_motors-1 do motor_wait, k(i)

; Temporary kludge to save x_, y_dist
IF MD(K(0)).N_PARTS GT 1 OR MD(K(1)).N_PARTS GT 1 THEN BEGIN
  NBYTES = 4 * (N_ROWS + N_COLS)
  USER_BUFFER = BYTARR(NBYTES)
  COPY_BYTES, NBYTES, FLOAT( [X_DIST, Y_DIST]), USER_BUFFER
ENDIF

; All done, save the data
write_bsif, sd.file_name
print, 'Data saved in file ', sd.file_name

; Increment the file extension number if it is numeric
file_parse, sd.file_name, disk, dir, file, ext, version
on_ioerror, not_numeric
nc = strlen(ext) - 1
ext = strmid(ext, 1, nc)  ; Peel off the period
ext = fix(ext)+1      ; Convert to number, add one, jump on error
nc = strtrim(string(nc),2)
ext = string(ext, format='(i'+nc+'.'+nc+')')
sd.file_name = file + '.' + ext
not_numeric:

end
