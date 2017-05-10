function caput_charwaveform, pvname, value, wait=wait
;
; caput a string to a character waveform
;
    nchar = strlen(value)
    out = bytarr(nchar+1)
    out[0:nchar-1] = byte(value)
    out = caput(pvname, out, wait=wait)

return, out
end

pro save_microscope_image, fname, prefix=prefix, path=path
; save image from AreaDetector FileSaving plugin

    adcam = '13IDEPS1:JPEG1:'
    if keyword_set(prefix) then adcam = prefix
    if keyword_set(path) then begin
       x = caput_charwaveform(adcam+'FilePath', path, wait=1) 
    endif
    fname_pv = adcam + 'FileName'
    save_pv = adcam + 'WriteFile'

    x = caput_charwaveform(adcam+'FileName', fname, wait=1)
    x = caput(adcam + 'WriteFile', 1, wait=1)

return
end
