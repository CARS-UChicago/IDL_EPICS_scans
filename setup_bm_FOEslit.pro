pro setup_bm_FOEslit

; Define FOE slit assembly motors
  top = obj_new('epics_motor','13BMA:m1')
  bot = obj_new('epics_motor','13BMA:m2')
  in  = obj_new('epics_motor','13BMA:m3')
  out = obj_new('epics_motor','13BMA:m4')

; Run calibration procedure
  top->calibrate,/negative,/offset
  bot->calibrate,/negative,/offset
  in->calibrate,/negative,/offset
  out->calibrate,/negative,/offset

; Return motors to their "centered" position
  top->move, 0, /ignore_limits
  bot->move, 0, /ignore_limits
  in->move,  0, /ignore_limits
  out->move, 0, /ignore_limits

; Return motors to their "centered" position
; Sometimes motors need 2 move commands to drive away from a limit
  top->move, 0, /ignore_limits
  bot->move, 0, /ignore_limits
  in->move,   0, /ignore_limits
  out->move, 0, /ignore_limits

end