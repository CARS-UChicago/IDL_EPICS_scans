pro setup_id_pinhole

; Define pinhole assembly motors
  y_up = obj_new('epics_motor','13IDA:m5')
  y_in = obj_new('epics_motor','13IDA:m6')
  y_out = obj_new('epics_motor','13IDA:m7')
  x_up = obj_new('epics_motor','13IDA:m8')
  y_dn = obj_new('epics_motor','13IDA:m9')

; Run calibration procedure
  y_up->calibrate,/negative,/offset
  y_in->calibrate,/negative,/offset
  y_out->calibrate,/negative,/offset
  x_up->calibrate,/negative,/offset
  x_dn->calibrate,/negative,/offset

; Return motors to their "centered" position
  y_up->move, 0, /ignore_limits
  y_in->move, 0, /ignore_limits
  y_out->move, 0, /ignore_limits
  x_up->move, 0, /ignore_limits
  x_dn->move, 0, /ignore_limits

; Return motors to their "centered" position
; Sometimes motors need 2 move commands to drive away from a limit
  y_up->move, 0, /ignore_limits
  y_in->move, 0, /ignore_limits
  y_out->move, 0, /ignore_limits
  x_up->move, 0, /ignore_limits
  x_dn->move, 0, /ignore_limits

end