pro epics_sscan_display::rebin, image, x_dist, y_dist
    ; This function is called to rebin a 2-D array, either shrinking or expanding it
    ; by the selected "zoom" factor
    widget_control, self.widgets.zoom, get_value=zoom, get_uvalue=all_zooms
    zoom = all_zooms[zoom]
    if (zoom eq 1) then return
    image = reform(image)
    ncols = n_elements(image[*,0])
    nrows = n_elements(image[0,*])
    if (zoom gt 1) then begin
        last_col = ncols - 1
        last_row = nrows - 1
        ncols = ncols * fix(zoom)
        nrows = nrows * fix(zoom)
    endif
    if (zoom lt -1) then begin
        izoom = fix(abs(zoom))
        last_col = (ncols/izoom)*izoom - 1
        last_row = (nrows/izoom)*izoom - 1
        ncols = ncols / izoom
        nrows = nrows / izoom
    endif
    image = rebin(image[0:last_col, 0:last_row], ncols, nrows)
    x_dist = rebin(x_dist[0:last_col], ncols)
    y_dist = rebin(y_dist[0:last_row], nrows)

end


pro epics_sscan_display::free_memory
    ptr_free, self.pscan
    widget_control, self.widgets.volume_file, set_value=''
end


pro tomo_options_event, event
    widget_control, event.top, get_uvalue=epics_sscan_display
    epics_sscan_display->options_event, event
end

pro epics_sscan_display::options_event, event
    if (tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST') then begin
        widget_control, self.widgets.options_base, map=0
        return
    endif
    case event.id of
        self.widgets.backproject: begin
            sens = event.value
            widget_control, self.widgets.backproject_base, sensitive=sens
            widget_control, self.widgets.gridrec_base, sensitive=1-sens
        end
        self.widgets.remove_rings: begin
            ; Nothing to do
        end
        self.widgets.white_average: begin
            ; Nothing to do
        end
        self.widgets.fluorescence: begin
            ; Nothing to do
        end
        self.widgets.display_sinogram: begin
            ; Nothing to do
        end
        self.widgets.plot_cog: begin
            ; Nothing to do
        end
        self.widgets.backproject_filter: begin
            ; Nothing to do
        end
        self.widgets.backproject_interpolation: begin
            ; Nothing to do
        end
        self.widgets.gridrec_resize: begin
            ; Nothing to do
        end
        else:  t = dialog_message('Unknown event')
    endcase
end

pro tomo_abort_event, event
    ; This procedure is called when an abort event is received.
    widget_control, event.id, set_uvalue=1
end


pro epics_sscan_display_event, event
    widget_control, event.top, get_uvalue=epics_sscan_display
    epics_sscan_display->event, event
end

pro epics_sscan_display::display_slice, new_window=new_window
    if (ptr_valid(self.pvolume)) then begin
        widget_control, self.widgets.disp_slice, get_value=slice
        widget_control, self.widgets.display_min, get_value=min
        widget_control, self.widgets.display_max, get_value=max
        widget_control, self.widgets.direction, get_value=direction
        widget_control, self.widgets.volume_file, get_value=file
        ; Set the axis dimensions
        if (self.setup.image_type eq 'RECONSTRUCTED') then begin
            xdist = findgen(self.nx)*self.setup.x_pixel_size
            ydist = findgen(self.ny)*self.setup.x_pixel_size
            zdist = findgen(self.nz)*self.setup.y_pixel_size
        endif else begin
            xdist = findgen(self.nx)*self.setup.x_pixel_size
            ydist = findgen(self.ny)*self.setup.y_pixel_size
            zdist = *self.setup.angles
        endelse
        case direction of
            0: begin
                slice = (slice > 0) < (self.nx-1)
                r = (*(self.pvolume))[slice, *, *]
                xdist = ydist
                ydist = zdist
                end
            1: begin
                slice = (slice > 0) < (self.ny-1)
                r = (*(self.pvolume))[*, slice, *]
                ydist = zdist
                end
            2: begin
                slice = (slice > 0) < (self.nz-1)
                r = (*(self.pvolume))[*, *, slice]
                end
        endcase
        axes = ['X', 'Y', 'Z']
        widget_control, self.widgets.rotation_center, get_value=center
        title = file + '    Center='+strtrim(string(center),2) + $
                    '     '+axes[direction]+'='+strtrim(string(slice),2)
        widget_control, self.widgets.auto_intensity, get_value=auto
        if (auto) then begin
            min=min(r, max=max)
        endif else begin
            widget_control, self.widgets.display_min, get_value=min
            widget_control, self.widgets.display_max, get_value=max
        endelse
        ; Change the size of the image before calling image_display
        self->rebin, r, xdist, ydist
        if (keyword_set(new_window)) or (obj_valid(self.image_display) eq 0) then begin
            self.image_display = obj_new('image_display', r, min=min, max=max, $
                                          title=title, xdist=xdist, ydist=ydist)
        endif else begin
            self.image_display->scale_image, r, min=min, max=max, $
                                          title=title, xdist=xdist, ydist=ydist, /leave_mouse
        endelse

    endif else begin
        t = dialog_message('Must read in volume file first.', /error)
    endelse
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
                self->set_directory
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
            ptr_free, self.pscan
            widget_control, /hourglass
            widget_control, self.widgets.status, $
                            set_value='Reading scan file ...'
            scan = read_mda(file)
            self.pscan = ptr_new(scan, /no_copy)
            *self.pscan->display
            dims = size(*self.pvolume, /dimensions)
            ; Set the volume filename and path
            widget_control, self.widgets.volume_file, set_value=file
            widget_control, self.widgets.directory, set_value=path
            ; Set the array dimensions
            widget_control, self.widgets.nx, set_value=dims[0]
            self.nx = dims[0]
            widget_control, self.widgets.ny, set_value=dims[1]
            self.ny = dims[1]
            widget_control, self.widgets.nz, set_value=dims[2]
            self.nz = dims[2]
            ; Set the intensity range
            min = min(*self.pvolume, max=max)
            widget_control, self.widgets.display_min, set_value=min
            widget_control, self.widgets.display_max, set_value=max
            ; Set the slice display range
            self->set_limits
            ; Build the angle array if it does not exist
            if (not ptr_valid(self.setup.angles)) then begin
                ; Assume evenly spaced angles 0 to 180-angle_step degrees
                self.setup.angles = ptr_new(findgen(self.nz)/(self.nz) * 180.)
            endif
            ; Set the pixel sizes to 1 if they are zero
            if (self.setup.x_pixel_size eq 0.) then self.setup.x_pixel_size=1.0
            if (self.setup.y_pixel_size eq 0.) then self.setup.y_pixel_size=1.0
            if (self.setup.z_pixel_size eq 0.) then self.setup.z_pixel_size=1.0
            widget_control, self.widgets.status, $
                            set_value='Done reading volume file ' + file
        end


        self.widgets.free_memory: begin
            self->free_memory
        end

        self.widgets.exit: begin
            widget_control, event.top, /destroy
            obj_destroy, self
            return
        end

        self.widgets.processing_options: begin
            widget_control, self.widgets.options_base, map=1
        end

        self.widgets.base_file: begin
            widget_control, self.widgets.base_file, get_value=base_file
            self->set_base_file, base_file[0]
        end


        self.widgets.direction: begin
            self->set_limits
        end

        self.widgets.order: begin
            widget_control, self.widgets.order, get_value=order
            !order=order
        end

        self.widgets.auto_intensity: begin
            ; Nothing to do
        end

        self.widgets.disp_slice: begin
            widget_control, self.widgets.disp_slider, set_value=event.value
            self->display_slice
        end

        self.widgets.disp_slider: begin
            widget_control, self.widgets.disp_slice, set_value=event.value
            self->display_slice
        end

        self.widgets.display_slice: begin
            self->display_slice, /new_window
        end

        self.widgets.volume_render: begin
            self->volume_render
        end

        self.widgets.movie_output: begin
            ; Nothing to do
        end

        self.widgets.zoom: begin
            ; Nothing to do
        end

        self.widgets.make_movie: begin
            widget_control, self.widgets.disp_slice, get_value=slice
            if (ptr_valid(self.pvolume)) then begin
                widget_control, self.widgets.movie_output, get_value=output
                widget_control, self.widgets.display_min, get_value=min
                widget_control, self.widgets.display_max, get_value=max
                widget_control, self.widgets.direction, get_value=direction
                widget_control, self.widgets.movie_file, get_value=file
                widget_control, self.widgets.zoom, get_value=zoom, get_uvalue=all_zooms
                widget_control, self.widgets.first_slice, get_value=start
                widget_control, self.widgets.last_slice, get_value=stop
                widget_control, self.widgets.slice_step, get_value=step
                scale = all_zooms[zoom]
                label=0
                case output of
                    0: label=1
                    1: widget_control, self.widgets.movie_file, $
                                       get_value=jpeg_file
                    2: widget_control, self.widgets.movie_file, $
                                       get_value=mpeg_file
                    3: widget_control, self.widgets.movie_file, $
                                       get_value=tiff_file
                endcase
                widget_control, self.widgets.abort, set_uvalue=0
                widget_control, self.widgets.status, set_value=""
                make_movie, index=direction+1, scale=scale, *self.pvolume, $
                            jpeg_file=jpeg_file, tiff_file=tiff_file, mpeg_file=mpeg_file, $
                            min=min, max=max, start=start, stop=stop, step=step, $
                            label=label, abort_widget=self.widgets.abort, $
                            status_widget=self.widgets.status
            endif else begin
                t = dialog_message('Must read in volume file first.', /error)
            endelse
        end

        else:  t = dialog_message('Unknown event')
    endcase

    ; If there is a valid volume array make the visualize base sensitive
    sensitive = ptr_valid(self.pvolume)
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
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers (16-Nov-2001)
;       June 4, 2002    MLR  Made the display slice entry and slider display an
;                            image in an existing window if it exists.
;       Jan. 9, 2004    MLR  Added TIFF output for make_movie
;
;-

    self.fonts.normal = get_font_name(/helvetica)
    self.fonts.heading1 = get_font_name(/large, /bold)
    self.fonts.heading2 = get_font_name(/bold)

    self.widgets.base= widget_base(column=1, /tlb_kill_request_events, $
                                   title='EPICS sscan Display', mbar=mbar)

    file = widget_button(mbar, /menu, value = 'File')
    self.widgets.read_scan_file = widget_button(file, $
                                            value = 'Read MDA file ...')
    self.widgets.free_memory = widget_button(file, value='Free sscan')
    self.widgets.exit = widget_button(file, $
                                            value = 'Exit')
    options = widget_button(mbar, /menu, value = 'Options')
    row0 = widget_base(self.widgets.base, /row, /frame)
    col0 = widget_base(row0, /column, /frame)
    col = widget_base(col0, /column, /frame)
    self.widgets.scan_file_base = col
    t = widget_label(col, value='File/Status', font=self.fonts.heading1)
    self.widgets.filename = cw_field(col, title="File name:", $
                                        xsize=50, /return_events)
    self.widgets.version = cw_field(col, title="Working directory:", $
                                        xsize=50, /noedit)
    self.widgets.dimensions = cw_field(col, title="Volume file name:", $
                                        xsize=50, /noedit)
    row = widget_base(col, /row)
    self.widgets.status = cw_field(row, title="Status:", $
                                        xsize=50, /noedit, $
                                        fieldfont=self.fonts.heading2)
    self.widgets.abort = widget_button(row, value='Abort', $
                                       event_pro='tomo_abort_event')


    ; Scans
    col = widget_base(col0, /column, /frame)
    self.widgets.scan_base = col
    ; Visualization
    col = widget_base(row0, /column, /frame)
    self.widgets.visualize_base = col
    widget_control, col, sensitive=0
    t = widget_label(col, value='Visualize', font=self.fonts.heading1)

    row = widget_base(col, /row)
    t = widget_label(row, value='Volume array:')
    self.widgets.nx = cw_field(row, title='NX', /integer, /noedit, /column, $
                               xsize=8, value=0)
    self.widgets.ny = cw_field(row, title='NY', /integer, /noedit, /column, $
                               xsize=8, value=0)
    self.widgets.nz = cw_field(row, title='NZ', /integer, /noedit, /column, $
                               xsize=8, value=0)
    self.widgets.volume_type = cw_field(row, title='Type', /noedit, /column, $
                               xsize=18, value='')

    row = widget_base(col, /row, /base_align_center)
    t = widget_label(row, value='Intensity range:')
    self.widgets.display_min = cw_field(row, title='Min.', /float, $
                                        /column, xsize=10, value=0)
    self.widgets.display_max = cw_field(row, title='Max.', /float, $
                                        /column, xsize=10, value=5000)
    self.widgets.auto_intensity = cw_bgroup(row, ['Manual', 'Auto'], $
                                             row=1, set_value=1, /exclusive)


    row = widget_base(col, /row)
    self.widgets.direction = cw_bgroup(row, ['X', 'Y', 'Z'], $
                                            label_left='Direction:', $
                                            row=1, set_value=2, /exclusive)
    !order=1
    self.widgets.order = cw_bgroup(row, ['Bottom to top', 'Top to bottom'], $
                                            label_left='Order:', row=1, $
                                            set_value=1, /exclusive)

    row = widget_base(col, /row)
    self.widgets.zoom = cw_bgroup(row, ['1/4', '1/2', '1', '2', '4'], $
                                    label_left='Zoom:', row=1, $
                                    set_value=2, /exclusive, $
                                    uvalue=[-4, -2, 1, 2, 4])

    row = widget_base(col, /row)
    t = widget_label(row, value='Display slice:')
    col1=widget_base(row, /column)
    self.widgets.disp_slice = cw_field(col1, /integer, title='',$
                                       xsize=10, value=100, /return_events)
    self.widgets.disp_slider = widget_slider(col1, value=100, min=0, max=100, $
                                             /suppress_value)
    col1 = widget_base(row, /column, /align_center)
    self.widgets.display_slice = widget_button(col1, value='Display slice')

    row = widget_base(col, /row)
    t = widget_label(row, value='Volume render:')
    self.widgets.volume_render = widget_button(row, value='Volume render')

    t = widget_label(col, value='Movies', font=self.fonts.heading1)

    row = widget_base(col, /row)
    self.widgets.movie_output = cw_bgroup(row, ['Screen', 'JPEGs', 'MPEG', 'TIFF'], $
                                            label_left='Output:', row=1, $
                                            set_value=0, /exclusive)
    col1 = widget_base(row, /column, /align_center)
    self.widgets.make_movie = widget_button(col1, value='Make movie')

    row = widget_base(col, /row)
    self.widgets.first_slice = cw_field(row, title='First slice', /integer, $
                                        /column, xsize=10, value=0)
    self.widgets.last_slice = cw_field(row, title='Last slice', /integer, $
                                        /column, xsize=10, value=0)
    self.widgets.slice_step = cw_field(row, title='Step', /integer, $
                                        /column, xsize=10, value=1)

    row = widget_base(col, /row)
    self.widgets.movie_file = cw_field(row, title="JPEG/MPEG/TIFF file name:", $
                                        xsize=40)


    widget_control, self.widgets.base, set_uvalue=self
    ; Make all of the base widgets the same size so they line up nicely
    g = widget_info(self.widgets.scan_file_base, /geometry)
    widget_control, self.widgets.scan_base, xsize=g.xsize
    widget_control, self.widgets.visualize_base, xsize=g.xsize
    widget_control, self.widgets.base, /realize


    xmanager, 'epics_sscan_display', self.widgets.base, /no_block
    return, 1
end

pro epics_sscan_display::cleanup
    ptr_free, self.pscan
end

pro epics_sscan_display__define

    MAX_SCANS = 4
    widgets={ epics_sscan_display_widgets, $
        base: 0L, $
        change_directory: 0L, $
        read_scan_file: 0L, $
        free_memory: 0L, $
        exit: 0L, $
        scan_file_base: 0L, $
        filename: 0L, $
        version: 0L, $
        dimensions: 0L, $
        status: 0L, $
        abort: 0L, $
        scan_base: 0L, $
        scan_bases: lonarr(MAX_SCANS), $
        visualize_base: 0L, $
        nx: 0L, $
        ny: 0L, $
        nz: 0L, $
        volume_type: 0L, $
        direction: 0L, $
        order: 0L, $
        display_min: 0L, $
        display_max: 0L, $
        auto_intensity: 0L, $
        disp_slice: 0L, $
        disp_slider: 0L, $
        display_slice: 0L, $
        volume_render: 0L, $
        movie_output: 0L, $
        first_slice: 0L, $
        last_slice: 0L, $
        slice_step: 0L, $
        zoom: 0L, $
        movie_file: 0L, $
        make_movie: 0L $

    }

    fonts = {tomo_fonts, $
        normal: '', $
        heading1: '', $
        heading2: '' $
    }

    epics_sscan_display = {epics_sscan_display, $
        widgets: widgets, $
        pscan: ptr_new(), $
        fonts: fonts $
    }
end
