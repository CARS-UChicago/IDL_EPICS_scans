; This program tests motors

motor = obj_new('epics_motor', '13BMD:m51')
nloops = 100
distance = 0.1

for i=0, nloops-1 do begin
    motor->move, distance, /relative
    t0 = systime(1)
    done = motor->done()
    j=0
    while (done) do begin
        done = motor->done()
        j=j+1
    endwhile
    t1 = systime(1)
    if (j gt 0) then print, 'done for ', j, ' polls ', t1-t0, ' seconds on loop ', i
    motor->wait
    distance = -distance
endfor

end

