pro move_to_position, data, position
;
; move to a position by name given the outputs of read_xyzini

npos = -1
pos  = strlowcase(strtrim(position,2))
for i = 0, n_elements(data.names)-1 do begin
    if (pos eq strlowcase(data.names[i])) then npos = i
endfor

if (npos eq -1) then begin
    print, ' position: ' , position, ' not found in list!!!'
    return
endif

print, 'Moving to position: ', position

s = caput(data.motor_x,  data.pts[npos].x)
s = caput(data.motor_y,  data.pts[npos].y)
s = caput(data.motor_z,  data.pts[npos].z)

; print, ' s = caput(', data.motor_x,  data.pts[npos].x
; print, ' s = caput(', data.motor_y,  data.pts[npos].y
; print, ' s = caput(', data.motor_z,  data.pts[npos].z

dmove = strarr(3)
dmove[0] = strmid(data.motor_x,0,strpos(data.motor_x,'.')) + '.DMOV'
dmove[1] = strmid(data.motor_y,0,strpos(data.motor_y,'.')) + '.DMOV'
dmove[2] = strmid(data.motor_z,0,strpos(data.motor_z,'.')) + '.DMOV'

waiting = 1
count   = 0
while (waiting eq 1) do begin
    waiting = 0
    for i = 0, 2 do begin
        s = caget(dmove[i],x)
        if (x eq 0) then waiting = 1
    endfor
    wait, 1
    if (count gt 30) then waiting = 0
endwhile


return
end


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
names   = strarr(1000)

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
                tmp.name = strtrim(arr[0],2)
                tmp.x    = arr[1]
                tmp.y    = arr[2]
                tmp.z    = arr[3]
                if (npts ge 1) then begin
                    pts = [pts, tmp]
                endif else begin
                    pts = tmp
                endelse
                names[npts]= tmp.name
                npts   = npts + 1
            endif
        end
        else: x = 1
    endcase
    loop_end:
endwhile

close, dlun
free_lun, dlun
names_out  = strarr(npts)
for i = 0, npts-1 do names_out[i]  = names[i]

motor_data = {motor_x:mot_x, motor_y:mot_y, motor_z:mot_z, names:names_out, pts:pts }

return, motor_data

bad_file:
  print, '  Warning: XYZ definition file ', file,  ' could not be loaded.'
  return, motor_data
end




