pro scan_me, start=start, stop=stop,step=step, file=file

drive = '13LAB:m1.VAL'
read  = '13LAB:m1.RBV'
det   = ['13LAB:LAE500_Z', '13LAB:LAE500_X']
wait_time = 0.10

n_det = 2


pos   = fltarr(1000)
det   = fltarr(1000,4)

if (keyword_set(step) eq 0)  then step = 0.1
if (keyword_set(start) eq 0) then start = 0
if (keyword_set(stop) eq 0)  then stop = 1
if (keyword_set(file) eq 0)  then file = 'scan.dat'

npts = 1 + fix((start -stop)/step)

for i = 0, npts -1 do begin
  pos[i] = start + i * step
endfor


openw, lun,   file, /get_lun, /append

printf, lun, ';    Simple scan file '
printf, lun, ';  '

for i = 0, npts-1 do begin
    x = caput(drive,pos[i])

    motor_move = 1
    while(motor_move) do begin
        wait, wait_time
        x = caget('13LAB:m1.DMOV',motor_move)
    endwhile

    wait, wait_time
    x = caget(rbv,mpos)
    x = caget(det[0], d1)
    x = caget(det[1], d2)
    printf, lun,  format='(3(1x,g14.7))', mpos, d1, d2

endfor


close, lun
free_lun, lun
return
end



