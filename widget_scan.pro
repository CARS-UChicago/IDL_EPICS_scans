; ************************************************************
pro widget_scan_print
    common widget_scan_print_common, print
    @scan_common
    @bsif_common

    if (n_elements(print) eq 0) then begin
        print = {   $
            xsize:         6.,   $
            ysize:         4.,   $
            orientation:    0,   $
            thick:         1.0,   $
            charthick:     1.0,   $
            charsize:      1.0,   $
            xtitle:        '',   $
            ytitle:        '',   $
            title:         '',   $
            font:           0,   $
            command:       'lpr -Pgse_floor'    $
        }
    endif

    print.title = sd.file_name
    print.xtitle = x_title

    desc = [                                                                  $
        '1, BASE,   ,COLUMN, FRAME',                                          $
        '1, BASE,   ,ROW, FRAME',                                             $
        '0, FLOAT,  '+ string(print.xsize) +                            $
                    ',TAG =xsize, LABEL_TOP =X size (inches), WIDTH=12',      $
        '0, FLOAT,  '+ string(print.ysize) +                            $
                    ',TAG =ysize, LABEL_TOP =Y size (inches), WIDTH =12',     $
        '2, BUTTON,  Portrait|Landscape, EXCLUSIVE,' +                        $
                    'LABEL_TOP =Orientation, TAG =orientation,' +             $
                    'SET_VALUE ='+string(print.orientation),            $
        '1, BASE,   ,ROW, FRAME',                                             $
        '0, FLOAT,  '+ string(print.charsize) +                         $
                    ',TAG =charsize, LABEL_TOP =Character size, WIDTH =12',   $
        '0, FLOAT,  '+ string(print.thick) +                            $ 
                    ',TAG =thick, LABEL_TOP =Line thickness , WIDTH =12',     $
        '0, FLOAT,  '+ string(print.charthick) +                        $
                    ',TAG =charthick, LABEL_TOP =Character thickness,' +      $ 
                    'WIDTH =12',                                              $
        '2, BUTTON,  Postscript|Vector, EXCLUSIVE,' +                         $
                    'LABEL_TOP =Font, TAG =font,' +                           $
                    'SET_VALUE ='+ string(print.font),                  $
        '1, BASE,   ,ROW, FRAME',                                             $
        '2, TEXT,   ' + print.xtitle +                                  $
                    ',TAG =xtitle, LABEL_LEFT =X title: , WIDTH =30',         $
        '1, BASE,   ,ROW, FRAME',                                             $
        '2, TEXT,   ' + print.ytitle +                                  $
                    ',TAG =ytitle, LABEL_LEFT =Y title: , WIDTH =30',         $
        '1, BASE,   ,ROW, FRAME',                                             $
        '2, TEXT,   ' + print.title +                                   $ 
                    ',TAG =title, LABEL_LEFT =Plot title: , WIDTH =30',       $
        '1, BASE,   ,ROW, FRAME',                                             $
        '2, TEXT,   ' + print.command +                                 $
                    ',TAG =command, LABEL_LEFT =Print command: , WIDTH =30',  $
        '1, BASE,   ,ROW, FRAME',                                             $
        '0, BUTTON,  Print, QUIT, TAG =print',                                $
        '2, BUTTON,  Cancel, QUIT, TAG =cancel']

    k = where(sd.plot gt 0, nplot)
    if (nplot eq 0) then return

    form = cw_form( /column, title='Scan Print', desc)
    if (form.cancel) then return
    old_device = !d.name
    set_plot, 'ps'
    if (form.orientation) eq 1 then landscape=1 else landscape=0
    if (form.font) eq 1 then font=-1 else font=0
    device, xsize=form.xsize, ysize=form.ysize, /inch, landscape=landscape, $
            file='idl.ps'

    big = max(image_data(*, 0, k))
    small = min(image_data(*, 0, k))
    plot, x_dist, image_data(*, 0, k(0)), psym=-1,             $
            yrange = [small - 0.2*abs(small), big + 0.2*abs(big)], $
            charsize  = form.charsize,                             $
            thick     = form.thick,                                $
            charthick = form.charthick,                            $
            xtitle    = form.xtitle,                               $
            ytitle    = form.ytitle,                               $
            title     = form.title,                                $
            font      = font
    for i=1, n_elements(k)-1 do begin
        oplot, x_dist, image_data(*, 0, k(i)), psym=-(i+1),    $
            thick     = form.thick
    endfor

    device, /close
    set_plot, old_device
    command = form.command + ' idl.ps'
    spawn, command
    print.xsize = form.xsize
    print.ysize = form.ysize
    print.orientation = form.orientation
    print.charsize = form.charsize
    print.thick = form.thick
    print.charthick = form.charthick
    print.font = form.font
    print.xtitle = form.xtitle
    print.ytitle = form.ytitle
    print.title = form.title
    print.command = form.command
end


; ************************************************************
pro set_plot_values
@scan_common

sd.plot=-1
j=0
if (sd.scan_type eq ROI_SCAN) then begin
    for i=0, sd.n_rois-1 do begin
        sd.plot[j] = sd.roi[i].plot
        j=j+1
    endfor
endif
for i=0, sd.n_scalers-1 do begin
    sd.plot[j] = sd.scalers[i].plot
    j=j+1
endfor
end

; ************************************************************
pro draw_scaler_widgets, widgets
@scan_common

widget_control, widgets.base, /hourglass
if obj_valid(sd.scaler) then begin
    titles = sd.scaler->get_title()
    for i=0, sd.n_scalers-1 do begin
        sd.scalers[i].title = titles[i]
    endfor
endif

if (widget_info(widgets.base, /realized)) then begin
    if (!version.os eq 'Win32') then begin 
        widget_control, widgets.base, map=0
    endif else begin
        widget_control, widgets.scaler_base2, update=0
    endelse
endif
widget_control, widgets.scaler_base2, /destroy
widgets.scaler_base2 = widget_base(widgets.scaler_base1, /row)
row = widgets.scaler_base2
widgets.scaler_name = cw_field(row, title='Scaler PVname', $
                        value=sd.scaler_pvname,  $
                        /return_events, /column, /string, xsize=20)
widgets.n_scalers = cw_field(row, title='# scalers', value=sd.n_scalers,  $
                        /return_events, /column, /integer, xsize=10)
col = widget_base(row, /column)
t = widget_label(col, value='Title')
for i=0, sd.n_scalers-1 do begin
  widgets.scalers[i].title = widget_text(col, /edit, $
                                value=sd.scalers[i].title, xsize=20)
endfor
c = widget_base(row, /column)
geometry = widget_info(widgets.scalers[0].title, /geometry)
ysize = geometry.scr_ysize
t = widget_label(c, value='Plot')
col = widget_base(c, /column, /nonexclusive)
for i=0, sd.n_scalers-1 do begin
    widgets.scalers[i].plot = widget_button(col, value="", ysize=ysize)
    widget_control, widgets.scalers[i].plot, set_button=sd.scalers[i].plot
endfor
set_plot_values
if (widget_info(widgets.base, /realized)) then begin
    if (!version.os eq 'Win32') then begin 
        widget_control, widgets.base, map=1
    endif else begin
        widget_control, widgets.scaler_base2, update=1
    endelse
endif
end


; ************************************************************
pro draw_roi_widgets, widgets
@scan_common

widget_control, widgets.base, /hourglass
if obj_valid(sd.mca) then begin
    roi = sd.mca->get_rois()
    sd.n_rois = n_elements(roi)
    for i=0, sd.n_rois-1 do begin
        sd.roi(i).name = roi(i).label
        sd.roi(i).bgd_width = roi(i).bgd_width
        sd.roi(i).left_chan = roi(i).left
        sd.roi(i).right_chan = roi(i).right
    endfor
endif else begin
    sd.n_rois = 0
endelse

if (widget_info(widgets.base, /realized)) then begin
    if (!version.os eq 'Win32') then begin 
        widget_control, widgets.base, map=0
    endif else begin
        widget_control, widgets.roi_base2, update=0
    endelse
endif
widget_control, widgets.roi_base2, /destroy
widgets.roi_base2 = widget_base(widgets.roi_base1, /row)
row = widgets.roi_base2
col = widget_base(row, /column)
widgets.mca_name = cw_field(col, title='MCA PVname', value=sd.mca_pvname,  $
                        /return_events, /column, /string, xsize=20)
col = widget_base(col, /column)
widgets.timing_base = col
t = widget_label(col, value='Timing mode')
widgets.timing_mode = widget_droplist(col, value=['Live', 'Real'])
widget_control, widgets.timing_mode, set_droplist_select=sd.timing_mode
col = widget_base(row, /column)
t = widget_label(col, value='Title')
for i=0, sd.n_rois-1 do begin
  widgets.rois(i).title = widget_text(col, /edit, $
                                value=sd.roi(i).name, xsize=10)
endfor
col = widget_base(row, /column)
t = widget_label(col, value='Left channel')
for i=0, sd.n_rois-1 do begin
  widgets.rois(i).left = widget_text(col, /edit, $
                                value=string(sd.roi(i).left_chan), xsize=10)
endfor
col = widget_base(row, /column)
t = widget_label(col, value='Right channel')
for i=0, sd.n_rois-1 do begin
  widgets.rois(i).right = widget_text(col, /edit, $
                                value=string(sd.roi(i).right_chan), xsize=10)
endfor
col = widget_base(row, /column)
t = widget_label(col, value='Back. width')
for i=0, sd.n_rois-1 do begin
  widgets.rois(i).bgd_width = widget_text(col, /edit, $
                                value=string(sd.roi(i).bgd_width), xsize=10)
endfor
c = widget_base(row, /column)
geometry = widget_info(widgets.scalers[0].title, /geometry)
ysize = geometry.scr_ysize
t = widget_label(c, value='Plot')
col = widget_base(c, /column, /nonexclusive)
for i=0, sd.n_rois-1 do begin
    widgets.rois[i].plot = widget_button(col, value="", ysize=ysize)
    widget_control, widgets.rois[i].plot, set_button=sd.roi[i].plot
endfor
set_plot_values
if (widget_info(widgets.base, /realized)) then begin
    if (!version.os eq 'Win32') then begin 
        widget_control, widgets.base, map=1
    endif else begin
        widget_control, widgets.roi_base2, update=1
    endelse
endif
end



; ************************************************************
pro widget_scan_sens, widgets
@scan_common

if (sd.n_dims eq 1) then sens=1 else sens=0
widget_control, widgets.n_motors_base, sensitive=sens

if (sd.scan_type eq SCALER_SCAN) then sens=0 else sens=1
widget_control, widgets.roi_base1, sensitive=sens

if (sd.n_dims eq 2) then sd.n_motors = 2
widget_control, widgets.n_motors, set_droplist_select=sd.n_motors-1

if (sd.n_motors eq 1) then sens=0 else sens=1
widget_control, widgets.mp(1).base, sensitive=sens

for i=0,1 do begin
  if obj_valid(sd.motors(i)) then sens=1 else sens=0
  widget_control, widgets.mp(i).abs_start, sensitive=sens
  widget_control, widgets.mp(i).abs_stop, sensitive=sens
  widget_control, widgets.mp(i).rel_start, sensitive=sens
  widget_control, widgets.mp(i).rel_stop, sensitive=sens
  widget_control, widgets.mp(i).step, sensitive=sens
  widget_control, widgets.mp(i).npoints, sensitive=sens
  widget_control, widgets.mp(i).position, sensitive=sens
endfor

end



; ************************************************************
pro new_scan_params, index, widgets
@scan_common

  ; This routine computes and displays scan parameters
  ; It must make sure that:
  ;   start, stop, and step are integral number of motor steps
  ;   start, stop, step, and npoints are internally consistent
  ;   scan range is within soft limits
  ; Updates estimated scan time

   if (not obj_valid(sd.motors(index))) then return
   mot = md(index)
   ; Make sure start, stop, and step are all integer # of motor steps
   scale = sd.motors(index)->get_scale()
   position = sd.motors(index)->get_position()
   mot.start[0] = round(mot.start[0]*scale) / scale
   mot.stop[0] = round(mot.stop[0]*scale) / scale
   mot.inc[0] = round(mot.inc[0]*scale) / scale
   ; Correct sign of step size if necessary
   if (mot.stop[0] gt mot.start[0]) then mot.inc[0] = abs(mot.inc[0]) $
                              else mot.inc[0] = -abs(mot.inc[0])
   sd.dims(index) = (mot.stop[0]-mot.start[0])/mot.inc[0] + 1
   widget_control, widgets.mp(index).abs_start, set_value=mot.start[0]
   widget_control, widgets.mp(index).abs_stop, set_value=mot.stop[0]
   widget_control, widgets.mp(index).rel_start, set_value=(mot.start[0]-position)
   widget_control, widgets.mp(index).rel_stop, set_value=(mot.stop[0]-position)
   widget_control, widgets.mp(index).step, set_value=mot.inc[0]
   widget_control, widgets.mp(index).npoints, set_value = sd.dims(index)
   widget_control, widgets.mp(index).position, set_value = position
   widget_control, widgets.mp(index).name, set_value=mot.name
   md(index) = mot
   ; Compute estimated scan time
   points = sd.dims(0)
   if (sd.n_dims eq 2) then points= points * sd.dims(1)
   time = sd.dwell_time * points
   widget_control, widgets.total_time, set_value=time

   ; Update scan dimensions, scan type, etc. in case we were called
   ; because of restore scan params from file
   widget_control, widgets.scan_mode, set_droplist_select=sd.scan_type
   widget_control, widgets.scan_dims, set_droplist_select=sd.n_dims-1
   widget_control, widgets.n_motors, set_droplist_select=sd.n_motors-1
   widget_control, widgets.dwell_time, set_value=sd.dwell_time

   ; Check for soft-limit violations
   high_limit = sd.motors[index]->get_high_limit()
   low_limit = sd.motors[index]->get_low_limit()
   if (mot.start[0] gt high_limit) or (mot.start[0] lt low_limit) then $
        t = dialog_message(/error, "Start position is beyond soft limits", $
        dialog_parent=widgets.base)
   if (mot.stop[0] gt high_limit) or (mot.stop[0] lt low_limit) then $
        t = dialog_message(/error, "Stop position is beyond soft limits", $
        dialog_parent=widgets.base)
end


; ************************************************************
pro widget_scan_event, event
@scan_common
@bsif_common

widget_control, event.top, get_uvalue=widgets, /no_copy

if n_elements(widgets) eq 0 then begin
    ; This is an event during a scan (when xmanager is inactive)
    ; Ignore it.
    print, 'got event, id = ', event.id
    return
endif

case event.id of
  widgets.timer: begin
    ; Read the current motor position, store it, and display it.
    for i=0,1 do begin
        if obj_valid(sd.motors(i)) then begin
            pos = sd.motors(i)->get_position()
            widget_control, widgets.mp(i).position, set_value=pos
        endif
    endfor
    widget_control, widgets.timer, timer=1.0
  end

  widgets.scan_mode: begin
    sd.scan_type = event.index
    widget_scan_sens, widgets
  end

  widgets.scan_dims: begin
    sd.n_dims = event.index + 1
    widget_scan_sens, widgets
  end

  widgets.n_motors: begin
    sd.n_motors = event.index + 1
    widget_scan_sens, widgets
  end

  widgets.dwell_time: begin
    sd.dwell_time = event.value
    new_scan_params, 0, widgets
  end

  widgets.scan_file: begin
    widget_control, event.id, get_value=scan_file
    sd.file_name = scan_file[0]
  end

  widgets.scan_title: begin
    widget_control, event.id, get_value=scan_title
    sd.title = scan_title[0]
  end

  widgets.start_scan: begin
    widget_control, widgets.start_scan, sensitive=0
    widget_control, widgets.exit, sensitive=0
    widget_control, widgets.print, sensitive=0
    set_plot_values
    catch, error
    if (error eq 0) then begin
        sd.abort_scan_widget = widgets.abort_scan
        scan
    endif else begin  ; An error occured during the scan
        t = dialog_message(/error, !ERR_STRING, dialog_parent=widgets.base)
    endelse
    widget_control, widgets.start_scan, sensitive=1
    widget_control, widgets.exit, sensitive=1
    widget_control, widgets.print, sensitive=1
    ; Update scan file name
    widget_control, widgets.scan_file, set_value=sd.file_name
  end

  widgets.print: begin
    widget_scan_print
  end

  widgets.save_params: begin
    file = dialog_pickfile( title = 'Save scan parameters')
    if (file ne "") then save, /xdr, sd, md, filename=file
  end

  widgets.read_file: begin
    file = dialog_pickfile( title = 'Read data file', /must_exist)
    if (file ne "") then begin
        read_bsif, file
        set_plot_values
        display_point, n_elements(image_data(0,*,0))-1, $
                       n_elements(image_data(*,0,0))-1, /rescale
    endif
  end
  
  widgets.replot: begin
    set_plot_values
    display_point, n_elements(image_data(0,*,0))-1, $
                   n_elements(image_data(*,0,0))-1, /rescale
  end

  widgets.restore_params: begin
    file = dialog_pickfile( title = 'Restore scan parameters', /must_exist)
    if (file ne "") then begin
        restore, file
        for i=0, 1 do new_scan_params, i, widgets
        draw_scaler_widgets, widgets
        draw_roi_widgets, widgets
        widget_scan_sens, widgets
    endif
  end

  widgets.exit: begin
    widget_control, event.top, /destroy
    return
  end

endcase

widget_control, event.top, set_uvalue=widgets, /no_copy
end


; ************************************************************
pro widget_scan_motor_event, event
@scan_common
widget_control, event.top, get_uvalue=widgets, /no_copy

    for i=0, 1 do begin
      if (event.id eq widgets.mp[i].name) then begin
        widget_control, widgets.base, /hourglass
        widget_control, event.id, get_value=motor_name
        motor_name = motor_name[0]
        m = obj_new('epics_motor', motor_name)
        if (not obj_valid(m)) then begin
            t = dialog_message(/error, 'Invalid motor name', $
                    dialog_parent=widgets.base)
            goto, done
        endif
        obj_destroy, sd.motors(i)
        sd.motors(i) = m
        md(i).name = sd.motors(i)->get_name()
        position = sd.motors(i)->get_position()
        ; Use the same values of relative start and stop positions and step
        widget_control, widgets.mp(i).rel_start, get_value=rel_start
        widget_control, widgets.mp(i).rel_stop, get_value=rel_stop
        md(i).start[0] = position + rel_start
        md(i).stop[0] = position + rel_stop
        widget_control, event.id, set_value=md(i).name
        widget_scan_sens, widgets
        new_scan_params, i, widgets
      endif else if (event.id eq widgets.mp(i).abs_start) then begin
         md(i).start[0] = event.value
         new_scan_params, i, widgets
      endif else if (event.id eq widgets.mp(i).abs_stop) then begin
         md(i).stop[0] = event.value
         new_scan_params, i, widgets
      endif else if (event.id eq widgets.mp(i).rel_start) then begin
         position = sd.motors(i)->get_position()
         md(i).start[0] = position + event.value
         new_scan_params, i, widgets
      endif else if (event.id eq widgets.mp(i).rel_stop) then begin
         position = sd.motors(i)->get_position()
         md(i).stop[0] = position + event.value
         new_scan_params, i, widgets
      endif else if (event.id eq widgets.mp(i).step) then begin
         md(i).inc[0] = event.value
         new_scan_params, i, widgets
      endif
    endfor

done:
widget_control, event.top, set_uvalue=widgets, /no_copy
end


; ************************************************************
pro widget_scan_scaler_event, event
@scan_common
widget_control, event.top, get_uvalue=widgets, /no_copy

case event.id of
  widgets.scaler_name: begin
    widget_control, widgets.base, /hourglass
    widget_control, event.id, get_value=scaler_name
    scaler_name = scaler_name[0]
    scaler = obj_new('epics_scaler', scaler_name)
    if obj_valid(scaler) then begin
        obj_destroy, sd.scaler
        sd.scaler = scaler
        sd.scaler_pvname = scaler_name
        draw_scaler_widgets, widgets
    endif else begin
        t = dialog_message(/error, 'Scaler not found', $
                            dialog_parent=widgets.base)
    endelse
  end


  widgets.n_scalers: begin
    widget_control, event.id, get_value=n_scalers
    sd.n_scalers = n_scalers > 1
    draw_scaler_widgets, widgets
  end

  else: begin
    for i=0, sd.n_scalers-1 do begin
      if (event.id eq widgets.scalers[i].title) then begin
        widget_control, event.id, get_value=title
        title = title[0]
        sd.scalers[i].title = title
        sd.scaler->set_title, i, title
      endif else if (event.id eq widgets.scalers[i].plot) then begin
        sd.scalers[i].plot = event.select
        set_plot_values
      endif
    endfor
  end
endcase

widget_control, event.top, set_uvalue=widgets, /no_copy
end


; ************************************************************
pro widget_scan_roi_event, event
@scan_common
widget_control, event.top, get_uvalue=widgets, /no_copy

case event.id of
  widgets.timing_mode: begin
    sd.timing_mode = event.index  ; This assumes index=0 is mode=0
    widget_scan_sens, widgets
  end

  widgets.mca_name: begin
    widget_control, widgets.base, /hourglass
    widget_control, event.id, get_value=mca_name
    mca_name = mca_name[0]
    m = obj_new('epics_mca', mca_name)
    if obj_valid(m) then begin
        obj_destroy, sd.mca
        sd.mca = m
        sd.mca_pvname = mca_name
        draw_roi_widgets, widgets
    endif else begin
        t = dialog_message(/error, 'MCA not found', dialog_parent=widgets.base)
    endelse
  end

  else: begin
    for i=0, sd.n_rois-1 do begin
      if (event.id eq widgets.rois(i).title) then begin
        widget_control, event.id, get_value=title
        title = title[0]
        rois = sd.mca->get_rois()
        rois[i].label = title
        sd.mca->set_rois, rois
      endif else if (event.id eq widgets.rois(i).left) then begin
        widget_control, event.id, get_value=left
        left = long(left[0])
        rois = sd.mca->get_rois()
        rois[i].left = left
        sd.mca->set_rois, rois
      endif else if (event.id eq widgets.rois(i).right) then begin
        widget_control, event.id, get_value=right
        right = long(right[0])
        rois = sd.mca->get_rois()
        rois[i].right = right
        sd.mca->set_rois, rois
      endif else if (event.id eq widgets.rois(i).bgd_width) then begin
        widget_control, event.id, get_value=bgd_width
        bgd_width = long(bgd_width[0])
        rois = sd.mca->get_rois()
        rois[i].bgd_width = bgd_width
        sd.mca->set_rois, rois
      endif else if (event.id eq widgets.rois[i].plot) then begin
        sd.roi[i].plot = event.select
        set_plot_values
      endif

    endfor
  end
endcase

widget_control, event.top, set_uvalue=widgets, /no_copy
end




; ************************************************************
pro widget_scan, group=group
@scan_common
init_scan_sd

; Resolve object routines, since restore scan params might happen first
resolve_routine, 'epics_motor__define'
resolve_routine, 'epics_scaler__define'
resolve_routine, 'epics_mca__define'
resolve_routine, 'mca__define'

mp = {base: 0L, name: 0L, $
      abs_start: 0L, abs_stop: 0L, rel_start: 0L, rel_stop: 0L, $
      step: 0L, npoints: 0L, position: 0L}
rois = {title: 0L, left: 0L, right:0L, bgd_width: 0L, plot: 0L}
scalers = {title: 0L, plot: 0L}
widgets = { base:       0L, $
            scan_mode:  0L, $
            scan_dims:  0L, $
            n_motors_base: 0L, $
            n_motors:   0L, $
            mp:         replicate(mp, 2), $
            n_scalers:   0L, $
            scaler_base1: 0L, $
            scaler_base2: 0L, $
            scaler_name:  0L, $
            scalers:  replicate(scalers, MAX_SCALERS), $
            mca_name:    0L, $
            roi_base1:   0L, $
            roi_base2:   0L, $
            rois:     replicate(rois, MAX_ROIS), $
            timing_base: 0L, $
            timing_mode: 0L, $
            dwell_time:  0L, $
            total_time:  0L, $
            timer:       0L, $
            start_scan: 0L, $
            abort_scan: 0L, $
            replot:     0L, $
            print:      0L, $
            save_params: 0L, $
            restore_params: 0L, $
            read_file:  0L, $
            scan_title: 0L, $
            scan_file:  0L, $
            exit:        0L }

default_font = get_font_name(/small)
label_font = get_font_name(/bold)
widgets.base = widget_base(title="Scan Setup", /column, mbar=mbar)
widget_control, widgets.base, default_font=default_font
widgets.timer = widgets.base

file = widget_button( mbar, /menu, value = 'File      ', font=label_font)
widgets.print = widget_button( file, value = 'Print . . .')
widgets.save_params = widget_button( file, $
                                 value = 'Save scan parameters. . .')
widgets.restore_params = widget_button( file, $
                                 value = 'Restore scan parameters. . .')
widgets.read_file = widget_button( file, $
                                 value = 'Read data file. . .')
widgets.exit = widget_button( file, value = 'Exit')



row = widget_base(widgets.base, /row, /frame)
col = widget_base(row, /column)
t = widget_label(col, value='Scan type')
widgets.scan_mode = widget_droplist(col, $
                        value= ['Scaler', 'ROI', 'Spectrum', 'MCS'])
widget_control, widgets.scan_mode, set_droplist_select=sd.scan_type

col = widget_base(row, /column)
t = widget_label(col, value='Scan dims.')
widgets.scan_dims = widget_droplist(col, value=['1-D', '2-D'])
widget_control, widgets.scan_dims, set_droplist_select=sd.n_dims-1

col = widget_base(row, /column)
widgets.n_motors_base = col
t = widget_label(col, value='# motors')
widgets.n_motors = widget_droplist(col, value=['1', '2'])

col = widget_base(row, /column)
widgets.dwell_time = cw_field(row, title='Count time (sec)', /return_events, $
                        value=sd.dwell_time, /column, /float, xsize=10)
widgets.total_time = cw_field(row, title='Total time (sec)', /noedit, $
                        value=0.0, /column, /float, xsize=10)

r = widget_base(widgets.base, /row, event_pro='widget_scan_motor_event')
for i=0, 1 do begin
  col = widget_base(r, /column, /frame)
  widgets.mp(i).base = col
  t = widget_label(col, value='Motor '+strtrim(i+1,2), font=label_font)
  row = widget_base(col, /row)
  widgets.mp(i).name = cw_field(row, title='Motor name', value=md(i).name, $
                        /return_events, /column, /string, xsize=20)
  width=10
  widgets.mp(i).position = cw_field(row, title='Current position', value=0.0, $
                        /return_events, /column, /float, xsize=width)
  row = widget_base(col, /row)
  widgets.mp(i).abs_start = cw_field(row, title='Start (abs)', $
                        value=md(i).start[0], $
                        /return_events, /column, /float, xsize=width)
  widgets.mp(i).abs_stop = cw_field(row, title='Stop (abs)', $
                        value=md(i).stop[0],  $
                        /return_events, /column, /float, xsize=width)
  widgets.mp(i).step = cw_field(row, title='Step', value=md[i].inc[0],  $
                        /return_events, /column, /float, xsize=width)
  row = widget_base(col, /row)
  widgets.mp(i).rel_start = cw_field(row, title='Start (rel)', value=-1.0, $
                        /return_events, /column, /float, xsize=width)
  widgets.mp(i).rel_stop = cw_field(row, title='Stop (rel)', value=1.0,  $
                        /return_events, /column, /float, xsize=width)
  widgets.mp(i).npoints = cw_field(row, title='# points', value=0,  $
                        /noedit, /column, /integer, xsize=width)
endfor

widgets.scaler_base1 = widget_base(widgets.base, /column, /frame, $
                            event_pro='widget_scan_scaler_event')
t = widget_label(widgets.scaler_base1, value='Scalers', font=label_font)
widgets.scaler_base2 = widget_base(widgets.scaler_base1, /row, /frame)
draw_scaler_widgets, widgets

widgets.roi_base1 = widget_base(widgets.base, /column, /frame, $
                            event_pro='widget_scan_roi_event')
t = widget_label(widgets.roi_base1, value='Regions of Interest', $
                            font=label_font)
widgets.roi_base2 = widget_base(widgets.roi_base1, /row, /frame)
draw_roi_widgets, widgets

row = widget_base(widgets.base, /row, /frame)
col = widget_base(row, /column)
t = widget_label(col, value='Scan file name')
widgets.scan_file = widget_text(col, value=sd.file_name, /edit, $
                        xsize=20)
col = widget_base(row, /column)
t = widget_label(col, value='Scan title')
widgets.scan_title = widget_text(col, value=sd.title, /edit, $
                        xsize=60)

row = widget_base(widgets.base, /row)
widgets.start_scan = widget_button(row, value='Start scan', font=label_font)
widgets.abort_scan = widget_button(row, value='Abort scan', font=label_font, $
                                event_pro = 'abort_scan')
widgets.replot = widget_button(row, value='Replot', font=label_font)

for i=0, 1 do new_scan_params, i, widgets

widget_scan_sens, widgets
widget_control, widgets.base, set_uvalue=widgets
widget_control, widgets.base, /realize
widget_control, widgets.timer, timer=1.0
xmanager, 'widget_scan', widgets.base, group_leader=group, /no_block

end
