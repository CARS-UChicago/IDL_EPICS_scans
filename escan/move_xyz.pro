pro restart_motor, motorname
  print, 'RESTART MOTOR !!! ', motorname
  s = caput(motorname + '.SPMG', 0)
  wait, 0.25
  s = caput(motorname + '.SPMG', 3)
return
end

pro wait_for_motor, pv, tmax=tmax
      xtmax = 120
      if (keyword_set(tmax) ne 0) then xtmax =tmax
      pv_dmov = strmid(pv,0,strpos(pv,'.VAL'))+'.DMOV'
      pv_rbv  = strmid(pv,0,strpos(pv,'.VAL'))+'.RBV'
      done_moving = 0
      count = 0
      s = caget(pv_rbv, rbv_old)
      count_max = xtmax * 10.0
      while done_moving eq 0 do begin
          s = caget(pv_dmov, done_moving)
          if count ge count_max then done_moving = 1
          count  = count+1
          wait,0.1
          s = caget(pv_rbv, rbv_new)
          if (done_moving eq 0) and (count mod 8 eq 0) and (abs(rbv_new - rbv_old) le 0.002) then begin
             restart_motor, pv
          endif
          rbv_old = rbv_new
      endwhile
return
end

pro move_xyz, position=position, xyz_file=xyz_file, no_wait=no_wait, zoffset=zoffset
; move to a named position in an xyz.ini file

file    = 'xyz_autosave.ini'
pos     = ''
do_wait = 1
zoff    = 0.001

if (keyword_set(xyz_file)  ne 0 )  then  file = xyz_file
if (keyword_set(position)  ne 0 )  then  pos  = position
if (keyword_set(no_wait)   eq 1 )  then  do_wait = 0
if (keyword_set(zoffset)   ne 0 )  then  zoff = zoffset

; print, 'MOVE XYZ  zoff = ', zoff, zoffset, keyword_set(zoffset)

pos  = strlowcase(strtrim(pos,2))
mdat = read_xyzini(xyz_file=file)
imot = -1

for i = 0, n_elements(mdat.pts)-1 do begin
   name = strlowcase(strtrim(mdat.pts[i].name,2))
   if (name eq pos) then  imot = i
endfor

if imot lt 0 then begin
   print, '  cannot find position named ', pos
endif else begin
   print, '  moving to position named ', pos
   z0 = mdat.pts[imot].z + zoff
   s  = caput(mdat.motor_z,  z0)
   
   if abs(zoff)>0.001 then  wait_for_motor, mdat.motor_z, tmax=30
   ;  print, 'put x,y'
   s = caput(mdat.motor_x,  mdat.pts[imot].x)
   s = caput(mdat.motor_y,  mdat.pts[imot].y)
   
   if (do_wait eq 1) then begin
      ; print, 'wait for x and y'
      wait_for_motor, mdat.motor_x, tmax=30
      ; print, 'wait for y'
      wait_for_motor, mdat.motor_y, tmax=30
   endif
   ; print, 'return to final z pos'
   s = caput(mdat.motor_z,  mdat.pts[imot].z)
   wait_for_motor, mdat.motor_z, tmax=30
   
endelse
return
end
