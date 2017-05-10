function file_mod_time, file
  tmod  = 0
  on_ioerror, io_error
  openr, l1, file, /get_lun
  st1   = fstat(l1)
  close, l1
  free_lun, l1
  tmod  = st1.mtime
  io_error:
  return, tmod
end
