pro setup_id_FOEslit

; Define FOE slit assembly motors
  h_pos = obj_new('epics_motor','13IDA:m1')
  h_wid = obj_new('epics_motor','13IDA:m2')
  v_pos = obj_new('epics_motor','13IDA:m3')
  v_wid = obj_new('epics_motor','13IDA:m4')

; Run calibration procedure
  h_pos->calibrate,/negative,/offset
  h_wid->calibrate,/negative,/offset
  v_pos->calibrate,/negative,/offset
  v_wid->calibrate,/negative,/offset

; Return motors to their "centered" position
  h_pos->move, 0, /ignore_limits
  h_wid->move, 0, /ignore_limits
  v_pos->move, 0, /ignore_limits
  v_wid->move, 0, /ignore_limits

; Return motors to their "centered" position
; Sometimes motors need 2 move commands to drive away from a limit
  h_pos->move, 0, /ignore_limits
  h_wid->move, 0, /ignore_limits
  v_pos->move, 0, /ignore_limits
  v_wid->move, 0, /ignore_limits

end