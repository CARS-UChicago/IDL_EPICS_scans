function read_xyzini, xyz_file=xyz_file
;
;  read an xyz.ini file and return a structure of named points
;  for x/y/z stage positions
;
;  structure has keys:
;    { motor_x:  x positioner,
;      motor_y:  y positioner,
;      motor_z:  z positioner,
;      points:  array of { name: , x:, y:, z: }  positions

file = 'xyz.ini'
if (keyword_set(xyz_file)  ne 0 )  then  file = xyz_file
print, ' reading xyz.ini definition file ' , file
on_ioerror, bad_file
openr, dlun, file, /get_lun
str     = ' '
group   = ''
npts    =  0
point   = {point, name:'', x:0., y:0., z:0. }
motor_data  = {motor_x:'', motor_y:'', motor_z:'', pts:point }

while not (eof(dlun)) do begin
    readf, dlun, str
    str  = strtrim(str,2)
    if (strlen(str) le 1) then goto, loop_end
    c1 = strmid(str, 0, 1)
    if ((c1 eq '#') or (c1 eq ';') or (c1 eq '%')) then goto, loop_end
    if (c1 eq '[') then group  = str

    ieq = strpos(str, '=')
    if (ieq eq -1)  then goto, loop_end        

    case group of
        '[xyz]': begin
            arr = str_sep(str, '=')
            key = strtrim(arr[0],2)
            val = strtrim(arr[1],2)
            case key of
                'x': mot_x = val
                'y': mot_y = val
                'z': mot_z = val
                else: x = 1
            endcase
        end
        '[pos]': begin
            ieq = strpos(str, '=')
            ipp = strpos(str, '||')
            arr = str_sep(strmid(str, ieq+1, strlen(str)),'||')
            if (n_elements(arr) ge 4) then begin
                tmp      = point
                tmp.name = arr[0]
                tmp.x    = arr[1]
                tmp.y    = arr[2]
                tmp.z    = arr[3]
                if (npts ge 1) then begin
                    pts = [pts, tmp]
                endif else begin
                    pts = tmp
                endelse
                npts   = npts + 1
            endif
        end
        else: x = 1
    endcase
    loop_end:
endwhile

close, dlun
free_lun, dlun
motor_data = {motor_x:mot_x, motor_y:mot_y, motor_z:mot_z, pts:pts }

return, motor_data

bad_file:
  print, '  Warning: XYZ definition file ', file,  ' could not be loaded.'
  return, motor_data
end




