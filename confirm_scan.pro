pro confirm_scan

;+
; NAME:
;       CONFIRM_SCAN
; PURPOSE:
;       Echoes the scan parameters for the scan and prompts the user to confirm
;       that they are acceptable.
; CALLING SEQUENCE:
;       CONFIRM_SCAN
; INPUTS:
;       None
; OUTPUTS:
;       None
; COMMON BLOCKS:
;       SCAN_COMMON which contains the current scan parameters.
; SIDE EFFECTS
;       If the user does not accept the scan (types "No") then this routine
;       returns by calling MESSAGE. The calling routine should thus issue
;       the approriate ON_ERROR call before calling CONFIRM_SCAN.
; PROCEDURE:
;       Types out fields in scan descriptor (SD) structure. Prompts for whether
;       these parameters are OK.
; MODIFICATION HISTORY:
;       Created Dec. 1991 by Mark Rivers
;       Modified Mar. 1995 by Harvey Rarback to do piecewise linear scans
;-

@scan_common

print, ' '
print, '                 SUMMARY OF SCAN'

print, 'Scan type: ', scan_types(sd.scan_type)
if sd.n_dims eq 1 then begin
  print, '1-D scan, number of points = ', sd.dims(0), format = '(a, i0)'
endif else begin
  print, '2-D scan, number of points = [', sd.dims(0), ', ', sd.dims(1), ']', $
         format = '(a, i0, a, i0, a)'
endelse
for i=0, sd.n_motors-1 do begin
  print, 'Motor ', md(i).name, ':'
  for l = 0, md(i).n_parts-1 do begin
    if l gt 0 then print, ' '
    if md(i).n_parts gt 1 then print, '  Region ', l+1, ':', format = '(a,i0,a)'
    print, '  Start     = ', md(i).start(l)
    print, '  Stop      = ', md(i).stop(l)
    print, '  Step size = ', md(i).inc(l)
    print, '  Range     = ', md(i).stop(l) - md(i).start(l)
  endfor
endfor

total_time = sd.dwell_time * (sd.dims(0)) * (sd.dims(1))
print, 'Total collection time: ', $
  total_time, ' (seconds) = ', $
  total_time/60., ' (minutes) = ', $
  total_time/3600., ' (hours)', format='(a,f8.1,a,f7.2,a,f6.2,a)'
if (sd.scan_type eq ROI_SCAN) then begin
  print, ' '
  print, ' ROI            Left                Right         Title'
  print, '           Energy  Channel      Energy  Channel
  for i = 0, sd.n_rois-1 do begin
   left_energy = sd.mca->chan_to_energy(sd.roi(i).left_chan)
   right_energy = sd.mca->chan_to_energy(sd.roi(i).right_chan)
   print, i, left_energy, sd.roi(i).left_chan, $
             right_energy, sd.roi(i).right_chan, sd.roi(i).name, $
             format='(i3, f, i6, f, i6, 5x, a)'
  endfor
endif

if (sd.scan_type eq SCALER_SCAN) or $
   (sd.scan_type eq ROI_SCAN) or $
   (sd.scan_type eq SPECTRUM_SCAN) or $
   (sd.scan_type eq GE13_SCAN) then begin
  print, ' '
  print, 'Scaler        Title'
  for i = 0, sd.n_scalers-1 do begin
    print, i, sd.scalers[i].title, format='(i3, 6x, a, 6x, a)'
  endfor
  print, ' '
endif

end
