pro realtime_mca_fft, freq, power_spectrum, dwell=dwell, mca=mca, avg_weight=avg_weight,time = time, _extra=extra
    if (n_elements(mca) eq 0) then mca='13IDA:quadEM:mca1'
    m = obj_new('epics_mca', mca)
    if (n_elements(dwell) eq 0) then dwell = .001
    if (n_elements(avg_weight) eq 0) then avg_weight = .9
    if (n_elements(time) eq 0) then time = 1e6
    presets = m->get_presets()
    presets.dwell = dwell
    m->set_presets, presets
    p_avg = 0
    tstart = systime(1)
    while(1) do begin
       m-> erase
       m-> acquire_on
       m-> acquire_wait, /start, /stop
       data = m-> get_data()
       presets = m->get_presets()
       dwell = presets.dwell
       nchans = n_elements(data)/2
       p = abs(fft(data, -1))
       p = p[0:nchans-1]
       p_avg = (avg_weight)*(p_avg) + (1-avg_weight)*(p)
       freq = findgen(nchans)/(nchans-1)/dwell/2.
       plot, freq, /ylog, p_avg, xtitle='Hz', ytitle=mca, _extra=extra
       if (get_kbrd(0) ne '') then break
       if ((systime(1) - tstart) GT time) then break
    endwhile
    iplot, freq, p_avg, /y_log, xtitle='Hz', ytitle=mca, _extra=extra
    power_spectrum = p_avg
end
