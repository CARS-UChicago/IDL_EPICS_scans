dest = '/millenia/www/htdocs/software/idl/'
mk_html_help, 'epics_motor__define.pro', dest+'epics_motor_class.html', $
        title = 'EPICS Motor Class'
mk_html_help, 'epics_scaler__define.pro', dest+'epics_scaler_class.html', $
        title = 'EPICS Scaler Class'
mk_html_help, /strict, ['epics_sscan__define.pro', 'read_mda.pro', 'display_mda.pro'], $
        dest+'epics_sscan_class.html', title='EPICS_SSCAN Class Reference'
end
