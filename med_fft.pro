pro med_fft, med_name, med_fft_name, med_raw=med, med_fft=med_fft
    if (n_elements(med_name) eq 0) then med_name='13IDA:quadEM:'
    if (n_elements(med_fft_name) eq 0) then med_fft_name='13IDA:quadEM_FFT:'
    nmcas = 10
    casettimeout, .001
    med = obj_new('epics_med', med_name, nmcas)
    med_fft = obj_new('epics_med', med_fft_name, nmcas)
    while(1) do begin
       fft_presets = med_fft->get_presets()
       t = caget(med_fft_name + 'PresetReal', avg_time)
       fft_data_avg = 0
       n_avg = 0
       tstart = systime(1)
       while(1) do begin
          ; Start med
          med->erase
          med->acquire_on
          ; Wait for MED to complete
          med->acquire_wait, /start, /stop
          data = med->get_data()
          presets = med->get_presets()
          dwell = presets[0].dwell
          nchans_data = n_elements(data(*,1))
          nchans_fft = nchans_data/2
          fft_data = fltarr(nchans_fft, nmcas)
          for i=0, nmcas-1 do begin
             fft_data[0,i] = (abs(fft(data(*,i), -1)))[0:nchans_fft-1]
          endfor
          n_avg = n_avg + 1
          fft_data_avg = fft_data_avg + fft_data
          if ((avg_time eq 0.0) or ((systime(1) - tstart) GE avg_time)) then break
       endwhile
       fft_data_avg = fft_data_avg / n_avg
       time_axis = dwell*findgen(nchans_data)
       t = caput(med_name+'Xaxis', time_axis)
       cal = {mca_calibration}
       cal.offset=0.
       cal.slope=dwell
       med->set_calibration, cal
       freq = findgen(nchans_fft)/(nchans_fft-1)/dwell/2.
       t = caput(med_fft_name+'Xaxis', freq)
       med_fft->set_data, 1000*fft_data_avg
       cal.slope = freq[1]
       med_fft->set_calibration, cal
       t = caput(med_fft_name+'ReadAll.PROC', 1)
       if (get_kbrd(0) ne '') then break
    endwhile
end
