pro setup_id_mono

; Define monochromator assembly motors
  mono    = obj_new('epics_motor','13IDA:m17')
  xtal_z  = obj_new('epics_motor','13IDA:m14')
  y_up    = obj_new('epics_motor','13IDA:m12')
  y_in    = obj_new('epics_motor','13IDA:m11')
  y_out   = obj_new('epics_motor','13IDA:m10')
  cage_y  = obj_new('epics_motor','13IDA:m13')

; Drive table motors simultaneously close to their limits
  y_up->move,  0.5, /dial, /ignore_limits
  y_in->move,  0.5, /dial, /ignore_limits
  y_out->move, 0.5, /dial, /ignore_limits

; Run calibration procedure
  mono->calibrate,/negative,/offset
  xtal_z->calibrate,/negative,/offset
  y_up->calibrate,/negative,/offset
  y_in->calibrate,/negative,/offset
  y_out->calibrate,/negative,/offset
  cage_y->calibrate,/negative,/offset

; Return motors to their "centered" position
  mono->move,   0, /ignore_limits
  xtal_z->move, 100, /ignore_limits
  y_up->move,   27, /ignore_limits
  y_in->move,   27, /ignore_limits
  y_out->move,  27, /ignore_limits
  cage_y->move, 0, /ignore_limits

; Return motors to their "centered" position
; Sometimes motors need 2 move commands to drive away from a limit
  mono->move,   0, /ignore_limits
  xtal_z->move, 100, /ignore_limits
  y_up->move,   27, /ignore_limits
  y_in->move,   27, /ignore_limits
  y_out->move,  27, /ignore_limits
  cage_y->move, 0, /ignore_limits

end