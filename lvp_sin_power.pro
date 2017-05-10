pro lvp_sin_power, offset=offset, amplitude=amplitude, period=period, dac=dac, update=update

    if (n_elements(offset) eq 0)    then offset = 0.
    if (n_elements(amplitude) eq 0) then amplitude = 0.1
    if (n_elements(period) eq 0)    then period = 1.
    if (n_elements(dac) eq 0)       then dac = '13IDD:DAC1_5.VAL'
    if (n_elements(update) eq 0)    then update = 0.1
   
    timeStart = systime(1);
    while (1) do begin
       dT = systime(1) - timeStart;
       output = offset + amplitude*sin(2. * !pi * dT / period)
       t = caput(dac, output)
       wait, update;
       print, 'Time=', dT, ' output=', output
    endwhile
end

