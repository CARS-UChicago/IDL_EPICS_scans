pro parse_file_name, file, path, name, extension, version


if (!version.os_family eq 'VMS') then begin
  full_name = findfile(file)
  full_name = full_name(0)
  start = 0
  stop = strpos(full_name, ']', start)
  n = stop - start + 1
  path = strmid(full_name, start, n)

  start = stop + 1
  stop = strpos(full_name, '.', start) - 1
  n = stop - start + 1
  name = strmid(full_name, start, n)

  start = stop + 1
  stop = strpos(full_name, ';', start) - 1
  n = stop - start + 1
  extension = strmid(full_name, start, n)

  start = stop + 1
  stop = strlen(full_name)
  n = stop - start + 1
  version = strmid(full_name, start, n)

endif else begin

  ; Find the last "/" in the file name
  path = ""
  extension= ""
  name = file
  pos = strpos(name, '/')
  if (pos gt 0) then begin
    path = strmid(name, 0, pos)
    name = strmid(name, pos+1, 100)
  endif
  pos = strpos(name, '.')
  if (pos gt 0) then begin
    name = strmid(name, 0, pos)
    ext  = strmid(name, pos+1, 100)
  endif
endelse

end
