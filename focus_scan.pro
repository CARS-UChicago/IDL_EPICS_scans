pro focus_scan

; This routine adjusts the forces on the mirrors to 

; and find the optimum
; focus on a 2-D grid

; This program moves a motor back and forth, usually over an edge, and
; collects MCS data on the counts.  It displays the derivative of the
; counts in another window.

; It assumes that the user has set ROI around the position of the edge

@bsif_common

    f1_motor_name = ' '
    f2_motor_name = ' '
    edge_motor_name = '13IDC:Stage_X'
    mcs_pv = '13IDC:aim_mcs1'

    print, '$Focus scan program'

    edge_motor_name = get_string('PV name of motor for edge scan:', $
                                 edge_motor_name)
    edge_motor = obj_new('epics_motor', edge_motor_name)
    pos = edge_motor->get_position()
    print, 'Curent position = ', pos
    edge_start = get_float('Start position for edge motor', pos)
    edge_stop  = get_float('Stop position for edge motor', pos+.1)
    scan_speed = get_float('Scan speed for edge motor', .1)
    flyback_speed = edge_motor->get_slew_speed()
    flyback_speed = get_float('Flyback speed for edge motor', flyback_speed)
    dwell_time = get_float('Dwell time of MCS (sec):', .01)
    edge_step = 1000.* scan_speed * dwell_time  ; Step size in microns

    f1_motor_name = get_string('PV name of F1 motor', f1_motor_name)
    f1_motor = obj_new('epics_motor', f1_motor_name)
    pos = f1_motor->get_position()
    print, 'Curent position = ', pos
    f1_start = get_float('Start position for F1 motor', pos)
    f1_stop  = get_float('Stop position for F1 motor', pos+100.)
    f1_step  = get_float('Step size for F1 motor', 10.)

    f2_motor_name = get_string('PV name of F2 motor', f2_motor_name)
    f2_motor = obj_new('epics_motor', f2_motor_name)
    pos = f2_motor->get_position()
    print, 'Curent position = ', pos
    f2_start = get_float('Start position for F2 motor', pos)
    f2_stop  = get_float('Stop position for F2 motor', pos+100.)
    f2_step  = get_float('Step size for F2 motor', 10.)

    filename = get_string('Enter filename to save data', 'focus.001')

    nx = (f1_stop-f1_start)/f1_step + 1
    ny = (f2_stop-f2_start)/f2_step + 1
    image_data = fltarr(nx, ny, 2)

    mcs_pv = get_string('PV name of MCS:', mcs_pv)
    mcs = obj_new('epics_mca', mcs_pv)
    ; Do an edge scan so user can set ROI
    ; Set speed of drive
    edge_motor->set_slew_speed, flyback_speed
    ; Drive to low position
    edge_motor->move, edge_start
    edge_motor->wait
    mcs->erase
    mcs->acquire_on
    edge_motor->set_slew_speed, scan_speed
    edge_motor->move, edge_stop
    edge_motor->wait
    mcs->acquire_off

    reply = get_string('Define an ROI around the edge, hit Return when ready', '')

    roi = mcs->get_rois()
    low_chan = roi[0].left
    high_chan = roi[0].right
    if (low_chan le 0 or high_chan le 0) then message, $
      'You must define ROI 0 around the edge position to use this routine'
    npoints = high_chan - low_chan + 1

    f1_pos = f1_start
    for ix=0, nx-1 do begin
	 f2_pos = f2_start
	 f1_motor->move, f1_pos
         f1_motor->wait
	 for iy=0, ny-1 do begin
	    f2_motor->move, f2_pos
            f2_motor->wait
	    ; Set speed of drive
            edge_motor->set_slew_speed, flyback_speed
	    ; Drive to low position
	    edge_motor->move, edge_start
            edge_motor->wait
            mcs->erase
            edge_motor->set_slew_speed, scan_speed
            mcs->acquire_on
            edge_motor->move, edge_stop
            edge_motor->wait
            mcs->acquire_off
            data = mcs->get_data()
            ; Limit data to that in the ROI
            data = data(low_chan:high_chan)
	    ; Compute the derivative
            deriv = float(data - shift(data, 1))
            ; Throw out first and last point
            deriv = deriv(1:npoints-2)
            ; Flip sign if the scan started in air
            np = n_elements(deriv)
            if (data(0) gt data(np-1)) then deriv = -deriv
	    ; Display the derivative
            plot, deriv
            ; Compute array of motor positions with arbitrary origin
            x = findgen(np) * edge_step
            sm = smooth(deriv, 3)
            max = max(sm, max_index)
            thresh = .05 * max
            left = max_index
            while ((left gt 1) and (sm(left) gt thresh)) $
                do left = left-1
            right = max_index
            while ((right lt np-1) and (sm(right) gt thresh)) $
                do right = right+1
            good = left + indgen(right-left+1)
	    ;Compute FWHM
            norm = total(deriv(good)) > 1.
            m1 = total(deriv(good) * x(good)) / norm
            m2 = total(deriv(good) * (x(good)-m1)^2) / norm
            fwhm = 2.*sqrt(2.*alog(2.)) * sqrt(m2)
            image_data(ix, iy, 0) = fwhm
            image_data(ix, iy, 1) = m1
            oplot, x(good), deriv(good), psym=1
;
	    print, 'point [', strtrim(string(ix),2), ', ', $
              strtrim(string(iy),2),      '] of [', $
              strtrim(string(fix(nx)),2), ',', $
              strtrim(string(fix(ny)),2), ']'
	    print, format='(4f12.3)', $
                        f1_pos, f2_pos, m1, fwhm
	    f2_pos = f2_pos + f2_step
        endfor
        f1_pos = f1_pos + f1_step
    endfor

    ; Define BSIF variables
    x_start = f1_start
    x_stop  = f1_stop
    x_dist  = f1_start + findgen(nx)*f1_step
    x_title = 'F1 (' + f1_motor_name + ')'
    x_normal = 1
    y_start = f2_start
    y_stop  = f2_stop
    y_dist  = f2_start + findgen(ny)*f2_step
    y_title = 'F2 (' + f2_motor_name + ')'
    y_normal = 1
    rotated  = 0
    data_title = ['FWHM', 'Centroid']
    image_title = 'Focus scan using ' + edge_motor_name
    write_bsif, filename

    ; Move motors back
    edge_motor->move, edge_start
    f1_motor->move, f1_start
    f2_motor->move, f2_start
    edge_motor->set_slew_speed, flyback_speed
end

