pro init_scan_sd

;+
; NAME:
;       INIT_SCAN_SD
; PURPOSE:
;       To initialize the scan descriptor structure. It needs to be called once
;       in each IDL session in which scanning is done. It does nothing
;       on second and subsequent calls.
; CALLING SEQUENCE:
;       INIT_SCAN_SD
; INPUTS:
;       None
; OUTPUTS:
;       None
; COMMON BLOCKS:
;       SCAN_COMMON, which contains the scan descriptor (SD) and motor
;       descriptor (MD) structures.
; SIDE EFFECTS:
;       Defines a number of new structure types, ROI, SCALER, SD, MD.
; PROCEDURE:
;       Just defines SD and MD structures and puts them in common block 
;       SCAN_COMMON.
; MODIFICATION HISTORY:
;       Created Dec. 1991 by Mark Rivers
;       Modifications:
;       Mar. 1995 by Harvey Rarback to allow piecewise linear md's
;       March 2, 2001 MLR  Added "gated" field to sd for gating scaler with MCA
;       
;-

@scan_common

if (n_elements(sd) ne 0) then return

roi = {roi, $
       name:            " ", $  ; Name of roi
       left_chan:       0, $    ; Left channel
       right_chan:      0, $    ; Right channel
       bgd_width:       0, $    ; Background width
       plot:            1  $    ; Plot flag
      }

scalers = {scalers, $
       title:            " ", $  ; Title of scaler
       plot:            1  $    ; Plot flag
      }

sd =  {sd, $
       file_name:       "test.dat", $; File name
       scan_type:       0,     $; Scan type (scaler, ROI, spectrum, MCS, GE13)
       title:           " ",   $; Scan title
       mca:             obj_new(), $ ; EPICS MCA object
       mca_pvname:      " ",$; EPICS MCA record name
       n_chans:         0, $    ; Number of channels
       eoffset:         0., $   ; Calibration offset
       eslope:          0., $   ; Calibration slope
       equad:           0., $   ; Calibration quadratic term
       n_rois:          0, $    ; Number of ROIs
       roi:             replicate(roi, MAX_ROIS), $ ; ROI structures
       scaler:          obj_new(), $ ; EPICS scaler object
       scaler_pvname:   " ",$   ; EPICS scaler record name
       n_scalers:       1, $    ; Number of scaler channels
       scalers:         replicate(scalers, MAX_SCALERS), $
       gated:           0, $    ; Is scaler gated by MCA? 0=No, 1=Yes
       n_dims:          1, $    ; Number of scan dimensions = 1 or 2
       dims:            make_array(MAX_SCAN_DIMS, value=10), $  
                        ; Scan dimensions
       n_motors:        1, $    ; Number of motors
       motors:          objarr(MAX_MOTORS), $; Maximum number of motors
       dwell_time:      1., $   ; Dwell time (seconds)
       timing_mode:     LIVE_TIME_MODE, $; LIVE_TIME(1) or REAL_TIME (2)
       plot:            make_array(MAX_SCALERS, /INT, value=-1), $ 
                        ; Scalers or ROIs to plot
       abort_scan_widget: 0L, $
       abort_scan:      0L $
     }

md =  {md,               $
       name:        " ", $  ; Motor name
       n_parts:     1,   $  ; Number of piecewise linear scan regions
       start:       replicate( NEW_START, MAX_PARTS), $ ; Region start positions
       stop:        replicate( 1.,        MAX_PARTS), $ ; Region stop  positions
       inc:         replicate( .1,        MAX_PARTS), $ ; Region step  sizes
       home:        0.   $  ; Home position
       }

md = replicate(md, MAX_MOTORS)
sd.plot(0)=0

end
