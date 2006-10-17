pro epics_sscan_display::read_scan_file, file
   widget_control, /hourglass
   ptr_free, self.pscan
   widget_control, self.widgets.status, set_value='Reading scan file ...'
   scan = read_mda(file)
   self.pscan = ptr_new(scan, /no_copy)
   fileHeader = *self.pscan->getFileHeader()
   widget_control, self.widgets.filename, set_value=fileHeader.fileName
   widget_control, self.widgets.version, set_value=fileHeader.version
   widget_control, self.widgets.dimensions, $
                   set_value=*self.pscan->formatDimensions(*fileHeader.pDims)

   ; Pick out the file number from the file name
   stop = strpos(file, '.mda') - 1
   start = stop - 3
   if ((start ge 0) and (stop ge 0)) then begin
      str = strmid(file, start, stop-start+1)
      num = long(str)
      self.previous_file = strmid(file, 0, start) + string(num-1, format='(i4.4)') + strmid(file, stop+1, 1000)
      self.next_file = strmid(file, 0, start) + string(num+1, format='(i4.4)') + strmid(file, stop+1, 1000)
      exists = file_test(self.previous_file)
      widget_control, self.widgets.previous_scan_file, sensitive=exists
      exists = file_test(self.next_file)
      widget_control, self.widgets.next_scan_file, sensitive=exists
   endif else begin
      widget_control, self.widgets.previous_scan_file, sensitive=0
      widget_control, self.widgets.next_scan_file, sensitive=0
   endelse


   ; Construct the widgets for the scans
   widget_control, self.widgets.status, set_value='Updating widgets ...'
   widget_control, /hourglass
   valid = widget_info(self.widgets.scan_base_top, /valid)
   if (valid) then begin
       g = widget_info(self.widgets.scan_base_top, /geometry)
       xoffset = g.xoffset
       yoffset = g.yoffset
       widget_control, self.widgets.scan_base_top, /destroy
   endif else begin
       xoffset = 520
       yoffset = 20
   endelse
   self.widgets.scan_base_top = widget_base(column=1, xoffset=xoffset, yoffset=yoffset, $
                                   group_leader = self.widgets.base, $
                                   title='EPICS sscan Scans (' + fileHeader.filename + ')')
   widget_control, self.widgets.scan_base_top, set_uvalue=self
   self.widgets.scan_base = widget_tab(self.widgets.scan_base_top)
   for i=0, fileHeader.rank-1 do begin
       sh = (*fileHeader.pScanHeader)[i]
       col = widget_base(self.widgets.scan_base, /column, $
                         title=sh.name, frame=0)
       row = widget_base(col, /row, /align_center)
       self.widgets.scans[i].display = widget_button(row, value='Display with iTools', font=self.fonts.heading2)
       self.widgets.scans[i].print = widget_button(row, value='Display in column format', font=self.fonts.heading2)
       row = widget_base(col, /row)
       t = widget_label(row, value='# Points: ' + strtrim(sh.npts,2))
       self.widgets.scans[i].base = col
       stab = widget_tab(col)
       col = widget_base(stab, /column, title='Positioners', frame=0)
       if (sh.numPositioners gt 0) then begin
           row = widget_base(col, /row)
           select_widget = widget_label(row, value='Select', /align_center)
           name_widget = widget_label(row, value='Name', /align_center)
           units_widget = widget_label(row, value='Units', /align_center)
           description_widget = widget_label(row, value='Description', /align_center)
           min_widget = widget_label(row, value='Minimum', /align_center)
           max_widget = widget_label(row, value='Maximum', /align_center)

           ; Select the first positioner if no positioner is selected
           if (max(self.scan_settings[i].pos_select[0:sh.numPositioners-1]) eq 0) then self.scan_settings[i].pos_select[0] = 1
           for j=0, sh.numPositioners-1 do begin
               row = widget_base(col, /row)
               p = (*sh.pPositioners)[j]
               data = *p.pData
               minimum = min(data, max=maximum)
               button_base = widget_base(row, /nonexclusive)
               self.widgets.scans[i].positioners[j].select = widget_button(button_base, value='')
               widget_control, self.widgets.scans[i].positioners[j].select, $
                               set_button=self.scan_settings[i].pos_select[j]
               self.widgets.scans[i].positioners[j].name = widget_text(row, xsize=20, value=p.name)
               self.widgets.scans[i].positioners[j].units = widget_text(row, xsize=6, value=p.units)
               self.widgets.scans[i].positioners[j].description = widget_text(row, xsize=30, $
                                                    value=p.description)
               self.widgets.scans[i].positioners[j].min = widget_text(row, xsize=10, value=strtrim(minimum,2))
               self.widgets.scans[i].positioners[j].max = widget_text(row, xsize=10, value=strtrim(maximum,2))
           endfor
           ; Make the label widgets the size as the text widgets
           g = widget_info(button_base, /geometry)
           widget_control, select_widget, xsize=g.scr_xsize
           g = widget_info(self.widgets.scans[i].positioners[0].name, /geometry)
           widget_control, name_widget, xsize=g.scr_xsize
           g = widget_info(self.widgets.scans[i].positioners[0].units, /geometry)
           widget_control, units_widget, xsize=g.scr_xsize
           g = widget_info(self.widgets.scans[i].positioners[0].description, /geometry)
           widget_control, description_widget, xsize=g.scr_xsize
           g = widget_info(self.widgets.scans[i].positioners[0].min, /geometry)
           widget_control, min_widget, xsize=g.scr_xsize
           g = widget_info(self.widgets.scans[i].positioners[0].max, /geometry)
           widget_control, max_widget, xsize=g.scr_xsize
       endif else begin
           row = widget_base(col, /row)
           t = widget_label(row, value='No positioners for this scan.')
       endelse

       col = widget_base(stab, /column, title='Detectors', frame=0)
       if (sh.numDetectors gt 0) then begin
           row = widget_base(col, /row, /align_center)
           t = widget_label(row, value='Detectors', $
                            font=self.fonts.heading2)

           MAX_DETECTORS_PER_TAB = 10
           det_base = widget_tab(col)
           ; Select the first detector if no detector is selected
           if (max(self.scan_settings[i].det_select[0:sh.numDetectors-1]) eq 0) then self.scan_settings[i].det_select[0] = 1
           for j=0, sh.numDetectors-1 do begin
               if (j mod MAX_DETECTORS_PER_TAB eq 0) then begin
                   tab = widget_base(det_base, /column, frame=0, $
                                     title='Det. '+ strtrim(j+1,2) + '-' + $
                                                    strtrim(j+MAX_DETECTORS_PER_TAB,2))
                   row = widget_base(tab, /row)
                   select_widget = widget_label(row, value='Select', /align_center)
                   name_widget = widget_label(row, value='Name', /align_center)
                   units_widget = widget_label(row, value='Units', /align_center)
                   description_widget = widget_label(row, value='Description', /align_center)
                   min_widget = widget_label(row, value='Minimum', /align_center)
                   max_widget = widget_label(row, value='Maximum', /align_center)
                   g = widget_info(select_widget, /geometry)
                   select_size = g.scr_xsize
               endif
               row = widget_base(tab, /row)
               d = (*sh.pDetectors)[j]
               data = *d.pData
               minimum = min(data, max=maximum)
               button_base = widget_base(row, /nonexclusive, frame=0, xsize=select_size)
               self.widgets.scans[i].detectors[j].select = widget_button(button_base, value='')
               widget_control, self.widgets.scans[i].detectors[j].select, $
                               set_button=self.scan_settings[i].det_select[j]
               self.widgets.scans[i].detectors[j].name = widget_text(row,  xsize=20, value=d.name)
               self.widgets.scans[i].detectors[j].units = widget_text(row, xsize=6, value=d.units)
               self.widgets.scans[i].detectors[j].description = widget_text(row, xsize=30, value=d.description)
               self.widgets.scans[i].detectors[j].min = widget_text(row, xsize=10, value=strtrim(minimum,2))
               self.widgets.scans[i].detectors[j].max = widget_text(row, xsize=10, value=strtrim(maximum,2))
               if (j mod MAX_DETECTORS_PER_TAB eq 0) then begin
                   ; Make the label widgets the size as the text widgets
                   ; Note that the select button is different, we assume that the
                   ; check box width is less than the widget_label for Select, so we have
                   ; set the check box size above
                   g = widget_info(self.widgets.scans[i].detectors[0].name, /geometry)
                   widget_control, name_widget, xsize=g.scr_xsize
                   g = widget_info(self.widgets.scans[i].detectors[0].units, /geometry)
                   widget_control, units_widget, xsize=g.scr_xsize
                   g = widget_info(self.widgets.scans[i].detectors[0].description, /geometry)
                   widget_control, description_widget, xsize=g.scr_xsize
                   g = widget_info(self.widgets.scans[i].detectors[0].min, /geometry)
                   widget_control, min_widget, xsize=g.scr_xsize
                   g = widget_info(self.widgets.scans[i].detectors[0].max, /geometry)
                   widget_control, max_widget, xsize=g.scr_xsize
               endif
           endfor
           data = *d.pData
           dims = size(data, /dimensions)
           self.scan_settings[i].dimensions = dims
           self.scan_settings[i].rank = n_elements(dims)
           self.scan_settings[i].dimensions_string = *self.pscan->formatDimensions(dims)
           row = widget_base(col, /row)
           t = widget_label(row, value='Dimensions: ' + self.scan_settings[i].dimensions_string)
           row = widget_base(col, /row)
           self.widgets.scans[i].select_all_detectors = widget_button(row, value='Select all')
           self.widgets.scans[i].deselect_all_detectors = widget_button(row, value='Deselect all')

           col = widget_base(stab, /column, title='Display range', frame=0)
           row = widget_base(col, /row)
           t = widget_label(row, value='Dimensions: ' + self.scan_settings[i].dimensions_string)
           for j=0, n_elements(dims)-1 do begin
               row = widget_base(col, /row, /align_center)
               t = widget_label(row, value='Dimension ' + strtrim(j+1,2), font=self.fonts.heading2)
               row = widget_base(col, /row, /base_align_center)
               ; We don't currently set the dimension limits to the previous scan, because they may be unrelated
               ; scans.  We could test to see if all of the dimensions are the same and set to the same values
               ; if they are.
               self.widgets.scans[i].dims[j].start = cw_fslider(row, /edit, $
                                                          title='Start', scroll=1, format='(i6)', $
                                                          minimum=1, maximum=dims[j], /drag, $
                                                          value=1)
               self.widgets.scans[i].dims[j].stop = cw_fslider(row, /edit, $
                                                          title='Stop', scroll=1, format='(i6)',$
                                                          minimum=1, maximum=dims[j], /drag, $
                                                          value=dims[j])
               ; Set the mode to that for the previous scan
               self.widgets.scans[i].dims[j].mode = cw_bgroup(row, ['Points', 'Cut', 'Sum'], $
                                                          uvalue = ['Points', 'Cut', 'Sum'], $
                                                          label_top='Mode', row=1, $
                                                          set_value=self.scan_settings[i].dim_mode[j], /exclusive)


           endfor
       endif else begin
       ; No detectors, can't display
           row = widget_base(col, /row)
           t = widget_label(row, value='No detectors for this scan.')
           self.scan_settings[i].rank = 0
           widget_control, self.widgets.scans[i].display, sensitive=0
       endelse

       ; Select the detector tab
       widget_control, stab, set_tab_current=1
   endfor

   ; Select the inner most scan as the default, since it is most interesting
   widget_control, self.widgets.scan_base, set_tab_current=self.selected_scan < (fileheader.rank-1)
   widget_control, self.widgets.scan_base_top, /realize
   xmanager, 'epics_sscan_display', self.widgets.scan_base_top, /no_block
   widget_control, self.widgets.status, set_value='Read file complete ...'
end


pro epics_sscan_display::free_memory
    ptr_free, self.pscan
    widget_control, self.widgets.filename, set_value=''
end


pro tomo_abort_event, event
    ; This procedure is called when an abort event is received.
    widget_control, event.id, set_uvalue=1
end


pro epics_sscan_display_event, event
    widget_control, event.top, get_uvalue=epics_sscan_display
    epics_sscan_display->event, event
end


pro epics_sscan_display::display_scan, scan=scan
    if (not obj_valid(*self.pscan)) then return
    widget_control, /hourglass
    fileHeader = *self.pscan->getFileHeader()
    if (n_elements(scan) eq 0) then scan=fileHeader.rank-1
    ; Look for selected positioner to display
    i=scan
    sh = (*fileHeader.pScanHeader)[i]
    positioner = 0
    for j=0, sh.numPositioners-1 do begin
        selected = widget_info(self.widgets.scans[i].positioners[j].select, /button_set)
        if (selected) then begin
            positioner = j
            break
        endif
    endfor
    for j=0, sh.numDetectors-1 do begin
        selected = widget_info(self.widgets.scans[i].detectors[j].select, /button_set)
        if (selected) then begin
            if (n_elements(detector) eq 0) then detector = j else detector = [detector, j]
        endif
    endfor

    range = lonarr(4,2)
    total = lonarr(4)
    for j=0, self.scan_settings[i].rank-1 do begin
        widget_control, self.widgets.scans[i].dims[j].start, get_value=start
        start = (start-1) > 0 < (self.scan_settings[i].dimensions[j]-1)
        widget_control, self.widgets.scans[i].dims[j].stop, get_value=stop
        stop = (stop-1) > start < (self.scan_settings[i].dimensions[j]-1)
        range[j,0] = start
        range[j,1] = stop
        widget_control, self.widgets.scans[i].dims[j].mode, get_value=mode
        total[j] = (mode eq 2)
    endfor

    widget_control, self.widgets.grid, get_value=grid
    widget_control, self.widgets.display_mode, get_value=display_mode
    view_next = display_mode eq 1
    overplot = display_mode eq 2
    widget_control, self.widgets.display2D, get_value=display2D
    image = display2D eq 0
    surface = display2D eq 1
    contour = display2D eq 2

    if (view_next) then begin
        *self.pscan->display, scan=scan+1, positioner=positioner+1, detector=detector+1, grid=grid, $
                              view_next=view_next, $
                              image=image, surface=surface, contour=contour, $
                              xrange = range[0,*], yrange=range[1,*], zrange=range[2,*], $
                              xtotal = total[0], ytotal=total[1], ztotal=total[2]
    endif else begin
        *self.pscan->display, scan=scan+1, positioner=positioner+1, detector=detector+1, grid=grid, $
                              overplot=overplot, $
                              image=image, surface=surface, contour=contour, $
                              xrange = range[0,*], yrange=range[1,*], zrange=range[2,*], $
                              xtotal = total[0], ytotal=total[1], ztotal=total[2]
    endelse
end


pro epics_sscan_display::print_scan, scan=scan
    if (not obj_valid(*self.pscan)) then return
    widget_control, /hourglass
    fileHeader = *self.pscan->getFileHeader()
    if (n_elements(scan) eq 0) then scan=fileHeader.rank-1
    ; Look for selected positioner to print
    i=scan
    sh = (*fileHeader.pScanHeader)[i]
    positioner = 0
    len = strpos(fileHeader.filename, '.mda')
    output = strmid(fileHeader.filename, 0, len) + '.ascii'
    for j=0, sh.numPositioners-1 do begin
        selected = widget_info(self.widgets.scans[i].positioners[j].select, /button_set)
        if (selected) then begin
            positioner = j
            break
        endif
    endfor
    for j=0, sh.numDetectors-1 do begin
        selected = widget_info(self.widgets.scans[i].detectors[j].select, /button_set)
        if (selected) then begin
            if (n_elements(detector) eq 0) then detector = j else detector = [detector, j]
        endif
    endfor

    range = lonarr(4,2)
    total = lonarr(4)
    for j=0, self.scan_settings[i].rank-1 do begin
        widget_control, self.widgets.scans[i].dims[j].start, get_value=start
        start = (start-1) > 0 < (self.scan_settings[i].dimensions[j]-1)
        widget_control, self.widgets.scans[i].dims[j].stop, get_value=stop
        stop = (stop-1) > start < (self.scan_settings[i].dimensions[j]-1)
        range[j,0] = start
        range[j,1] = stop
        widget_control, self.widgets.scans[i].dims[j].mode, get_value=mode
        total[j] = (mode eq 2)
    endfor

    *self.pscan->print_columns, scan=scan+1, positioner=positioner+1, detector=detector+1, $
                              xrange = range[0,*], yrange=range[1,*], zrange=range[2,*], $
                              xtotal = total[0], ytotal=total[1], ztotal=total[2], $
                              output=output, /display
end


pro epics_sscan_display::ascii_output
    if (not obj_valid(*self.pscan)) then return
    widget_control, /hourglass
    fileHeader = *self.pscan->getFileHeader()
    widget_control, self.widgets.ascii_options, get_value=options
    positioners = options[0]
    detectors =   options[1]
    extrapvs =    options[2]
    file =        options[3]
    display =     options[4]
    if (file) then begin
       len = strpos(fileHeader.filename, '.mda')
       output = strmid(fileHeader.filename, 0, len) + '.ascii'
    endif
    *self.pscan->print, positioners=positioners, detectors=detectors, $
                        extrapvs=extrapvs, display=display, output=output
end


pro epics_sscan_display::event, event
    if (tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST') then begin
        widget_control, event.top, /destroy
        obj_destroy, self
        return
    endif
    catch, err
    if (err ne 0) then begin
        t = dialog_message(!error_state.msg, /error)
        widget_control, self.widgets.status, set_value=!error_state.msg
        goto, end_event
    endif

    case event.id of
        self.widgets.read_scan_file: begin
            file = dialog_pickfile(filter='*.mda*', get_path=path)
            if (file eq '') then break
            pos = strpos(file, path)
            if (pos ge 0) then begin
                pos = pos + strlen(path)
                file = strmid(file, pos)
            endif
            cd, path
            self->read_scan_file, file
            goto, end_event
        end

        self.widgets.next_scan_file: begin
            self->read_scan_file, self.next_file
            goto, end_event
        end

        self.widgets.previous_scan_file: begin
            self->read_scan_file, self.previous_file
            goto, end_event
        end

        self.widgets.ascii_output: begin
            self->ascii_output
            goto, end_event
        end

        self.widgets.scan_base: begin
            self.selected_scan = event.tab
            goto, end_event
        end

        self.widgets.exit: begin
            widget_control, event.top, /destroy
            obj_destroy, self
            return
        end

        else: begin
            ; Other widgets either don't generate events we care about or are handled
            ; in the loops below
        end
    endcase

    ; Loop through the scan widgets and see if they have generated an event
    valid_scan = widget_info(self.widgets.scan_base_top, /valid)
    if (not valid_scan) then goto, end_event
    if (not ptr_valid(self.pscan)) then goto, end_event
    if (not obj_valid(*self.pscan)) then goto, end_event

    fileHeader = *self.pscan->getFileHeader()
    for i=0, fileHeader.rank-1 do begin
        sh = (*fileHeader.pScanHeader)[i]
        if (event.id eq self.widgets.scans[i].select_all_detectors) then begin
            for j=0, sh.numDetectors-1 do  begin
                widget_control, self.widgets.scans[i].detectors[j].select, set_button=1
            endfor
            goto, end_event
        endif

        if (event.id eq self.widgets.scans[i].deselect_all_detectors) then begin
            for j=0, sh.numDetectors-1 do  begin
                widget_control, self.widgets.scans[i].detectors[j].select, set_button=0
            endfor
            goto, end_event
        endif

        if (event.id eq self.widgets.scans[i].display) then begin
            self->display_scan, scan=i
            goto, end_event
        endif

        if (event.id eq self.widgets.scans[i].print) then begin
            self->print_scan, scan=i
            goto, end_event
        endif

        for j=0, self.scan_settings[i].rank-1 do begin
            widget_control, self.widgets.scans[i].dims[j].mode, get_value=mode
            if (event.id eq self.widgets.scans[i].dims[j].start) then begin
                start = event.value
                self.scan_settings[i].dim_start[j] = start
                widget_control, self.widgets.scans[i].dims[j].mode, get_value=mode
                widget_control, self.widgets.scans[i].dims[j].stop, get_value=stop
                if ((mode ne 1) and (start gt stop)) then begin
                    widget_control, self.widgets.scans[i].dims[j].start, set_value=stop
                endif else if (mode eq 1) then begin
                    widget_control, self.widgets.scans[i].dims[j].stop, set_value=start
                endif
                goto, end_event
            endif

            if (event.id eq self.widgets.scans[i].dims[j].stop) then begin
                stop = event.value
                self.scan_settings[i].dim_stop[j] = stop
                widget_control, self.widgets.scans[i].dims[j].mode, get_value=mode
                widget_control, self.widgets.scans[i].dims[j].start, get_value=start
                if ((mode ne 1) and (stop lt start)) then begin
                    widget_control, self.widgets.scans[i].dims[j].stop, set_value=start
                endif else if (mode eq 1) then begin
                    widget_control, self.widgets.scans[i].dims[j].start, set_value=stop
                endif
                goto, end_event
            endif

            if (event.id eq self.widgets.scans[i].dims[j].mode) then begin
                mode = event.value
                self.scan_settings[i].dim_mode[j] = mode
                if (mode eq 1) then begin
                    widget_control, self.widgets.scans[i].dims[j].start, get_value=start
                    widget_control, self.widgets.scans[i].dims[j].stop, set_value=start
                endif
                goto, end_event
            endif
        endfor

        for j=0, sh.numDetectors-1 do begin
            if (event.id eq self.widgets.scans[i].detectors[j].select) then begin
                self.scan_settings[i].det_select[j] = event.select
                goto, end_event
            endif
        endfor

        for j=0, sh.numPositioners-1 do begin
            if (event.id eq self.widgets.scans[i].positioners[j].select) then begin
                self.scan_settings[i].pos_select[j] = event.select
                goto, end_event
            endif
        endfor

    endfor

    end_event:
    ; If there is a valid scan object make certain widgets sensitive
    valid_scan = ptr_valid(self.pscan)
    if (valid_scan) then begin
        widget_control, self.widgets.visualize_base, sensitive=1
    endif else begin
        widget_control, self.widgets.visualize_base, sensitive=0
        widget_control, self.widgets.next_scan_file, sensitive=0
        widget_control, self.widgets.previous_scan_file, sensitive=0
        valid = widget_info(self.widgets.scan_base_top, /valid)
        if (valid) then widget_control, self.widgets.scan_base_top, /destroy
    endelse

end


function epics_sscan_display::init
;+
; NAME:
;       epics_sscan_display::INIT
;
; PURPOSE:
;       This function initializes an object of class epics_sscan_display.  It is
;       not called directly, but is called indirectly when a new object of
;       class epics_sscan_display is created via OBJ_NEW('epics_sscan_display')
;
;       The epics_sscan_display object is a GUI display which provides control
;       for preprocessing, reconstructing and visualizing tomographic data
;
; CATEGORY:
;       Imaging
;
; CALLING SEQUENCE:
;       obj = OBJ_NEW('epics_sscan_display')
;
; EXAMPLE:
;       IDL> obj = OBJ_NEW('epics_sscan_display')
;

;-

    self.fonts.normal = get_font_name(/helvetica)
    self.fonts.heading1 = get_font_name(/large, /bold)
    self.fonts.heading2 = get_font_name(/bold)

    self.widgets.base= widget_base(column=1, /tlb_kill_request_events, $
                                   title='EPICS sscan Display', mbar=mbar, $
                                   xoffset=20, yoffset=20)

    file = widget_button(mbar, /menu, value = 'File')
    self.widgets.exit = widget_button(file, $
                                            value = 'Exit')
    row0 = widget_base(self.widgets.base, /row)
    col0 = widget_base(row0, /column)
    col = widget_base(col0, /column, /frame)
    self.widgets.scan_file_base = col
    t = widget_label(col, value='File/Status', font=self.fonts.heading1)
    row = widget_base(col, /row, /align_center)
    self.widgets.read_scan_file = widget_button(row, value = 'Read MDA file ...', $
                                                font=self.fonts.heading2)
    self.widgets.previous_scan_file = widget_button(row, value = '< Previous file', $
                                                font=self.fonts.heading2)
    self.widgets.next_scan_file = widget_button(row, value = '> Next file', $
                                                font=self.fonts.heading2)
    row = widget_base(col, /row)
    self.widgets.filename = cw_field(row, title="File name:", $
                                        xsize=50, /noedit)
    row = widget_base(col, /row)
    self.widgets.version = cw_field(row, title="MDA version:", $
                                        xsize=50, /noedit)
    row = widget_base(col, /row)
    self.widgets.dimensions = cw_field(row, title="Scan dimensions:", $
                                        xsize=50, /noedit)
    row = widget_base(col, /row)
    self.widgets.status = cw_field(row, title="Status:", $
                                        xsize=50, /noedit, $
                                        fieldfont=self.fonts.heading2)
    self.widgets.abort = widget_button(row, value='Abort', $
                                       event_pro='tomo_abort_event')


    ; Visualization
    col = widget_base(col0, /column, /frame)
    self.widgets.visualize_base = col
    t = widget_label(col, value='Display Options', font=self.fonts.heading1)

    row = widget_base(col, /row)
    self.widgets.display_mode = cw_bgroup(row, ['New window', 'Re-use window', 'Overplot'], $
                                            label_left='Next iTools display:', $
                                            row=1, set_value=0, /exclusive)

    row = widget_base(col, /row)
    self.widgets.grid = cw_bgroup(row, ['Overplot', 'Grid'], $
                                            label_left='Multiple detectors:', $
                                            row=1, set_value=0, /exclusive)

    row = widget_base(col, /row)
    self.widgets.display2D = cw_bgroup(row, ['Image', 'Surface', 'Contour'], $
                                            label_left='2D display:', $
                                            row=1, set_value=0, /exclusive)

    row = widget_base(col, /row)
    t = widget_label(col, value='ASCII Output', font=self.fonts.heading1)
    row = widget_base(col, /row)
    self.widgets.ascii_options = cw_bgroup(row, ['Positioners', 'Detectors', 'ExtraPVs', $
                                                 'To file', 'To screen'], $
                                            label_left='Output:', $
                                            row=1, set_value=[0,0,0,0,1], /nonexclusive)
    row = widget_base(col, /row, /align_center)
    self.widgets.ascii_output = widget_button(row, value='Display as ASCII', $
                                              font=self.fonts.heading2)

    widget_control, self.widgets.base, set_uvalue=self
    ; Make all of the base widgets the same size so they line up nicely
    g = widget_info(self.widgets.scan_file_base, /geometry)
    widget_control, self.widgets.visualize_base, xsize=g.xsize

    widget_control, self.widgets.visualize_base, sensitive=0
    widget_control, self.widgets.next_scan_file, sensitive=0
    widget_control, self.widgets.previous_scan_file, sensitive=0

    widget_control, self.widgets.base, /realize

    xmanager, 'epics_sscan_display', self.widgets.base, /no_block
    return, 1
end

pro epics_sscan_display::cleanup
    ptr_free, self.pscan
end

pro epics_sscan_display__define
    MAX_SCANS = 4
    MAX_DIMENSIONS = 4
    MAX_POSITIONERS = 4
    MAX_DETECTORS = 85

    positioner_widgets = {epics_sscan_display_positioner_widgets, $
        base: 0L, $
        select: 0L, $
        name: 0L, $
        description: 0L, $
        units:  0L, $
        readbackName: 0L, $
        readbackDescription: 0L, $
        readbackUnits: 0L, $
        min: 0L, $
        max: 0L $
    }

    detector_widgets = {epics_sscan_display_detector_widgets, $
        base: 0L, $
        select: 0L, $
        name: 0L, $
        description: 0L, $
        units:  0L, $
        min: 0L, $
        max: 0L $
    }

    dimension_widgets = {epics_sscan_display_dimension_widgets, $
        base: 0L, $
        start: 0L, $
        stop: 0L, $
        mode: 0L $
    }

    scan_widgets = {epics_sscan_display_scan_widgets, $
        base: 0L, $
        name: 0L, $
        npts: 0L, $
        cpt:  0L, $
        display: 0L, $
        print: 0L, $
        dimensions: 0L, $
        positioners: replicate(positioner_widgets, MAX_POSITIONERS), $
        detectors: replicate(detector_widgets, MAX_DETECTORS), $
        dims: replicate(dimension_widgets, MAX_DIMENSIONS), $
        select_all_detectors: 0L, $
        deselect_all_detectors: 0L $
    }

    scan_settings = {epics_sscan_scan_settings, $
        rank: 0L, $
        dimensions: lonarr(MAX_DIMENSIONS), $
        dimensions_string: '', $
        dim_start: lonarr(MAX_DIMENSIONS), $
        dim_stop:  lonarr(MAX_DIMENSIONS), $
        dim_mode: lonarr(MAX_DIMENSIONS), $
        pos_select: lonarr(MAX_POSITIONERS), $
        det_select: lonarr(MAX_DETECTORS) $
    }

    widgets={ epics_sscan_display_widgets, $
        base: 0L, $
        read_scan_file: 0L, $
        next_scan_file: 0L, $
        previous_scan_file: 0L, $
        ascii_output: 0L, $
        exit: 0L, $
        scan_file_base: 0L, $
        filename: 0L, $
        version: 0L, $
        dimensions: 0L, $
        status: 0L, $
        abort: 0L, $
        scan_base_top: 0L, $
        scan_base: 0L, $
        scans: replicate(scan_widgets, MAX_SCANS), $
        visualize_base: 0L, $
        grid: 0L, $
        display2D: 0L, $
        display_mode: 0L, $
        ascii_options: 0L $
    }

    fonts = {tomo_fonts, $
        normal: '', $
        heading1: '', $
        heading2: '' $
    }

    epics_sscan_display = {epics_sscan_display, $
        widgets: widgets, $
        pscan: ptr_new(), $
        next_file: '', $
        previous_file: '', $
        scan_settings: replicate(scan_settings, MAX_SCANS), $
        selected_scan: 0L, $
        fonts: fonts $
    }
end
