function npts_calc, start_in, stop_in, step_in, step, max

step  = step_in
start = start_in
stop  = stop_in
if (abs(step) le 1.d-8) then  step = (stop - start)/20.0
if (abs(step) le 1.d-8) then  begin
    step = 1.
    npts = 3
endif else begin
    npts   = 1 + round((abs(stop - start) )/abs(step))
    npts   = fix ( (npts > 2) < max)
    step   = (stop - start) / (npts-1)
endelse
return, npts
end

