pro setup_bm_mirror

; Define mirror assembly motors
  us_pitch   = obj_new('epics_motor','13BMA:m20')
  ds_pitch   = obj_new('epics_motor','13BMA:m21')
  sum_height = obj_new('epics_motor','13BMA:pm3')
  dif_pitch  = obj_new('epics_motor','13BMA:pm4')
  us_horiz   = obj_new('epics_motor','13BMA:m22')
  ds_horiz   = obj_new('epics_motor','13BMA:m23')



; Drive pitch motors simultaneously close to their limits
; such that laser overtilt is not tripped
  us_pitch->move, 0.4, /dial, /ignore_limits
  ds_pitch->move, 0.4, /dial, /ignore_limits

; Drive table motors simultaneously close to their limits
; such that bellows are not over stretched
  us_horiz->move, 0.5, /dial, /ignore_limits
  ds_horiz->move, 0.5, /dial, /ignore_limits

; Run calibration procedure
  ds_pitch->calibrate,/negative,/offset
  us_pitch->calibrate,/negative,/offset
  ds_horiz->calibrate,/negative,/offset
  us_horiz->calibrate,/negative,/offset

; Return motors to their "centered" position
  us_pitch->move, 1.0, /dial, /ignore_limits
  ds_pitch->move, 1.0, /dial, /ignore_limits
    us_horiz->move, 0, /ignore_limits
  ds_horiz->move, 0, /ignore_limits

; Return motors to their "centered" position
; Sometimes motors need 2 move commands to drive away from a limit
  us_pitch->move, 1.0, /dial, /ignore_limits
  ds_pitch->move, 1.0, /dial, /ignore_limits
  us_horiz->move, 0, /ignore_limits
  ds_horiz->move, 0, /ignore_limits

; Move pseudo-motors so the vertical jacks remain level and don't trip the laser
  dif_pitch->move,  0
  sum_height->move, 20

end