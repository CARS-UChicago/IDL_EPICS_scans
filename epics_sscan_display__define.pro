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
       xoffset = 0
       yoffset = 0
   endelse
   self.widgets.scan_base_top = widget_base(column=1, xoffset=xoffset, yoffset=yoffset, $
                                   title='EPICS sscan Scans')
   widget_control, self.widgets.scan_base_top, set_uvalue=self
   self.widgets.scan_base = widget_tab(self.widgets.scan_base_top)
   for i=0, fileHeader.rank-1 do begin
       sh = (*fileHeader.pScanHeader)[i]
       col = widget_base(self.widgets.scan_base, /column, $
                         title=sh.name, frame=0)
       row = widget_base(col, /row, /align_center)
       self.widgets.scans[i].display = widget_button(row, value='Display with iTools', font=self.fonts.heading2)
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

           for j=0, sh.numPositioners-1 do begin
               row = widget_base(col, /row)
               p = (*sh.pPositioners)[j]
               button_base = widget_base(row, /nonexclusive)
               self.widgets.scans[i].positioners[j].select = widget_button(button_base, value='')
               self.widgets.scans[i].positioners[j].name = widget_text(row, xsize=20, value=p.name)
               self.widgets.scans[i].positioners[j].units = widget_text(row, xsize=6, value=p.units)
               self.widgets.scans[i].positioners[j].description = widget_text(row, xsize=30, $
                                                    value=p.description)
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
           ; Make the first positioner the default
           widget_control, self.widgets.scans[i].positioners[0].select, set_button=1
       endif

       col = widget_base(stab, /column, title='Detectors', frame=0)
       if (sh.numDetectors gt 0) then begin
           row = widget_base(col, /row, /align_center)
           t = widget_label(row, value='Detectors', $
                            font=self.fonts.heading2)

           MAX_DETECTORS_PER_TAB = 10
           det_base = widget_tab(col)
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
               endif
               row = widget_base(tab, /row)
               d = (*sh.pDetectors)[j]
               button_base = widget_base(row, /nonexclusive, frame=0)
               self.widgets.scans[i].detectors[j].select = widget_button(button_base, value='')
               self.widgets.scans[i].detectors[j].name = widget_text(row,  xsize=20, value=d.name)
               self.widgets.scans[i].detectors[j].units = widget_text(row, xsize=6, value=d.units)
               self.widgets.scans[i].detectors[j].description = widget_text(row, xsize=30, value=d.description)
               if (j mod MAX_DETECTORS_PER_TAB eq 0) then begin
                   ; Make the label widgets the size as the text widgets
                   g = widget_info(button_base, /geometry)
                   widget_control, select_widget, xsize=g.scr_xsize
                   g = widget_info(self.widgets.scans[i].detectors[0].name, /geometry)
                   widget_control, name_widget, xsize=g.scr_xsize
                   g = widget_info(self.widgets.scans[i].detectors[0].units, /geometry)
                   widget_control, units_widget, xsize=g.scr_xsize
                   g = widget_info(self.widgets.scans[i].detectors[0].description, /geometry)
                   widget_control, description_widget, xsize=g.scr_xsize
               endif
           endfor
           ; Make the first positioner the default
           widget_control, self.widgets.scans[i].detectors[0].select, set_button=1
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
               row = widget_base(col, /row, /base_align_center)
               t = widget_label(row, value='Dimension ' + strtrim(j+1,2) + ':')
               self.widgets.scans[i].dims[j].start = cw_field(row, /row, xsize=6, /long, $
                                                          title='Start', $
                                                          value=1)
               self.widgets.scans[i].dims[j].stop = cw_field(row, /row, xsize=6, /long, $
                                                          title='Stop', $
                                                          value=dims[j])
               self.widgets.scans[i].dims[j].total = cw_bgroup(row, ['No', 'Yes'], $
                                            label_left='Total:', row=1, $
                                            set_value=0, /exclusive)

           endfor
       endif else begin
       ; No detectors, can't display
       widget_control, self.widgets.scans[i].display, sensitive=0
       endelse

       ; Select the detector tab
       widget_control, stab, set_tab_current=1
   endfor

   ; Select the inner most scan as the default, since it is most interesting
   widget_control, self.widgets.scan_base, set_tab_current=fileheader.rank-1
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
        widget_control, self.widgets.scans[i].dims[j].total, get_value=tot
        total[j] = tot
    endfor

    widget_control, self.widgets.grid, get_value=grid
    widget_control, self.widgets.new_window, get_value=view_next
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
                              image=image, surface=surface, contour=contour, $
                              xrange = range[0,*], yrange=range[1,*], zrange=range[2,*], $
                              xtotal = total[0], ytotal=total[1], ztotal=total[2]
    endelse
end

pro epics_sscan_display::ascii_output
    if (not obj_valid(*self.pscan)) then return
    widget_control, /hourglass
    widget_control, self.widgets.ascii_options, get_value=options
    positioners = options[0]
    detectors =   options[1]
    extrapvs =    options[2]
    file =        options[3]
    display =     options[4]
    if (file) then filename = dialog_pickfile(/write)
    *self.pscan->print, positioners=positioners, detectors=detectors, $
                        extrapvs=extrapvs, display=display, output=filename
end


pro epics_sscan_display::event, event
    if (tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST') then begin
        widget_control, event.top, /destroy
        obj_destroy, self
        return
    endif
    case event.id of
        self.widgets.change_directory: begin
            f = dialog_pickfile(/directory, get_path=p)
            if (p ne "") then begin
                cd, p
            endif
        end

        self.widgets.read_scan_file: begin
            file = dialog_pickfile(filter='*.mda', get_path=path)
            if (file eq '') then break
                pos = strpos(file, path)
                if (pos ge 0) then begin
                pos = pos + strlen(path)
                file = strmid(file, pos)
            endif
            cd, path
            self->read_scan_file, file
        end

        self.widgets.ascii_output: begin
            self->ascii_output
        end

        self.widgets.free_memory: begin
            self->free_memory
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
    if (ptr_valid(self.pscan)) then if (obj_valid(*self.pscan)) then begin
        fileHeader = *self.pscan->getFileHeader()
        for i=0, fileHeader.rank-1 do begin
            sh = (*fileHeader.pScanHeader)[i]
            if (event.id eq self.widgets.scans[i].select_all_detectors) then begin
                for j=0, sh.numDetectors-1 do  begin
                    widget_control, self.widgets.scans[i].detectors[j].select, set_button=1
                endfor
            endif
            if (event.id eq self.widgets.scans[i].deselect_all_detectors) then begin
                for j=0, sh.numDetectors-1 do  begin
                    widget_control, self.widgets.scans[i].detectors[j].select, set_button=0
                endfor
            endif
            if (event.id eq self.widgets.scans[i].display) then self->display_scan, scan=i
        endfor
    endif


    ; If there is a valid scan object make certain widgets sensitive
    sensitive = ptr_valid(self.pscan)
    widget_control, self.widgets.ascii_output, sensitive=sensitive
    widget_control, self.widgets.free_memory, sensitive=sensitive
    widget_control, self.widgets.visualize_base, sensitive=sensitive

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
                                   title='EPICS sscan Display', mbar=mbar)

    file = widget_button(mbar, /menu, value = 'File')
    self.widgets.change_directory = widget_button(file, $
                                            value = 'Change directory ...')
    self.widgets.read_scan_file = widget_button(file, $
                                            value = 'Read MDA file ...')
    self.widgets.ascii_output = widget_button(file, value='ASCII output...')
    self.widgets.free_memory = widget_button(file, value='Free sscan')
    self.widgets.exit = widget_button(file, $
                                            value = 'Exit')
    options = widget_button(mbar, /menu, value = 'Options')
    row0 = widget_base(self.widgets.base, /row)
    col0 = widget_base(row0, /column)
    col = widget_base(col0, /column, /frame)
    self.widgets.scan_file_base = col
    t = widget_label(col, value='File/Status', font=self.fonts.heading1)
    self.widgets.filename = cw_field(col, title="File name:", $
                                        xsize=50, /return_events)
    self.widgets.version = cw_field(col, title="MDA version:", $
                                        xsize=50, /noedit)
    self.widgets.dimensions = cw_field(col, title="Scan dimensions:", $
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
    self.widgets.new_window = cw_bgroup(row, ['New window', 'Re-use window'], $
                                            label_left='iTools display:', $
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
    self.widgets.ascii_options = cw_bgroup(row, ['Positioners', 'Detectors', 'ExtraPVs', $
                                                 'To file', 'To screen'], $
                                            label_left='ASCII output:', $
                                            row=1, set_value=[0,0,0,0,1], /nonexclusive)

    widget_control, self.widgets.base, set_uvalue=self
    ; Make all of the base widgets the same size so they line up nicely
    g = widget_info(self.widgets.scan_file_base, /geometry)
    widget_control, self.widgets.visualize_base, xsize=g.xsize

    widget_control, self.widgets.ascii_output, sensitive=0
    widget_control, self.widgets.free_memory, sensitive=0
    widget_control, self.widgets.visualize_base, sensitive=0

    widget_control, self.widgets.base, /realize

    xmanager, 'epics_sscan_display', self.widgets.base, /no_block
    return, 1
end

pro epics_sscan_display::cleanup
    ptr_free, self.pscan
end

pro epics_sscan_display__define
    MAX_SCANS = 4
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
        readbackUnits: 0L $
    }

    detector_widgets = {epics_sscan_display_detector_widgets, $
        base: 0L, $
        select: 0L, $
        name: 0L, $
        description: 0L, $
        units:  0L $
    }

    dimension_widgets = {epics_sscan_display_dimension_widgets, $
        base: 0L, $
        start: 0L, $
        stop: 0L, $
        total: 0L $
    }

    scan_widgets = {epics_sscan_display_scan_widgets, $
        base: 0L, $
        name: 0L, $
        npts: 0L, $
        cpt:  0L, $
        display: 0L, $
        dimensions: 0L, $
        positioners: replicate(positioner_widgets, MAX_POSITIONERS), $
        detectors: replicate(detector_widgets, MAX_DETECTORS), $
        dims: replicate(dimension_widgets, MAX_SCANS), $
        select_all_detectors: 0L, $
        deselect_all_detectors: 0L $
    }

    scan_settings = {epics_sscan_scan_settings, $
        rank: 0L, $
        dimensions: lonarr(MAX_SCANS), $
        dimensions_string: '', $
        start: lonarr(MAX_SCANS), $
        stop:  lonarr(MAX_SCANS), $
        total: lonarr(MAX_SCANS) $
    }

    widgets={ epics_sscan_display_widgets, $
        base: 0L, $
        change_directory: 0L, $
        read_scan_file: 0L, $
        ascii_output: 0L, $
        free_memory: 0L, $
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
        new_window: 0L, $
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
        scan_settings: replicate(scan_settings, MAX_SCANS), $
        fonts: fonts $
    }
end
