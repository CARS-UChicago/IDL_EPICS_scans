pro move_to_stage_position, data, position, wait=wait
;
; move to a position by name given the outputs of read_xyzini

do_wait = 1
if (keyword_set(wait)  ne 0) then do_wait = wait

npos = -1
pos  = strlowcase(strtrim(position, 2))
for i = 0, n_elements(data.names)-1 do begin
    if (pos eq strlowcase(data.names[i])) then npos = i
endfor

if (npos eq -1) then begin
    print, ' position: ' , position, ' not found in list!!!'
    return
endif

print, 'Moving to position: ', position

s = caput(data.motor_x,     data.pts[npos].x)
s = caput(data.motor_y,     data.pts[npos].y)
s = caput(data.motor_z,     data.pts[npos].z)
;s = caput(data.motor_finex, data.pts[npos].finex)
;s = caput(data.motor_finey, data.pts[npos].finey)
;s = caput(data.motor_th,    data.pts[npos].th)

if do_wait eq 1 then begin 
    s = caput(data.motor_x,     data.pts[npos].x, /wait)
    s = caput(data.motor_y,     data.pts[npos].y, /wait)
    s = caput(data.motor_z,     data.pts[npos].z, /wait)
    ;s = caput(data.motor_finex, data.pts[npos].finex, /wait)
    ;s = caput(data.motor_finey, data.pts[npos].finey, /wait)
    ;s = caput(data.motor_th,    data.pts[npos].th, /wait)
endif
return
end

function read_stageini, stage_file=stage_file
;
;  read an xyz.ini file and return a structure of named points
;  for x/y/z stage positions
;
;  structure has keys:
;    { motor_x:  x positioner,
;      motor_y:  y positioner,
;      motor_z:  z positioner,
;      points:  array of { name: , x:, y:, z: }  positions

file = 'SampleStage_autosave.ini'
if (keyword_set(stage_file)  ne 0 )  then  file = stage_file
print, ' reading SampleStage definition file ' , file
on_ioerror, bad_file
openr, dlun, file, /get_lun
str     = ' '
group   = ''
npts    = 0
nstage  = 0
names   = strarr(1000)
stages  = strarr(10)

motpv_x = ''
motpv_y = ''
motpv_z = ''
motpv_th = ''
motpv_finex = ''
motpv_finey = ''

point   = {point, name:'', finex:0.0, finey:0.0, x:0.0, y:0.0, z:0.0, th:0.0 }
motor_data  = {motor_finex:'', motor_finey:'', motor_th:'', $
               motor_x:'', motor_y:'', motor_z:'', pts:point }

;point   = {point, name:'', x:0.0, y:0.0, z:0.0}
;motor_data  = {motor_x:'', motor_y:'', motor_z:'', pts:point }

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
        '[stages]': begin
            main = str_sep(str, '=')
            data = str_sep(main[1], '||')
            pvname = strtrim(data[0], 2)
            desc   = strtrim(strlowcase(data[2]), 2)
            case desc of
                'x':      motpv_x = pvname
                'y':      motpv_y = pvname
                'z':      motpv_z = pvname
                'theta':  motpv_th = pvname
                'finex':  motpv_finex = pvname
                'finey':  motpv_finey = pvname
                else: begin
                    print, 'unknown name?' , desc
                    end
            endcase
            stages[nstage] = desc
            nstage = nstage + 1
        end
        '[positions]': begin
            words = str_sep(str, '=')
            data = str_sep(words[1], '||')
            name = strtrim(data[0], 2)
            imgfile = strtrim(data[1], 2)
            vals = str_sep(data[2], ',')
            pt      = point
            pt.name = name
            for i = 0, n_elements(stages)-1 do begin
                sname = stages[i]
                if sname ne '' then begin
                    case sname of
                        'x':     pt.x = vals[i]
                        'y':     pt.y = vals[i]
                        'z':     pt.z = vals[i]
                        'theta':  pt.th = vals[i]
                        'finex':  pt.finex = vals[i]
                        'finey':  pt.finey = vals[i]
                        else: x = 1
                    endcase
                endif
            endfor
            if (npts ge 1) then begin
                pts = [pts, pt]
            endif else begin
                pts = pt
            endelse
            names[npts]= pt.name
            npts   = npts + 1
        end
        else: x = 1
    endcase
    loop_end:
endwhile

close, dlun
free_lun, dlun
names_out  = strarr(npts)
for i = 0, npts-1 do names_out[i]  = names[i]

motor_data = {motor_x:motpv_x, motor_y:motpv_y, motor_z:motpv_z, $
              motor_finex:motpv_finex, motor_finey:motpv_finey, $
              motor_th:motpv_th, $
              names:names_out, pts:pts }

return, motor_data

bad_file:
  print, '  Warning: SampleStage definition file ', file,  ' could not be loaded.'
  return, motor_data
end




