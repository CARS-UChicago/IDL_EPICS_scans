function read_dmm, dmm
; Reads channels 7-10 of DMM
volts = fltarr(4)
t = caput(dmm+'done_read.VAL', 1)
repeat begin
	t = caget(dmm+'done_read.VAL', done)
endrep until (done eq 0)
for i=0,3 do begin
	t = caget(dmm+'Ch'+strtrim(i+7,2)+'_raw.VAL', temp)
	volts(i) = temp
endfor
return, volts
end


pro debug_motor, motor, dmm, volts=volts, nsteps=nsteps

if (n_elements(nsteps) eq 0) then nsteps = 8
NPHASES = 4
m = obj_new('epics_motor', motor)
original_position = m->get_position(/step)
print, 'Motor ' + motor + ' original position: ', original_position

; The following assumes that the motor phases are connected to
; inputs 7-10 of the Keithley DMM.

; Put DMM in one-shot mode
t = caput(dmm+'onesh_cont.VAL', 0)

; Put DMM in multiple input mode
t = caput(dmm+'single_multi.VAL', 1)

; Turn on inputs 7-10, put in V DC mode
for i=7, 10 do begin
	t = caput(dmm+'ch'+strtrim(i,2)+'_mode_sel.VAL', 'V DC')
	t = caput(dmm+'Ch'+strtrim(i,2)+'_on_off.VAL', 'ON')
endfor

; Loop through 8 steps of motor in positive direction
volts = fltarr(NPHASES, nsteps, 2)
for i=0, nsteps-1 do begin
	m->move, original_position+i+1, /step
	m->wait
	volts(*,i,0) = read_dmm(dmm)
	print, 'Step=', i+1, ', volts=', volts[*,i,0]
endfor

; Loop through 8 steps of motor in negative direction
for i=0, nsteps-1 do begin
	m->move, original_position+nsteps-i, /step
	m->wait
	volts(*,i,1) = read_dmm(dmm)
	print, 'Step=', nsteps-i, ' volts=', volts[*,i,1]
endfor
m->move, original_position, /step
colors = intarr(4, 3)
colors[0, *] = [255, 255, 255]
colors[1, *] = [255, 0, 0]
colors[2, *] = [0, 255, 0]
colors[3, *] = [0, 0, 255]
tvlct, colors, 1
plot, volts[0,*,0], yrange=[min(volts), max(volts)], xrange=[0, nsteps+1], $
      /nodata, xtitle = 'Step', ytitle='Volts', title=motor, color=1
steps = findgen(nsteps)+1
;steps = rebin(steps, 2*nsteps, /sample)
;steps = [1, steps]
;steps = steps[0:2*nsteps-1]
for i=0, NPHASES-1 do begin
;    y = rebin(reform(volts[i,*,0]), nsteps*2, /sample)
;	oplot, steps+(i-1)*.05, y, psym=-2, color=i+1
	oplot, steps, volts[i,*,0], psym=-2, color=i+1
;   y = rebin(reform(volts[i,*,1]), nsteps*2, /sample)
	oplot, reverse(steps), volts[i,*,1], psym=-2, color=i+1, linestyle=1
	xyouts, .87, .89-.05*i, strtrim(i+1,2), /normal, color=i+1
	plots, [.90, .95], [.90-.05*i, .90-.05*i], psym=-2, color=i+1, /normal
endfor
end