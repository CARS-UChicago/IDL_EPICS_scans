pro setup_scan

; This routine gets the information for the scan descriptor (sd) and motor
; descriptor (md) for a scan

; Define constants
@scan_common

init_scan_sd

sd.file_name = get_string('File name', sd.file_name)

sd.title = get_string('Scan title', sd.title)

sd.scan_type = get_choice('Scan type (Scaler, ROI, Spectrum, MCS)', $
                           scan_types, sd.scan_type)
sd.n_dims = $
    get_choice('Scan dimensions (1D or 2D)', ['1D', '2D'], sd.n_dims-1) + 1

if (sd.n_dims eq 1) then begin
  sd.n_motors = get_int('Number of motors to scan', sd.n_motors)
endif else begin
  sd.n_motors = 2
endelse

for i=0, sd.n_motors-1 do begin
  print, ' '
  name = get_string(string('Name of motor ',i, format='(a, i0)'), md(i).name)
  m = obj_new('epics_motor', name)
  if (not obj_valid(m)) then message, "Motor does not exist!!!"
  sd.motors(i)=m
  md(i).name = name
  msg1 = ' for motor ' + name
  md(i).start(0) = sd.motors(i)->get_position()
  get_step = 1
  if sd.n_dims eq 1 and sd.n_motors gt 1 then begin
    md(i).n_parts = 1 
    if i gt 0 then get_step = 0
  endif else if sd.scan_type eq SPECTRUM_SCAN and i gt 0 then begin
    md(i).n_parts = 1 
  endif else begin
    md(i).n_parts = get_int( 'Number of piecewise linear scanning regions' + $
                             msg1, md(i).n_parts, min = 1, max = MAX_PARTS)
  endelse
  for l = 0, md(i).n_parts-1 do begin
    msg2 = msg1
    if md(i).n_parts gt 1 then msg2 = msg1 + string( ' in region ', l+1, $
                                                     format = '(a, i0)')
    if md(i).start(l) eq NEW_START then md(i).start(l) = md(i).stop(l-1)
    md(i).start(l) = get_float( 'Start position' + msg2, md(i).start(l))
    md(i).stop(l)  = get_float(  'Stop position' + msg2, md(i).stop(l))
    if get_step then begin
      md(i).inc(l) = get_float(  'Step size'     + msg2, md(i).inc(l))
    endif else begin ; other than first motor in 1-D scan
      md(i).inc(l) = md(0).inc(0) * (md(i).stop(l) - md(i).start(l)) /     $
                                        (md(0).stop(0) - md(0).start(0))
      print, 'Step size' + msg2 + ' = ', md(i).inc(l), format = '(a, g0.0)'
    endelse
  endfor
endfor

if (sd.scan_type eq ROI_SCAN) or $
   (sd.scan_type eq SPECTRUM_SCAN) then begin
  ; Find out what MCA record the user wants
  print, ' '
  sd.mca_pvname = get_string('MCA record', sd.mca_pvname)

  ; Extract just the record name
  sd.mca = obj_new('epics_mca', sd.mca_pvname)
  if (not obj_valid(sd.mca)) then message, $
        "MCA record does not exist or is not correct version!!!"
  sd.n_chans = sd.mca->get_nchans()
  calibration = sd.mca->get_calibration()
  sd.eoffset = calibration.offset
  sd.eslope = calibration.slope
  sd.equad = calibration.quad

  sd.timing_mode = get_choice('Timing mode (Live or Real)', $
                              ['Live', 'Real'], sd.timing_mode)
  if (sd.timing_mode eq LIVE_TIME_MODE) then begin
    sd.dwell_time = get_float('Live time per pixel ', sd.dwell_time)
  endif else begin
    sd.dwell_time = get_float('Real time per pixel ', sd.dwell_time)
  endelse

  if (sd.scan_type eq ROI_SCAN) then begin
    roi = sd.mca->get_rois()
    sd.n_rois = n_elements(roi)
    for i=0, sd.n_rois-1 do begin
        roi(i).label = $
                        get_string('Title for ROI'+string(i), roi(i).label)
        sd.roi(i).name = roi(i).label
        roi(i).bgd_width = $
                        get_int('Number of channels for background window', $
                             roi(i).bgd_width)
        sd.roi(i).bgd_width = roi(i).bgd_width
    endfor
    sd.mca->set_rois, roi
  endif
  if sd.scan_type eq SPECTRUM_SCAN then begin
    sd.roi(0).left_chan = get_int('First channel to store', 1)
    sd.roi(0).right_chan = get_int('Last channel to store', sd.n_chans)
  endif
endif

if (sd.scan_type eq SCALER_SCAN) or $
   (sd.scan_type eq MCS_SCAN) then begin
  sd.dwell_time = get_float('Time per point', sd.dwell_time)
endif

if (sd.scan_type eq ROI_SCAN) or $
   (sd.scan_type eq SPECTRUM_SCAN) or $
   (sd.scan_type eq SCALER_SCAN) then begin
   sd.scaler_pvname = get_string('PV name for scaler ', sd.scaler_pvname)
   scaler = obj_new('epics_scaler', sd.scaler_pvname)
   if (not obj_valid(scaler)) then message, $
        "MCA record does not exist or is not correct version!!!"
   sd.scaler = scaler
   sd.n_scalers = get_int('Number of EPICS scalers to use', sd.n_scalers)
   for i=0, sd.n_scalers-1 do begin
    sd.scalers[i].title = sd.scaler->get_title(i)
    sd.scalers[i].title = get_string( string( 'Title for scaler ', i+1,       $
                                   format = '(a,i0)'), sd.scalers[i].title)
    sd.scaler->set_title, i, sd.scalers[i].title
   endfor
endif

end
