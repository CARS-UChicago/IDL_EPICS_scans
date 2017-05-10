function pre_scan_command, scanpv
;
; this function is meant to be overwritten for custom 'pre-scan' setup

print, 'Nov 2007: pre-scan for scan= ', scanpv

wait_time = 0.25
MAX_beam_count = 600
MAX_beam_count = 60

x = caput('13SDD1:EraseAll',      1)
x = caput('13SDD1:PresetReal',    0)
x = caput('13SDD1:ReadAll.SCAN',9)
x = caput('13SDD1:StatusAll.SCAN',9)

x = caput('13IDC:scaler1.CONT',      0)
x = caput('13IDC:scan1.DDLY', 0.010)
x = caget('13IDC:scan1.P1PV', p1pv)
x = caget('13IDC:scan1.NPTS', npts)
x = caget('13IDC:scan1.P1PA', p1pa)

p1pv = strtrim(p1pv,2)
p0   = p1pa[0] + (p1pa[0] - p1pa[1])/2.0
x    = caput(p1pv,p0)

if p1pv eq '13IDA:E:Energy.VAL' then  begin
   wait, 2.0
   x = caput('13IDA:E:z2_track', 0)
   x = caput('13IDA:E:y2_track', 0)
endif

count = 0
beam  = 0
while ((count le MAX_beam_count) and (beam ne 1)) do begin
    wait, wait_time
    x = caget('13IDA:eps_mbbi4',beam)
    count = count + 1
    if ((count ge 60) and (count le 300)) then wait_time =wait_time + 0.25
endwhile
print, 'beam is on,  moving to beginning of scan... ', p0
x  = caput(p1pv,p0)
wait, wait_time
                               
if p1pv eq '13IDA:E:Energy.VAL' then  adjust_ID_mono_tilt

;  check that feedback is locked
print,  'checking for feedback'
x  = caput('13IDA:mono_pid1.FBON',1)
count  = 0
locked = 0
while ((count le MAX_beam_count) and (locked le 3)) do begin
    wait, wait_time
    x = caget('13IDA:mono_pid1Locked',lval)
    locked = locked + lval
    count = count + 1
endwhile

;  check split ion chamber Sum and Diff
pv_split1 = '13IDC:IP330_11.VAL'
pv_split2 = '13IDC:IP330_12.VAL'
x  = caput('13IDA:mono_pid2.FBON',0)
x  = caput('13IDA:DAC1_2.VAL', 0)
x  = caget(pv_split1,  ipre1)
x  = caget(pv_split2,  ipre2)
split_sum  = ipre1+ipre2
split_diff = (ipre1 - ipre2)/(split_sum+0.002)

if split_sum le 0.1 then begin
    print, 'pre-slit intensity too low -- beam lost?? ', split_sum
endif else begin
    if abs(split_diff) le 5.8 then begin
        print, 'pre-slit looks OK -- no roll adjustment needed'
    endif else begin
        print, 'pre-slit needs roll adjustment'
        rcount = 0
        x = caput('13IDA:m11.TWV', 0.0010)
        while ((rcount le 10) and (abs(split_diff) ge 0.08)) do begin
            rcount = rcount + 1
            adjust_pv = '13IDA:m11.TWF'
            if split_diff gt 0 then  adjust_pv = '13IDA:m11.TWR'
            x = caput(adjust_pv, 1)
            x  = caget(pv_split1,  ipre1)
            x  = caget(pv_split2,  ipre2)
            split_sum = ipre1+ipre2
            split_diff = (ipre1 - ipre2)/(split_sum+0.002)

            print, 'pre-slit diff, sum = ', split_diff, split_sum, rcount
            wait, 0.25
        endwhile
        print, 'pre-slit roll adjustment finished in ' , rcount, ' steps.'
    endelse
endelse

x  = caput('13IDA:mono_pid2.FBON',0)

x  = caget(p1pv, current)
print, ' drive ', p1pv, ' is at ', current
print, 'pre scan done.'
return, 1
end



