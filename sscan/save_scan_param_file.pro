function save_scan_param_file, p, save_as
  main  = (*p).main
  scan1 = (*p).scan1
  scan2 = (*p).scan2
  scan3 = (*p).scan3

  init_file = main.file
  file = ''
  if (save_as eq 1) then file = dialog_pickfile(filter='*.scn', $
                                                get_path=path, $
                                                /write, file = init_file)
  file  = strtrim(file,2)
  if (file eq '') then return, -1
  (*p).main.file = file
  openw, lun,   file, /get_lun
  printf, lun,  ';Scan Parameters: v1.0'
  printf, lun,  ' prefix:      ',  main.prefix
  printf, lun,  ' dimension:   ',  main.dimension
  printf, lun,  ' detectors:   ',  main.detectors
  printf, lun,  ' trigger1:    ',  main.trigger1
  printf, lun,  ' trigger2:    ',  main.trigger2
  printf, lun,  ';scan 1:'
  printf, lun,  '  type:        ', scan1.type
  printf, lun,  '  scanPV:      ', scan1.scanPV
  printf, lun,  '  motor_name:  ', scan1.motor_name
  printf, lun,  '  pos1:        ', scan1.pos1
  printf, lun,  '  rbv1:        ', scan1.rbv1
  printf, lun,  '  units:       ', scan1.units
  printf, lun,  '  nregs:     ', scan1.nregs
  printf, lun,  '  time:      ', scan1.time
  printf, lun,  '  is_rel:    ', scan1.is_rel
  printf, lun,  '  is_kspace: ', scan1.is_kspace
  printf, lun,  '  r1start:   ', scan1.r1start
  printf, lun,  '  r1stop:    ', scan1.r1stop
  printf, lun,  '  r1step:    ', scan1.r1step
  printf, lun,  '  r2start:   ', scan1.r2start
  printf, lun,  '  r2stop:    ', scan1.r2stop
  printf, lun,  '  r2step:    ', scan1.r2step
  printf, lun,  '  r3start:   ', scan1.r3start
  printf, lun,  '  r3stop:    ', scan1.r3stop
  printf, lun,  '  r3step:    ', scan1.r3step
  printf, lun,  '  e0:        ', scan1.e0
  printf, lun,  ';scan 2:'
  printf, lun,  '  type:      ', scan2.type
  printf, lun,  '  scanPV:    ', scan2.scanPV
  printf, lun,  '  motor_name:', scan2.motor_name
  printf, lun,  '  pos1:      ', scan2.pos1
  printf, lun,  '  rbv1:      ', scan2.rbv1
  printf, lun,  '  units:     ', scan2.units
  printf, lun,  '  nregs:     ', scan2.nregs
  printf, lun,  '  time:      ', scan2.time
  printf, lun,  '  is_rel:    ', scan2.is_rel
  printf, lun,  '  is_kspace: ', scan2.is_kspace
  printf, lun,  '  r1start:   ', scan2.r1start
  printf, lun,  '  r1stop:    ', scan2.r1stop
  printf, lun,  '  r1step:    ', scan2.r1step
  printf, lun,  '  r2start:   ', scan2.r2start
  printf, lun,  '  r2stop:    ', scan2.r2stop
  printf, lun,  '  r2step:    ', scan2.r2step
  printf, lun,  '  r3start:   ', scan2.r3start
  printf, lun,  '  r3stop:    ', scan2.r3stop
  printf, lun,  '  r3step:    ', scan2.r3step
  printf, lun,  '  e0:        ', scan2.e0
  printf, lun,  ';scan 3:'
  printf, lun,  '  type:      ', scan3.type
  printf, lun,  '  scanPV:    ', scan3.scanPV
  printf, lun,  '  motor_name:', scan3.motor_name
  printf, lun,  '  pos1:      ', scan3.pos1
  printf, lun,  '  rbv1:      ', scan3.rbv1
  printf, lun,  '  units:     ', scan3.units
  printf, lun,  '  nregs:     ', scan3.nregs
  printf, lun,  '  time:      ', scan3.time
  printf, lun,  '  is_rel:    ', scan3.is_rel
  printf, lun,  '  is_kspace: ', scan3.is_kspace
  printf, lun,  '  r1start:   ', scan3.r1start
  printf, lun,  '  r1stop:    ', scan3.r1stop
  printf, lun,  '  r1step:    ', scan3.r1step
  printf, lun,  '  r2start:   ', scan3.r2start
  printf, lun,  '  r2stop:    ', scan3.r2stop
  printf, lun,  '  r2step:    ', scan3.r2step
  printf, lun,  '  r3start:   ', scan3.r3start
  printf, lun,  '  r3stop:    ', scan3.r3stop
  printf, lun,  '  r3step:    ', scan3.r3step
  printf, lun,  '  e0:        ', scan3.e0
  printf, lun,  ';detectors:'
  close, lun
  free_lun, lun
  print, ' wrote file = ', file
  return, 0
end
