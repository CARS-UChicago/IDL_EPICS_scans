pro focus_scan_diag

; make 2-D grid of mirror forces to see focal spot.
;
; focus on a 2-D grid

; This program moves a motor back and forth, usually over an edge, and
; collects MCS data on the counts.  It displays the derivative of the
; counts in another window.

; It assumes that the user has set ROI around the position of the edge

@bsif_common
@focus_scan_common.pro


print, '>> Focus scan program <<'
;
; initialize common block on first entrance
if (n_elements(sum_step) eq 0) then begin
    print,  ' setting initial values'
    f1_motor_name  = '13IDC:HforceU'
    f2_motor_name  = '13IDC:HforceD'
    edge_motor_name= '13IDC:Stage_X'
    mcs_pv         = '13IDC:aim_mcs1'
    dwell_time     =  0.1
    sum_start      =  400.
    sum_stop       =  500.
    sum_step       =   10.
    diff_start     = -50.
    diff_stop      =  50.
    diff_step      =   10.
    filename       =  'focus.001'
endif

;
; calculate real starting values for f1 and f2

;
; get motor names
edge_motor_name = get_string('PV name of motor for edge scan:', $
                             edge_motor_name)
edge_motor = obj_new('epics_motor', edge_motor_name)
pos = edge_motor->get_position()
print, 'Current position = ', pos
edge_start = get_float('Start position for edge motor', pos)
edge_stop  = get_float('Stop position for edge motor', pos+.1)
scan_speed = get_float('Scan speed for edge motor', .1)
flyback_speed = edge_motor->get_slew_speed()
flyback_speed = get_float('Flyback speed for edge motor', flyback_speed)
dwell_time = get_float('Dwell time of MCS (sec):', dwell_time)
edge_step = 1000.* scan_speed * dwell_time ; Step size in microns

f1_motor_name = get_string('PV name of F1 motor', f1_motor_name)
f1_motor = obj_new('epics_motor', f1_motor_name)
f2_motor_name = get_string('PV name of F2 motor', f2_motor_name)
f2_motor = obj_new('epics_motor', f2_motor_name)
f1_pos = f1_motor->get_position()
f2_pos = f2_motor->get_position()
print, 'Current positions of F1 and F2 = ', f1_pos, f2_pos


sum_start  = get_float('Start position for Sum  ', sum_start)
sum_stop   = get_float('Stop position for Sum   ', sum_stop)
sum_step   = get_float('Step size  for Sum      ', sum_step)
diff_start = get_float('Start position for Diff ', diff_start)
diff_stop  = get_float('Stop position for Diff  ', diff_stop)
diff_step  = get_float('Step size for Diff      ', diff_step)

;sum_start  = ave_start * 2.
;sum_stop   = ave_stop  * 2.
;sum_step   = ave_step
;diff_start = diff_start * 2.
;diff_stop  = diff_stop  * 2.
f1_start = (sum_start  + diff_start )
f2_start = (sum_start  - diff_start )

; calculate number of scan points and create the image_data array
n_sum  = (abs(sum_start  - sum_stop )/ sum_step )   + 1
n_diff = (abs(diff_start - diff_stop )/ diff_step ) + 1
print,' allocating ', n_sum, n_diff, ' for image_data '
image_data = fltarr(n_sum, n_diff, 2)

filename = get_string('Enter filename to save data', filename)

mcs_pv = get_string('PV name of MCS:', mcs_pv)
mcs = obj_new('epics_mca', mcs_pv)

;
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

magic = 2.*sqrt(2.*alog(2.))
; increment over diff and ave
for isum=0, n_sum-1  do begin
    sum  = sum_start + isum * sum_step
    for idiff=0, n_diff-1 do begin
        diff = diff_start + idiff * diff_step
        f1_pos = (sum  - diff ) /2.
        f2_pos = (sum  + diff ) /2.
        print,  'moving to -> ' , sum, diff, f1_pos, f2_pos
        f1_motor->move, f1_pos
        f1_motor->wait
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
       norm =       total(deriv(good)) > 1.
       m1   =       total(deriv(good) * x(good)) / norm
       m2   = sqrt( total(deriv(good) * (x(good)-m1)^2) / norm )
       fwhm = magic *  m2 
       image_data(isum, idiff, 0) = fwhm
       image_data(isum, idiff, 1) = m1
       oplot, x(good), deriv(good), psym=1

;	    print, format='(f9.4,f9.4,f12.4,f12.4 )',  sum, diff,  m1, fwhm
       print, 'point [', strtrim(string(isum),2), ', ', $
         strtrim(string(idiff),2),      '] of [', $
         strtrim(string(fix(n_sum)),2), ',', $
         strtrim(string(fix(n_diff)),2), ']', sum, diff, f1_pos, f2_pos, m1, fwhm
; See if the user has typed ^P on the keyboard. If so, pause. Empty typeahead
; buffer checking each character for ^P.
        c = get_kbrd(0)
        if (c eq string(16B)) then begin
            print, "Scanning interrupted by keyboard input"
            print, " To plot data:"
            print, "    PLOT, IMAGE_DATA()"
            print, " To look at numbers:"
            print, "    PRINT, IMAGE_DATA()"
            print, " To abort scan:"
            print, "    ABORT_SCAN"
            print, "    .CON"
            print, " To continue scan"
            print, "    .CON "
            stop
        endif
    endfor
endfor

; exit for control-p mechanism
done_scan:

; Define BSIF variables
x_start = sum_start
x_stop  = sum_stop
x_dist  = sum_start + findgen(n_sum)*sum_step
x_title = 'Sum : (' + f1_motor_name + ' + ' + f2_motor_name+ ') / 2'
x_normal = 1
y_start = diff_start
y_stop  = diff_stop
y_dist  = diff_start + findgen(n_diff)*diff_step
y_title = 'Diff: (' + f2_motor_name + ' - ' + f1_motor_name+ ')'
y_normal = 1
rotated  = 0
data_title = ['FWHM', 'Centroid']
image_title = 'Focus scan using ' + edge_motor_name
write_bsif, filename

;
; Move motors back
    edge_motor->move, edge_start
    f1_motor->move, f1_start
    f2_motor->move, f2_start
    edge_motor->set_slew_speed, flyback_speed
end

