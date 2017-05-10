function get_string, prompt, value
    print, prompt+' ['+value+']', format="(a,$)"
    string = ''
    read, format='(q,a)', nc, string
    if nc gt 0 then return, string else return, value
end

function get_choice, prompt, choices, current
    print, prompt+' ['+choices(current)+']', format="(a,$)"
    string = ' '
    read, format='(q,a)', nc, string
end

pro test_crash
    sd =  {sd, scan_type: 0, title: " " }
    scan_types    = ['A','B']
    sd.title = get_string('Scan title', sd.title)
    sd.scan_type = get_choice('Scan type (Scaler, ROI, Spectrum, MCS)', $
                               scan_types, sd.scan_type)
end
