pro setup_id_hor_mirror

; Define monochromator assembly motors
  us_pitch  = obj_new('epics_motor','13IDA:m28')
  ds_pitch  = obj_new('epics_motor','13IDA:m29')
  sum_height = obj_new('epics_motor','13IDA:pm7')
  dif_pitch  = obj_new('epics_motor','13IDA:pm8')
  us_jack   = obj_new('epics_motor','13IDA:m30')
  in_jack   = obj_new('epics_motor','13IDA:m31')
  out_jack  = obj_new('epics_motor','13IDA:m32')


; Drive pitch motors simultaneously close to their limits
; such that laser overtilt is not tripped
  us_pitch->move, 0.4, /dial, /ignore_limits
  ds_pitch->move, 0.4, /dial, /ignore_limits

; Drive table motors simultaneously close to their limits
; such that overtilt sensors are not tripped
  us_jack->move,  0.4, /dial, /ignore_limits
  in_jack->move,  0.4, /dial, /ignore_limits
  out_jack->move, 0.4, /dial, /ignore_limits

; Run calibration procedure
  ds_pitch->calibrate,/negative,/offset
  us_pitch->calibrate,/negative,/offset
  out_jack->calibrate,/negative,/offset
  in_jack->calibrate,/negative,/offset
  us_jack->calibrate,/negative,/offset

; Return motors to their "centered" position
  us_pitch->move,  1.0, /dial, /ignore_limits
  ds_pitch->move,  1.0, /dial, /ignore_limits
  us_jack->move,   34, /ignore_limits
  in_jack->move,   34, /ignore_limits
  out_jack->move,  34, /ignore_limits

; Return motors to their "centered" position
; Sometimes motors need 2 move commands to drive away from a limit
  us_pitch->move,  1.0, /dial, /ignore_limits
  ds_pitch->move,  1.0, /dial, /ignore_limits
  us_jack->move,   34, /ignore_limits
  in_jack->move,   34, /ignore_limits
  out_jack->move,  34, /ignore_limits

; Move pseudo-motors so the vertical jacks remain level and don't trip the laser
  dif_pitch->move,  0
  sum_height->move, 5

end