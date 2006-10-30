function epics_sscan::formatDimensions, dimensions
   dim_string = '['
   ndims = n_elements(dimensions)
   for idim=0L, ndims-2 do begin
      dim_string = dim_string + strtrim(dimensions[idim],2) + ','
   endfor
   dim_string = dim_string + strtrim(dimensions[ndims-1],2)+']'
   return, dim_string
end

function epics_sscan::getColor, index
   common epics_sscanColor, colors, max_colors
   if (n_elements(colors) eq 0) then begin
      colors = [[0,0,0], $    ;  Black
                [255,0,0], $  ;  Red
                [0,255,0], $  ;  Green
                [0,0,255], $  ;  Blue
                [255,255,0], $ ; Yellow
                [0,255,255], $ ; Cyan
                [255,0,255]]   ; Magenta
      max_colors = n_elements(colors[0,*])
   endif
   j = index mod MAX_COLORS
   color = colors[*,j]
   return, color
end


function epics_sscan::getPositioner, scan=scan, positioner=positioner, all=all, copy=copy
;+
; NAME:
;   epics_sscan::getPositioner
;
; PURPOSE:
;   This function returns the positioner information for a scan.
;   The information is returned as an array of {epics_sscanPositioner}
;   structures.
;
; CATEGORY:
;   EPICS scanning tools.
;
; CALLING SEQUENCE:
;   Result = scan->getPositioner()
;
; KEYWORD PARAMETERS:
;   SCAN:
;      The scan for which positioner information will be returned.
;      The default is the innermost scan.  Valid range=1 to the "rank" of
;      the overall dataset, e.g. 1 for a 1-D scan, 2 for a 2-D scan, etc.
;
;   POSITIONER:
;      The number of the positioner to return.  Valid range=1 to number of
;      positioners in this scan.  Default=1, the first positioner for this
;      scan.
;
;   ALL:
;      Set this flag to return an array of all of the positioners for this
;      scan.
;
;  COPY:
;      Set this flag to return a copy of the positioner data, rather than
;      having the pointer in the {epics_sscanPositioner} structure point to
;      the original data in the epics_sscan object.  Set this flag if you
;      will be modifying the data.
;
; OUTPUTS:
;   This function returns an array of {epics_sscanPositioner}
;   structures.  The number of elements in this array will be 1 by default,
;   or if the POSITIONER keyword is specified.  If the ALL keyword is specified
;   then the array dimension will be the total number of positioners in this scan.
;
;   If there are no positioners for this scan, this function will return
;   a new {epics_sscanPositioner} structure, with the data set to the array
;   index in the data, e.g [0,1,2,3,..NPTS-1]
;

; EXAMPLE:
;   IDL> s=read_mda('2idd_0087.mda')
;   IDL> p=s->getPositioner(scan=2)
;   IDL> print, *p.pData
;      -10.000000      -9.5000000      -9.0000000      -8.5000000      -8.0000000      -7.5000000      -7.0000000
;      -6.5000000      -6.0000000      -5.5000000      -5.0000000      -4.5000000      -4.0000000      -3.5000000      -3.0000000
;      -2.5000000      -2.0000000      -1.5000000      -1.0000000     -0.50000000      0.00000000      0.50000000       1.0000000
;       1.5000000       2.0000000       2.5000000       3.0000000       3.5000000       4.0000000       4.5000000       5.0000000
;       5.5000000       6.0000000       6.5000000       7.0000000       7.5000000       8.0000000       8.5000000       9.0000000
;       9.5000000       10.000000
;   IDL> print, p.description
;      PM500_X
;
; MODIFICATION HISTORY:
;   Written by:  Mark Rivers, Nov. 8, 2003
;-
if (n_elements(scan) eq 0) then scan=self.fileHeader.rank
   if ((scan lt 1) or (scan gt self.fileHeader.rank)) then begin
      message, 'Invalid scan'
      return, -1
   endif
   if (n_elements(positioner) eq 0) then positioner=1
   sh = (*self.fileHeader.pScanHeader)[scan-1]
   if ((sh.numPositioners gt 0) and  $
       ((positioner lt 1) or (positioner gt sh.numPositioners))) then begin
      message, 'Invalid positioner'
      return, -1
   endif
   if (sh.numPositioners gt 0) then begin
      if (keyword_set(all)) then begin
         p = *sh.pPositioners
      endif else begin
         p = (*sh.pPositioners)[positioner-1]
      endelse
   endif else begin
      p = {epics_sscanPositioner}
      p.pData = ptr_new(findgen(sh.npts))
   endelse
   if (keyword_set(copy)) then begin
      for i=0L, n_elements(p)-1 do p[i].pData = ptr_new(*p[i].pData)
   endif
   return, p
end


function epics_sscan::getDetector, scan=scan, detector=detector, all=all, copy=copy
;+
; NAME:
;   epics_sscan::getDetector
;
; PURPOSE:
;   This function returns the detector information for a scan.
;   The information is returned as an array of {epics_sscanDetector}
;   structures.
;
; CATEGORY:
;   EPICS scanning tools.
;
; CALLING SEQUENCE:
;   Result = scan->getDetector()
;
; KEYWORD PARAMETERS:
;   SCAN:
;      The scan for which detector information will be returned.
;      The default is the innermost scan.  Valid range=1 to the "rank" of
;      the overall dataset, e.g. 1 for a 1-D scan, 2 for a 2-D scan, etc.
;
;   DETECTOR:
;      The number of the detector to return.  Valid range=1 to number of
;      detectors in this scan.  Default=1, the first detector for this
;      scan.
;
;   ALL:
;      Set this flag to return an array of all of the detectors for this
;      scan.
;
;  COPY:
;      Set this flag to return a copy of the detector data, rather than
;      having the pointer in the {epics_sscanDetector} structure point to
;      the original data in the epics_sscan object.  Set this flag if you
;      will be modifying the data.
;
; OUTPUTS:
;   This function returns an array of {epics_sscanDetector}
;   structures.  The number of elements in this array will be 1 by default,
;   or if the DETECTOR keyword is specified.  If the ALL keyword is specified
;   then the array dimension will be the total number of detectors in this scan.
;
; EXAMPLE:
;   IDL> s=read_mda('2idd_0087.mda')
;   IDL> d=s->getDetector(scan=2, detector=6)
;   IDL> print, (*d.pData)[5:7,6:8]
;      49.0000      54.0000      60.0000
;      51.0000      39.0000      61.0000
;      64.0000      45.0000      51.0000
;   IDL> print, d.name
;      2idd:mca1.R1
;
; MODIFICATION HISTORY:
;   Written by:  Mark Rivers, Nov. 8, 2003
;-
   if (n_elements(scan) eq 0) then scan=self.fileHeader.rank
   if ((scan lt 1) or (scan gt self.fileHeader.rank)) then begin
      message, 'Invalid scan'
      return, -1
   endif
   if (n_elements(detector) eq 0) then detector=1
   sh = (*self.fileHeader.pScanHeader)[scan-1]
   if (sh.numDetectors lt 1) then begin
      message, 'No detectors!'
      return, -1
   endif
   if ((min(detector) lt 1) or (max(detector) gt sh.numDetectors)) then begin
      message, 'Invalid detector'
      return, -1
   endif
   if (keyword_set(all)) then begin
      d = *sh.pDetectors
   endif else begin
      d = (*sh.pDetectors)[detector-1]
   endelse
   if (keyword_set(copy)) then begin
      for i=0L, n_elements(d)-1 do d[i].pData = ptr_new(*d[i].pData)
   endif
   return, d
end


function epics_sscan::getData, p, d, scan=scan, detector=detector, positioner=positioner, all=all, $
                                   xrange=xrange, yrange=yrange, zrange=zrange, $
                                   xtotal=xtotal, ytotal=ytotal, ztotal=ztotal
;+
; NAME:
;   epics_sscan::getData
;
; PURPOSE:
;   This function returns the positioner and detector information for a scan.
;   The information is returned as an array of {epics_sscanPositioner}
;   and {epics_sscanDetector} structures.  The subset of the data to be returned
;   can be specified.
;
; CATEGORY:
;   EPICS scanning tools.
;
; CALLING SEQUENCE:
;   Result = scan->getData(PositionArray, DetectorArray)
;
; KEYWORD PARAMETERS:
;   SCAN:
;      The scan for which information will be returned.
;      Passed to epics_sscan::getPositioner() and epics_sscan::getDetector().
;
;   POSITIONER:
;      The number of the positioner to return.
;      Passed to epics_sscan::getPositioner().
;
;   DETECTOR:
;      The number of the detector to return.
;      Passed to epics_sscan::getDetector().
;
;   ALL:
;      Set this flag to return an array of all of the detectors for this
;      scan. Passed to epics_sscan::getDetector()
;
;   [X,Y,Z]RANGE:
;      Use this keyword to restrict the range of array elements returned in
;      the X, Y, or Z dimensions. 3-D arrays indices are defined as [X,Y,Z].
;      [X,Y,Z]RANGE can each be either:
;         - A scalar, in which case a single array element is returned in
;           that direction.  This will reduce the rank of the detector data
;           by 1.
;         - A 2-element array, in which case a range of array elements are
;           returned in that direction.  If both elements of the array are
;           the same it is equivalent to specifying a scalar for that keyword.
;
;   [X,Y,Z]TOTAL:
;      Set this flag to sum over the array elements in the X, Y, or Z
;      dimensions.  The summation is performed after application of the
;      [X,Y,Z]RANGE keyword, so it is possible to sum over a restricted
;      range of array elements.  Each use of this keyword will reduce the
;      rank of the detector data by 1.  It will also change which positioner
;      arrays are returned, since positioner arrays are not returned for
;      axes with only one element.
;
; OUTPUTS:
;   This function returns a status flag, 0 for success, -1 for failure.
;
;   The positioner information is returned in the PositionArray parameter
;   as array of {epics_sscanPositioner} structures.
;
;   The detector information is returned in the DetectorArray parameter
;   as array of {epics_sscanDetector} structures.

; EXAMPLE:
;   IDL> s=read_mda('2idd_0087.mda')
;   IDL> status=s->getData(p, d, scan=2, /all)
;   IDL> print, p[0].description, '  ', p[1].description
;      PM500_X  PM500_Y
;   IDL> help, d
;      D     STRUCT    = -> EPICS_SSCANDETECTOR Array[47]
;   IDL> status=s->getData(p, d, scan=2, detector=10, /ytotal, yrange=[10,20])
;   IDL> help, *d.pData
;      <PtrHeapVar74409> FLOAT     = Array[41]
;
; MODIFICATION HISTORY:
;   Written by:  Mark Rivers, Nov. 8, 2003
;-
   if (n_elements(scan) eq 0) then scan=self.fileHeader.rank
   if ((scan lt 1) or (scan gt self.fileHeader.rank)) then begin
      message, 'Invalid scan'
      return, -1
   endif
   d = self->getDetector(scan=scan, detector=detector, all=all, /copy)
   if (size(d, /tname) ne 'STRUCT') then return, -1
   n_detectors = n_elements(d)
   data_rank = size(*d[0].pData, /n_dimensions)
   dims = size(*d[0].pData, /dimensions)
   p = replicate({epics_sscanPositioner}, data_rank)
   case n_elements(positioner) of
      0: begin
            pos = replicate(1, data_rank)
         end
      1: begin
            pos = replicate(1, data_rank)
            pos[0] = positioner
         end
      data_rank: begin
            pos = positioner
         end
      else: begin
            message, 'Wrong dimensions on positioner'
            return, -1
         end
   endcase
   for i=0L, data_rank-1 do begin
      temp = self->getPositioner(scan=scan-i, positioner=pos[i], /copy)
      if (size(temp, /tname) ne 'STRUCT') then return, -1
      p[i] = temp
   endfor
   ; Need to make a copy of the data so we don't modify original data in self
   ; Process the [z,y,z]range keywords
   if ((data_rank ge 3) and (n_elements(zrange) ne 0)) then begin
      if (n_elements(zrange) eq 1) then begin
         zrange = [zrange, zrange]
         dims[2] = 1
      endif else dims[2] = zrange[1]-zrange[0]+1
      *p[2].pData = (*p[2].pData)[zrange[0]:zrange[1]]
      for i=0L, n_detectors-1 do begin
         *d[i].pData = reform((*d[i].pData)[*,*,zrange[0]:zrange[1]], dims)
      endfor
   endif
   if ((data_rank ge 2) and (n_elements(yrange) ne 0)) then begin
      if (n_elements(yrange) eq 1) then begin
         yrange = [yrange, yrange]
         dims[1] = 1
      endif else dims[1] = yrange[1]-yrange[0]+1
      *p[1].pData = (*p[1].pData)[yrange[0]:yrange[1]]
      for i=0L, n_detectors-1 do begin
         *d[i].pData = reform((*d[i].pData)[*,yrange[0]:yrange[1],*], dims)
      endfor
   endif
   if (n_elements(xrange) ne 0) then begin
      if (n_elements(xrange) eq 1) then begin
         xrange = [xrange, xrange]
         dims[0] = 1
      endif else dims[0] = xrange[1]-xrange[0]+1
      *p[0].pData = (*p[0].pData)[xrange[0]:xrange[1]]
      for i=0L, n_detectors-1 do begin
         *d[i].pData = reform((*d[i].pData)[xrange[0]:xrange[1],*,*], dims)
      endfor
   endif
   ; Process the [x,y,z]total keywords
   if ((data_rank gt 2) and (keyword_set(ztotal))) then begin
      dims[2] = 1
      for i=0L, n_detectors-1 do *d[i].pData = total(*d[i].pData, 3)
   endif
   if ((data_rank gt 1) and (keyword_set(ytotal))) then begin
      dims[1] = 1
      for i=0L, n_detectors-1 do *d[i].pData = total(*d[i].pData, 2)
   endif
   if (keyword_set(xtotal)) then begin
      dims[0] = 1
      for i=0L, n_detectors-1 do *d[i].pData = total(*d[i].pData, 1)
   endif
   ; Eliminate any redundant dimensions
   for i=0L, n_detectors-1 do *d[i].pData = reform(*d[i].pData, /overwrite)
   ; Return array of valid positioners
   valid_dims = where((dims gt 1), count)
   if (count le 0) then return, -1
   p = p(valid_dims)
end


pro epics_sscan::display, scan=scan, positioner=positioner, detector=detector, all=all, $
                          xrange=xrange, yrange=yrange, zrange=zrange, $
                          xtotal=xtotal, ytotal=ytotal, ztotal=ztotal, $
                          grid=grid, overplot=overplot, $
                          image=image, surface=surface, contour=contour, $
                          _extra=extra
;+
; NAME:
;   epics_sscan::display
;
; PURPOSE:
;   This procedure displays scan data using the IDL iTools.
;
;   If the resulting data (after application of any keywords) is 1-D, then
;   an iPlot tool is created or modified.
;
;   If the resulting data is 2-d then an iImage tool is created.  This
;   display can be interactively modified to display contours and/or
;   surfaces.
;
; CATEGORY:
;   EPICS scanning tools.
;
; CALLING SEQUENCE:
;   scan->display
;
; KEYWORD PARAMETERS:
;   SCAN:
;      The scan to display.
;      Default is the innermost scan in this scan object.
;      Passed to epics_sscan::getData().
;
;   POSITIONER:
;      The number of the positioner to display.
;      Passed to epics_sscan::getData().
;
;   DETECTOR:
;      The number of the detector(s) to display.
;      Passed to epics_sscan::getData().
;
;   ALL:
;      Set this flag to display all of the detectors for this
;      scan. Passed to epics_sscan::getData()
;
;   [X,Y,Z]RANGE:
;      Used this keyword to restrict the range of array elements display in
;      the X, Y, or Z dimensions.  Passed to epics_sscan::getData()
;
;   [X,Y,Z]TOTAL:
;      Set this flag to sum over the array elements in the X, Y, or Z
;      dimensions.  Passed to epics_sscan::getData()
;
;   GRID:
;      Set this flag to display multiple detectors in separate dataspaces
;      within this iTool, layed out in a grid format.
;
;      If this keyword is not specified, and there are multiple detectors
;      selected then the iTool /OVERPLOT keyword is used.  For 1-D data this
;      results in multiple traces on the same plot, which each done in a
;      different color and plot symbol.  For 2-D data the images are plotted
;      on top of one another.  To browse through the images use the right mouse
;      button in the image or Visualization Browser to change this display
;      order (Send to Back, etc.).
;
;   IMAGE:
;      Set this flag to display 2-D data with iImage.  This is the default.
;
;   SURFACE:
;      Set this flag to display 2-D data with iSurface.
;
;   CONTOUR:
;      Set this flag to display 2-D data with iContour.
;
;   Other:
;      Any unrecognized keywords will be passed to the iPlot or iImage
;      procedures via the _EXTRA mechanism.  This allows one to specify,
;      for example, /VIEW_NEXT, to put the display in an existing iTool
;      rather than creating a new one.
;
; RESTRICTIONS:
;    The display is currently limited to 1-D and 2-D data.  Slices or
;    sums of 3-D or 4-D data can be displayed in 1-D or 2-D using the
;    [X,Y,Z]RANGE and/or [X,Y,Z]TOTAL keywords.
;
;    A plot legend should be automatically created for 1-D data with
;    multiple detectors.  I don't know how to do this yet.  However, it
;    is easy to manually create a legend: click in the dataspace (away
;    from any curves) and then use Insert/Legend from the menu.
;
;    An image title should be automatically placed above each image.
;    I don't know how to do this yet.  Titles can be added manually with
;    the annotation tools.
;
; EXAMPLE:
;   IDL> s=read_mda('2idd_0087.mda')
;   IDL> s->display               ; Displays the first detector in scan2
;   IDL> s->display, /all, /grid  ; Note this takes a minute or so, since
;                                 ; 47 images are created in one iTool
;   IDL> s->display, detector=10, /ytotal ; 1-D plot of sum over all rows
;   IDL> s->display, scan=1, /view_next ; Plot of outer scan, same window
;
; MODIFICATION HISTORY:
;   Written by:  Mark Rivers, Nov. 8, 2003
;-

   ; For now we need to remember the range from one call to the next
   common epics_sscan_display_common, ymin, ymax

   image = 1
   if (keyword_set(overplot)) then new_plot=0 else new_plot=1
   if (keyword_set(surface) or keyword_set(contour)) then image=0
   status = self->getData(p, d, scan=scan, detector=detector, all=all, positioner=positioner, $
                         xrange=xrange, yrange=yrange, zrange=zrange, $
                         xtotal=xtotal, ytotal=ytotal, ztotal=ztotal)
   if (status ne 0) then return
   n_detectors = n_elements(d)
   overplot = 1
   if ((keyword_set(grid)) and (n_detectors gt 0)) then begin
      ny = fix(sqrt(n_detectors))
      nx = n_detectors/ny
      if (nx*ny lt n_detectors) then nx = nx + 1
      view_grid = [nx, ny]
      view_next = 1
      overplot = 0
   endif
   if ((n_detectors > 4) and (overplot eq 0)) then tickfont_size=7 else tickfont_size=10
   data_rank = size(*d[0].pData, /n_dimensions)
   x = *p[0].pData
   xtitle = p[0].description + ' ' + p[0].units
   if (strlen(p[0].name) gt 0) then xtitle = xtitle + ' ('+p[0].name+')'
   if (data_rank gt 1) then begin
      ; Get the data and title for the previous ("slow") positioner for 2-D data
      slow_data = *p[1].pData
      slow_title = p[1].description + ' ' + p[1].units
      if (strlen(p[1].name) gt 0) then slow_title = slow_title + ' ('+p[1].name+')'
      if (keyword_set(image)) then begin
         ; This data must be evenly spaced for it to work with iimage.  The following should not change
         ; the array, but it might if the axis step size is not uniform
         xstep = x[1] - x[0]
         if (xstep eq 0) then xstep=1.
         x = x[0] + findgen(n_elements(x)) * xstep
         ; iimage has a very bad feature.  It won't accept decreasing steps, so change the sign for now
         if (xstep lt 0) then x = -x
         ystep = slow_data[1] - slow_data[0]
         if (ystep eq 0) then ystep=1.
         slow_data = slow_data[0] + findgen(n_elements(slow_data)) * ystep
         if (ystep lt 0) then slow_data = -slow_data
         ; iimage has another bad feature.  It scales the pixel sizes to the data dimensions, which is simply
         ; not correct.  For now we work around this by not passing the data coordinates if there is a large
         ; aspect ratio
         hide_iimage_axes = ((abs(xstep/ystep) lt 0.25) or (abs(xstep/ystep) gt 4))
      endif
   endif

   for i=0L, n_detectors-1 do begin
      if (overplot) then begin
         color = self->getColor(i)
         sym_index = i+1
      endif else begin
         color = self->getColor(0)
         sym_index = 1
      endelse
      description = d[i].description
      if (strlen(description) gt 0) then name=description else name=d[i].name
      if ((n_detectors eq 1) or (keyword_set(grid))) then ytitle=name else ytitle=''
      if (new_plot and (i eq 0)) then begin
         case data_rank of
         1: begin
               ; Get the min and max of first data set so we can adjust
               ymin = min(*d[0].pData, max=ymax)
               yspan = ymax-ymin
               if (yspan eq 0) then yspan=10
               yrange = [ymin-.1*yspan, ymax+.1*yspan]
               iplot, x, *d[i].pData, _extra=extra, $
                  yrange=yrange, $
                  ytitle=ytitle, xtitle=xtitle, $
                  title=self.fileHeader.fileName, $
                  name=name, view_grid=view_grid, $
                  sym_index=sym_index, color=color, $
                  xtickfont_size=tickfont_size, ytickfont_size=tickfont_size
            end
         2: begin
               if (keyword_set(image)) then begin
                  if (hide_iimage_axes) then begin
                     iimage, *d[i].pData, _extra=extra, $
                        ytitle=slow_title, xtitle=xtitle, $
                        title=self.fileHeader.fileName, $
                        name=name, view_grid=view_grid, $
                        xtickfont_size=tickfont_size, ytickfont_size=tickfont_size
                  endif else begin
                     iimage, *d[i].pData, x, slow_data, _extra=extra, $
                        ytitle=slow_title, xtitle=xtitle, $
                        title=self.fileHeader.fileName, $
                        name=name, view_grid=view_grid, $
                        xtickfont_size=tickfont_size, ytickfont_size=tickfont_size
                  endelse
               endif
               if (keyword_set(surface)) then $
                  isurface, *d[i].pData, x, slow_data, _extra=extra, $
                     ytitle=slow_title, xtitle=xtitle, $
                     title=self.fileHeader.fileName, $
                     name=name, view_grid=view_grid, $
                     xtickfont_size=tickfont_size, ytickfont_size=tickfont_size
               if (keyword_set(contour)) then $
                  icontour, *d[i].pData, x, slow_data, _extra=extra, $
                     ytitle=slow_title, xtitle=xtitle, $
                     title=self.fileHeader.fileName, $
                     name=name, view_grid=view_grid, $
                     xtickfont_size=tickfont_size, ytickfont_size=tickfont_size
            end
         else: begin
               message, 'Only rank 1-2 supported for now'
            end
         endcase
      endif else begin
         case data_rank of
         1: begin
               ; Get the min and max of this data set so we can adjust
               ymin1=min(*d[i].pData, max=ymax1)
               if (overplot) then begin
                  ymin = ymin < ymin1 & ymax = ymax > ymax1
               endif else begin
                  ymin = ymin1        & ymax = ymax1
               endelse
               yspan = ymax-ymin
               if (yspan eq 0) then yspan=10
               yrange= [ymin-.1*yspan, ymax+.1*yspan]
               iplot, x, *d[i].pData, view_next=view_next, overplot=overplot, $
                  yrange=yrange, $
                  ytitle=ytitle, xtitle=xtitle, $
                  name=name, sym_index=sym_index, $
                  color=color,_extra=extra, $
                  xtickfont_size=tickfont_size, ytickfont_size=tickfont_size
            end
         2: begin
               if (keyword_set(image)) then begin
                  if (hide_iimage_axes) then begin
                     iimage, *d[i].pData, _extra=extra, $
                        ytitle=slow_title, xtitle=xtitle, $
                        title=self.fileHeader.fileName, $
                        name=name, view_grid=view_grid, $
                        xtickfont_size=tickfont_size, ytickfont_size=tickfont_size
                  endif else begin
                     iimage, *d[i].pData, x, slow_data, $
                        ytitle=slow_title, xtitle=xtitle, $
                        view_next=view_next, overplot=overplot, $
                        name=name, _extra=extra, $
                        xtickfont_size=tickfont_size, ytickfont_size=tickfont_size
                  endelse
               endif
               if (keyword_set(surface)) then $
                  isurface, *d[i].pData, x, slow_data, $
                     ytitle=slow_title, xtitle=xtitle, $
                     view_next=view_next, overplot=overplot, $
                     name=name, _extra=extra, $
                     xtickfont_size=tickfont_size, ytickfont_size=tickfont_size
               if (keyword_set(contour)) then $
                  icontour, *d[i].pData, x, slow_data, $
                     ytitle=slow_title, xtitle=xtitle, $
                     view_next=view_next, overplot=overplot, $
                     name=name, _extra=extra, $
                     xtickfont_size=tickfont_size, ytickfont_size=tickfont_size
            end
         else: begin
               message, 'Only rank 1-2 supported for now'
            end
         endcase
      endelse
   endfor
end


pro epics_sscan::print, positioners=positioners, detectors=detectors, $
                      extraPVs=extraPVs, all=all, output=output, display=display
;+
; NAME:
;   epics_sscan::print
;
; PURPOSE:
;   This procedure converts scan data to ASCII format.  It can be saved
;   in a file, and/or displayed in a text window.  The default is to print
;   only header information to a temporary file, and then display that file
;   in a window using the IDL XDISPLAYFILE procedure.  Keywords can be used
;   to control what information is output, the name of the output file, and
;   whether the file is displayed.
;
; CATEGORY:
;   EPICS scanning tools.
;
; CALLING SEQUENCE:
;   scan->print
;
; KEYWORD PARAMETERS:
;
;   POSITIONER:
;      Set this flag to output the positioner data.
;
;   DETECTOR:
;      Set this flag to output the detector data.
;
;   EXTRAPVS:
;      Set this flag to output the extra PV data.
;
;   ALL:
;      Equivalent to /POSITIONERS, /DETECTORS, /EXTRAPVS
;
;   OUTPUT:
;      Set this keyword to the name of an output to write the ASCII
;      data to.  Don't forget to use /ALL if you want to dump the entire
;      scan.
;
;   DISPLAY:
;      Set this flag to display the output file in a window using XDISPLAYFILE.
;      The default is DISPLAY=1 if the OUTPUT keyword is not specified, and
;      DISPLAY=0 if the output keyword is specified.
;
; EXAMPLE:
;   IDL> s=read_mda('2idd_0087.mda')
;   IDL> s->print           ; Display the header information to a window
;   IDL> s->print, /all     ; Display everything to a window
;   IDL> s->print, /all, output='2idd_0087.ASCII'
;
; MODIFICATION HISTORY:
;   Written by:  Mark Rivers, Nov. 8, 2003
;-
   if (keyword_set(all)) then begin
      positioner=1
      detector=1
      extraPVs=1
   endif
   file=1
   if (n_elements(output) eq 0) then file=0
   if (n_elements(output) gt 0) then if (strlen(output) eq 0) then file=0
   if (file eq 0) then begin
      tmpdir = getenv('IDL_TMPDIR')
      output = tmpdir+'epics_sscan.tmp'
      if (n_elements(display) eq 0) then display=1
   endif else begin
      if (n_elements(display) eq 0) then display=0
   endelse
   openw, lun, /get, output
   printf, lun, 'File name:  ', self.fileHeader.fileName
   printf, lun, 'Version:    ', self.fileHeader.version
   printf, lun, 'Dimensions: ', self->formatDimensions(*self.fileHeader.pDims)
   for i=0L, self.fileHeader.rank-1 do begin
      printf, lun
      sh = (*self.fileHeader.pScanHeader)[i]
      printf, lun, 'Scan:             ', i+1
      printf, lun, '   Num. points:      ', sh.npts
      printf, lun, '   Last point:       ', sh.cpt
      printf, lun, '   Name:             ', sh.name
      printf, lun, '   Time stamp:       ', sh.timeStamp
      printf, lun, '   Num. positioners: ', sh.numPositioners
      printf, lun, '   Num. detectors:   ', sh.numDetectors
      printf, lun, '   Num. triggers:    ', sh.numTriggers
      if (1) then begin
         for j=0L, sh.numPositioners-1 do begin
            p = (*sh.pPositioners)[j]
            printf, lun, '   Positioner: ', j+1
            printf, lun, '      Name:        ', p.name
            printf, lun, '      Description: ', p.description
            printf, lun, '      Step mode:   ', p.stepMode
            printf, lun, '      Units:       ', p.units
            printf, lun, '      Readback:   ', j+1
            printf, lun, '         Name:         ', p.readbackName
            printf, lun, '         Description:  ', p.readbackDescription
            printf, lun, '         Units:        ', p.readbackDescription
            data = *p.pData
            dims = size(data, /dimensions)
            printf, lun, '      Dimensions: '+self->formatDimensions(dims)
            if (keyword_set(positioners)) then begin
               printf, lun, '      Data:'
               printf, lun, data
            endif
         endfor
         for j=0L, sh.numTriggers-1 do begin
            t = (*sh.pTriggers)[j]
            printf, lun, '   Trigger: ', j+1
            printf, lun, '      Name:    ', t.name
            printf, lun, '      Command: ', t.command
         endfor
         for j=0L, sh.numDetectors-1 do begin
            d = (*sh.pDetectors)[j]
            printf, lun, '   Detector: ', j+1
            printf, lun, '      Name:        ', d.name
            printf, lun, '      Description: ', d.description
            printf, lun, '      Units:       ', d.units
            data = *d.pData
            dims = size(data, /dimensions)
            printf, lun, '      Dimensions: '+self->formatDimensions(dims)
            if (keyword_set(detectors)) then begin
               printf, lun, '      Data:'
               printf, lun, data
            endif
         endfor
      endif
   endfor
   if (keyword_set(extraPVs)) then begin
      printf, lun
      printf, lun, 'Num. Extra PVs:', self.fileHeader.numExtra
      ; We need the following conditional for reading incomplete scan files
      if (self.extraPointer gt 0) then begin
         for j=0L, self.fileHeader.numExtra-1 do begin
            e = (*self.fileHeader.pExtraPVs)[j]
            printf, lun, '   Extra PV: ', j+1
            printf, lun, '      Name:        ', e.name
            printf, lun, '      Description: ', e.description
            printf, lun, '      Units:       ', e.units
            printf, lun, '      Value:       ', *e.pValue
         endfor
      endif
   endif
   free_lun, lun
   if (display) then xdisplayfile, output, title=self.fileHeader.fileName + ' ('+output+')', $
                                   font=get_font_name(/courier), $
                                   /edit, done='Exit'
end


pro epics_sscan::print_columns, scan=scan, positioner=positioner, detector=detector, $
                                xrange=xrange, yrange=yrange, zrange=zrange, $
                                xtotal=xtotal, ytotal=ytotal, ztotal=ztotal, $
                                delimiter=delimiter, output=output, display=display
;+
; NAME:
;   epics_sscan::print_columns
;
; PURPOSE:
;   This procedure converts scan data to ASCII column format.  epics_sscan::print
;   is intended mainly for human-readable display, while epics_sscan::print_column
;   is more suitable for exporting data to other programs, such as spreadsheets.
;
; CATEGORY:
;   EPICS scanning tools.
;
; CALLING SEQUENCE:
;   scan->print_columns
;
; KEYWORD PARAMETERS:
;
;   SCAN:
;      The scan to display.
;      Default is the innermost scan in this scan object.
;      Passed to epics_sscan::getData().
;
;   POSITIONER:
;      The number of the positioner to display.
;      Passed to epics_sscan::getData().
;
;   DETECTOR:
;      The number of the detector(s) to display.
;      Passed to epics_sscan::getData().
;
;   [X,Y,Z]RANGE:
;      Used this keyword to restrict the range of array elements display in
;      the X, Y, or Z dimensions.  Passed to epics_sscan::getData()
;
;   [X,Y,Z]TOTAL:
;      Set this flag to sum over the array elements in the X, Y, or Z
;      dimensions.  Passed to epics_sscan::getData()
;
;   DELIMITER:
;      The delimiter between fields in the output.  Default=' '.
;
;   OUTPUT:
;      Set this keyword to the name of an output to write the ASCII
;      column data to.
;
;   DISPLAY:
;      Set this flag to display the output file in a window using XDISPLAYFILE.
;      The default is DISPLAY=1 if the OUTPUT keyword is not specified, and
;      DISPLAY=0 if the output keyword is specified.
;
; EXAMPLE:
;   IDL> s=read_mda('2idd_0087.mda')
;   IDL> s->print_columns, scan=1, positioners=1     ; Display all detectors for the first scan.
;
; MODIFICATION HISTORY:
;   Written by:  Mark Rivers, Oct. 10, 2006
;-
   status = self->getData(p, d, scan=scan, detector=detector, positioner=positioner, $
                         xrange=xrange, yrange=yrange, zrange=zrange, $
                         xtotal=xtotal, ytotal=ytotal, ztotal=ztotal)
   if (status ne 0) then return

   file=1
   if (n_elements(delimiter) eq 0) then delimiter = ' '
   sh = (*self.fileHeader.pScanHeader)[scan-1]
   if (n_elements(output) eq 0) then file=0
   if (n_elements(output) gt 0) then if (strlen(output) eq 0) then file=0
   if (file eq 0) then begin
      tmpdir = getenv('IDL_TMPDIR')
      output = tmpdir+'epics_sscan.tmp'
      if (n_elements(display) eq 0) then display=1
   endif else begin
      if (n_elements(display) eq 0) then display=0
   endelse
   openw, lun, /get, output
   printf, lun, 'File name:' + delimiter + self.fileHeader.fileName
   printf, lun, 'Scan name:' + delimiter + sh.name
   dims = size(*d[0].pData, /dimensions)
   printf, lun, 'Dimensions:' + delimiter + self->formatDimensions(dims)

   n_detectors = n_elements(d)
   data_rank = size(*d[0].pData, /n_dimensions)
   x = *p[0].pData
   if (strlen(p[0].name) gt 0) then xtitle = p[0].name else xtitle='Fast'
   if (data_rank gt 1) then begin
      ; Get the data and title for the previous ("slow") positioner for 2-D data
      slow_data = *p[1].pData
      if (strlen(p[1].name) gt 0) then slow_title = p[1].name else slow_title = 'Slow'
   endif

   case data_rank of
   1: begin
      line = 'Index' + delimiter + p[0].name
      for j=0L, n_elements(d)-1 do begin
         line = line + delimiter + d[j].name
      endfor
      printf, lun, line
      for i=0L, n_elements(x)-1 do begin
         line = strtrim(i+1,2) + delimiter + strtrim(x[i],2)
         for j=0L, n_elements(d)-1 do begin
            line = line + delimiter + strtrim((*d[j].pData)[i], 2)
         endfor
         printf, lun, line
      endfor
   end

   2: begin
      line = 'Slow' + delimiter + 'Fast' + delimiter + slow_title + delimiter + xtitle
      for j=0L, n_elements(d)-1 do begin
         line = line + delimiter + d[j].name
      endfor
      printf, lun, line
      for i=0L, n_elements(slow_data)-1 do begin
         for j=0L, n_elements(x)-1 do begin
            line = strtrim(i+1,2) + delimiter + strtrim(j+1, 2) + delimiter + $
                   strtrim(slow_data[i], 2) + delimiter + strtrim(x[j],2)
            for k=0L, n_elements(d)-1 do begin
               line = line + delimiter + strtrim((*d[k].pData)[j,i], 2)
            endfor
            printf, lun, line
         endfor
      endfor
   end

   else: begin
      message, 'Only rank 1-2 supported for now'
      end
   endcase

   free_lun, lun
   if (display) then xdisplayfile, output, title=output, font=get_font_name(/courier), $
                                   /edit, done='Exit'
end


pro epics_sscan::readMDAExtraPVs
   lun = self.lun
   if (self.extraPointer le 0) then return
   point_lun, lun, self.extraPointer
   ; From db_access.h
   DBR_STRING = 0
   DBR_CTRL_STRING = 28
   DBR_CTRL_SHORT  = 29
   DBR_CTRL_INT    = DBR_CTRL_SHORT
   DBR_CTRL_FLOAT  = 30
   DBR_CTRL_ENUM   = 31
   DBR_CTRL_CHAR   = 32
   DBR_CTRL_LONG   = 33
   DBR_CTRL_DOUBLE = 34
   num_extra = 0L
   readu, lun, num_extra
   self.fileHeader.numExtra = num_extra
   if (num_extra le 0) then return
   extraPVs = replicate({epics_sscanExtraPV}, num_extra)
   for i=0L, num_extra-1 do begin
      name='' & description='' & type=0L
      readu, lun, name, description, type
      extraPVs[i].name = name
      extraPVs[i].description = description
      extraPVs[i].type = type
      if (type ne DBR_STRING) then begin
         count=0L & units=''
         readu, lun, count, units
         extraPVs[i].count = count
         extraPVs[i].units = units
      endif
      case type of
         DBR_STRING:      value = ''
         DBR_CTRL_STRING: value = bytarr(count)
         DBR_CTRL_SHORT:  value = 0S
         DBR_CTRL_LONG:   value = 0L
         DBR_CTRL_FLOAT:  value = 0.
         DBR_CTRL_DOUBLE: value = 0.D0
         else: begin
            message, 'Unknown data type in extraPV=', type
            value = ''
         end
      endcase
      readu, lun, value
      extraPVs[i].pValue = ptr_new(value, /no_copy)
   endfor
   self.fileHeader.pExtraPVs = ptr_new(extraPVs, /no_copy)
end


pro epics_sscan::readMDAScanHeader
   lun = self.lun
   rank=0S & npts=0L & cpt=0L
   readu, lun, rank, npts, cpt
   if (rank gt 1) then begin
      scanPointers = lonarr(npts)
      readu, lun, scanPointers
   endif
   scanName='' & timeStamp='' & numPositioners=0L & numDetectors=0L & numTriggers=0L
   readu, lun, scanName, timeStamp, numPositioners, numDetectors, numTriggers
   if (numPositioners gt 0) then begin
      positioners = replicate({epics_sscanPositioner}, numPositioners)
      number=0L & name='' & description='' & stepMode='' & units=''
      readbackName='' & readbackDescription='' & readbackUnits=''
      for i=0L, numPositioners-1 do begin
         readu, lun, number, name, description, stepMode, units, $
                     readbackName, readbackDescription, readbackUnits
         p = {epics_sscanPositioner}
         p.number=number & p.name=name & p.description=description & p.stepMode=stepMode
         p.units=units & p.readbackName=readbackName
         p.readbackDescription=readbackDescription &p.readbackUnits=readbackUnits
         positioners[i] = p
      endfor
   endif
   if (numDetectors gt 0) then begin
      detectors = replicate({epics_sscanDetector}, numDetectors)
      number=0L & name='' & description='' & units=''
      for i=0L, numDetectors-1 do begin
         readu, lun, number, name, description, units
         p = {epics_sscanDetector}
         p.number=number & p.name=name & p.description=description & p.units=units
         detectors[i] = p
      endfor
   endif
   if (numTriggers gt 0) then begin
      triggers = replicate({epics_sscanTrigger}, numTriggers)
      for i=0L, numTriggers-1 do begin
         p = {epics_sscanTrigger}
         readu, lun, p
         triggers[i] = p
      endfor
   endif
   if (numPositioners gt 0) then begin
      positionerData = dblarr(npts, numPositioners)
      readu, lun, positionerData
   endif
   if (numDetectors gt 0) then begin
      detectorData = fltarr(npts, numDetectors)
      readu, lun, detectorData
   endif

   index = self.fileHeader.rank - rank
   if ((*self.fileHeader.pScanHeader)[index].rank eq 0) then begin
      ; This is the first scan of this rank.  Copy information to the scanHeader
      scanHeader = {epics_sscanScanHeader}
      scanHeader.rank = rank
      scanHeader.npts = npts
      scanHeader.cpt  = cpt
      if (rank gt 1 ) then scanHeader.pScanPointers = ptr_new(scanPointers)
      scanHeader.name       = scanName
      scanHeader.timeStamp      = timeStamp
      scanHeader.numPositioners = numPositioners
      scanHeader.numDetectors   = numDetectors
      scanHeader.numTriggers    = numTriggers
      if (numPositioners gt 0) then begin
         scanHeader.pPositioners = ptr_new(positioners, /no_copy)
         for i=0L, numPositioners-1 do begin
            (*scanHeader.pPositioners)[i].pData = ptr_new(positionerData[*,i])
         endfor
      endif
      if (numDetectors gt 0) then begin
         scanHeader.pDetectors = ptr_new(detectors, /no_copy)
         dims = (*self.fileHeader.pDims)[0:index]
         dims = reverse(dims)
         data = fltarr(dims)
         for i=0L, numDetectors-1 do begin
            ; Create data arrays
            (*scanHeader.pDetectors)[i].pData = ptr_new(data)
         endfor
      endif
      if (numTriggers gt 0) then scanHeader.pTriggers = ptr_new(triggers, /no_copy)
      (*self.fileHeader.pScanHeader)[index] = scanHeader
   endif
   offset = (*self.pDataOffset)[index]
   for i=0L, numDetectors-1 do begin
      (*(*(*self.fileHeader.pScanHeader)[index].pDetectors)[i].pData)[offset] = detectorData[*,i]
   endfor
   (*self.pDataOffset)[index] += npts
   if (rank gt 1) then begin
      ; Call ourselves recursively for each scan inside this scan
      for i=0L, cpt-1 do begin
         self->readMDAScanHeader
      endfor
   endif
end


pro epics_sscan::readMDAFileHeader
   lun = self.lun
   version=0. & number=0L & rank=0S
   readu, lun, version, number, rank
   self.fileHeader.version = version
   self.fileHeader.number  = number
   self.fileHeader.rank    = rank
   self.fileHeader.pScanHeader = ptr_new(replicate({epics_sscanScanHeader}, rank))
   self.pDataOffset = ptr_new(lonarr(rank))
   dims = lonarr(rank)
   readu, lun, dims
   self.fileHeader.pDims = ptr_new(dims)
   isRegular=0L & extraPointer=0L
   readu, lun, isRegular, extraPointer
   self.fileHeader.isRegular    = isRegular
   self.extraPointer = extraPointer
end

pro epics_sscan::read_mda, filename
;+
; NAME:
;   epics_sscan::read_mda
;
; PURPOSE:
;   This procedure reads an MDA file into an epics_sscan object.
;
; CATEGORY:
;   EPICS scanning tools.
;
; CALLING SEQUENCE:
;   scan->read_mda, Filename
;
; INPUTS:
;   Filename:  The name of the MDA file to read.
;
; EXAMPLE:
;   IDL> s=obj_new('epics_sscan')
;   IDL> s->read_mda, '2idd_0087.mda'
;   IDL> s->display               ; Displays the first detector in scan2
;
; MODIFICATION HISTORY:
;   Written by:  Mark Rivers, Nov. 8, 2003
;-
   ; Free any existing pointers
   self->cleanup_ptrs
   openr, lun, /get, /xdr, filename
   self.lun = lun
   self->readMDAFileHeader
   self.fileHeader.fileName = filename
   self->readMDAScanHeader
   self->readMDAExtraPVs
   free_lun, lun
end


function epics_sscan::getFileHeader
;+
; NAME:
;   epics_sscan::getFileHeader
;
; PURPOSE:
;   This procedure returns a structure of type {epics_sscanFileHeader}.
;   Using this structure users can write IDL software to retrieve all of
;   the data from the epics_sscan object, and hence from an MDA file.
;
;   This structure contains pointers to an array of {epics_sscanScanHeader}
;   structures, which contain the headers and pointers to the data for each
;   scan (1 to rank).
;
; CATEGORY:
;   EPICS scanning tools.
;
; CALLING SEQUENCE:
;   fileHeader = scan->getFileHeader()
;
; EXAMPLE:
;   IDL> s=read_mda('2idd_0087.mda')
;   IDL> h=s->getFileHeader()
;   IDL> help, /structure, h
;   ** Structure EPICS_SSCANFILEHEADER, 9 tags, length=44, data length=42:
;      FILENAME        STRING    '2idd_0087.mda'
;      VERSION         FLOAT           1.30000
;      NUMBER          LONG                87
;      RANK            INT              2
;      PDIMS           POINTER   <PtrHeapVar4>
;      ISREGULAR       LONG                 1
;      NUMEXTRA        LONG                43
;      PSCANHEADER     POINTER   <PtrHeapVar2>
;      PEXTRAPVS       POINTER   <PtrHeapVar112>
;   IDL>  print, 'dims=', *h.pDims
;      dims=          41          41
;   IDL>  help, /structure, (*h.pScanHeader)[0]
;   ** Structure EPICS_SSCANSCANHEADER, 12 tags, length=64, data length=62:
;      RANK            INT              2
;      NPTS            LONG                41
;      CPT             LONG                41
;      PSCANPOINTERS   POINTER   <PtrHeapVar5>
;      NAME            STRING    '2idd:scan2'
;      TIMESTAMP       STRING    'Jun 19, 2003 23:59:05.085430051'
;      NUMPOSITIONERS  LONG                 1
;      NUMDETECTORS    LONG                 8
;      NUMTRIGGERS     LONG                 1
;      PPOSITIONERS    POINTER   <PtrHeapVar6>
;      PDETECTORS      POINTER   <PtrHeapVar8>
;      PTRIGGERS       POINTER   <PtrHeapVar17>
;
; MODIFICATION HISTORY:
;   Written by:  Mark Rivers, Nov. 8, 2003
;-
   return, self.fileHeader
end


function epics_sscan::init
   ; This routine would do any initialization.  None is needed yet.
   return, 1
end

pro epics_sscan::cleanup
   self->cleanup_ptrs
end

pro epics_sscan::cleanup_ptrs
   ; This routine cleans up by freeing pointers
   ptr_free, self.fileHeader.pDims
   if (ptr_valid(self.fileHeader.pExtraPVs)) then begin
      for i=0L, n_elements(*self.fileHeader.pExtraPVs)-1 do begin
         ptr_free, (*self.fileHeader.pExtraPVs)[i].pValue
      endfor
   endif
   ptr_free, self.fileHeader.pExtraPVs
   if (ptr_valid(self.fileHeader.pScanHeader)) then begin
      for i=0L, n_elements(*self.fileHeader.pScanHeader)-1 do begin
         sh = (*self.fileHeader.pScanHeader)[i]
         ptr_free, sh.pScanPointers
         if (ptr_valid(sh.pPositioners)) then begin
            for j=0L, n_elements(*sh.pPositioners)-1 do begin
               ptr_free, (*sh.pPositioners)[j].pData
            endfor
         endif
         ptr_free, sh.pPositioners
         if (ptr_valid(sh.pDetectors)) then begin
            for j=0L, n_elements(*sh.pDetectors)-1 do begin
               ptr_free, (*sh.pDetectors)[j].pData
            endfor
         endif
         ptr_free, sh.pDetectors
         ptr_free, sh.pTriggers
      endfor
   endif
   ptr_free, self.fileHeader.pScanHeader
   ptr_free, self.pDataOffset
end


pro epics_sscan__define
;+
; NAME:
;   epics_sscan__define
;
; PURPOSE:
;   This procedure defines the EPICS_SSCAN class.
;   The EPICS_SSCAN class is designed to do the following:
;   - Provide an object-oriented interface to standard EPICS scans, enabling
;     user written software to easily access scan header information and data.
;   - Provide an easy way to read MDA files written by the saveData function
;     in synApps.
;   - Provide an easy way to get scan data into the IDL iTools system.
;     iTools provide easy to use interfaces for visualizing data, zooming
;     in, adding annotation, and producing publication quality plots.
;   - Provide a way to convert binary scan files (e.g. MDA) into ASCII
;
;   The initial implementation of EPICS_SSCAN only reads MDA files.
;   Future enhancements may add a channel-access interface for reading scans
;   from the IOC directly.  Additional file readers (e.g. Nexus) may be
;   added.
;
; CATEGORY:
;   EPICS scanning tools.
;
; CALLING SEQUENCE:
;   This routine cannot be called directly.  It is called indirectly as follows:
;   scan = OBJ_NEW('EPICS_SSCAN')
;
; DATA STRUCTURES:
;   This class defines a number of IDL structure types to store the scan
;   information.  These structures map closely to the structure of EPICS scans
;   and MDA data files.  However, they are not limited to MDA files, they could
;   be used to contain data from any EPICS scan.
;
;   The fields described below for these structures are guaranteed to be
;   present.  More fields may be added in the future as the EPICS_SSCAN
;   class is enhanced.
;
;   The top-level data structure is the {epics_sscanFileHeader}.  There is
;   only one of these structures in an EPICS_SSCAN object.  It can be returned
;   with the epics_sscan::getFileHeader method.  With this structure all of
;   the information in the scan can be retrieved.
;   This structure is defined as follows:
;      {epics_sscanFileHeader, $   ; Defines the overall scan data set
;       fileName:     '', $        ; Contains name of file read with ::read_mda
;       version:      0., $        ; File version.  1.3 for current files.
;       number:       0L, $        ; Scan number
;       rank:         0S, $        ; Rank of outermost scan (1 for 1-D, 2 for 2-D, etc.)
;       pDims:        ptr_new(), $ ; Pointer to array of scan dimensions
;       isRegular:    0L, $        ; Don't know what this means yet
;       numExtra:     0L, $        ; Number of extra PVs
;       pScanHeader:  ptr_new(), $ ; Pointer to array of {epics_sscanScanHeader} structures
;                                  ; Array dimensions = "rank"
;       pExtraPVs:    ptr_new() $  ; Pointer to array of {epics_sscanExtraPV} structures
;                                  ; Array dimensions = "numExtra"
;   }
;
;   The next structure is the {epics_sscanScanHeader}.  It describes a
;   single scan. {epics_sscanFileHeader} points to an array of these.
;   This structure is defined as follows:
;      {epics_sscanScanHeader, $     ; Defines a single scan.
;       rank:           0S, $        ; Rank of this scan (1 for 1-D, 2 for 2-D, etc.)
;       npts:           0L, $        ; Number of points in this scan
;       cpt:            0L, $        ; Current point.  Less than npts if scan is incomplete.
;       pScanPointers:  ptr_new(), $ ; Pointers to offsets in file where scans start.
;       name:           '', $        ; Name of this scan.  This seems wrong in MDA files.
;       timeStamp:      '', $        ; Time when scan completed
;       numPositioners: 0L, $        ; Number of positioners
;       numDetectors:   0L, $        ; Number of detectors
;       numTriggers:    0L, $        ; Number of detector triggers
;       pPositioners:   ptr_new(), $ ; Pointer to array of {epics_sscanPositioner}
;                                    ; Array dimensions = "numPositioners"
;       pDetectors:     ptr_new(), $ ; Pointer to array of {epics_sscanDetector}
;                                    ; Array dimensions = "numDetectors"
;       pTriggers:      ptr_new()  $ ; Pointer to array of {epics_sscanTrigger}
;                                    ; Array dimensions = "numTriggers"
;   }
;
;   The next structure is the {epics_sscanScanPositioner}.  It describes a
;   single positioner. {epics_sscanScanHeader} points to an array of these.
;   This structure is defined as follows:
;      {epics_sscanPositioner, $     ; Defines a positioner
;       number:              0L, $   ; Index number
;       name:                '', $   ; PV name
;       description:         '', $   ; Description string
;       stepMode:            '', $   ; Step mode (LINEAR, TABLE, etc.)
;       units:               '', $   ; Units string
;       readbackName:        '', $   ; PV name of readback
;       readbackDescription: '', $   ; Readback description
;       readbackUnits:       '', $   ; Readback units
;       pData:               ptr_new() $ ; Pointer to positioner data array.
;                                    ; Array type=DOUBLE
;                                    ; Array dimensions = "npts" for this scan
;   }
;
;   The next structure is the {epics_sscanScanDetector}.  It describes a
;   single detector. {epics_sscanScanHeader} points to an array of these.
;   This structure is defined as follows:
;      {epics_sscanDetector, $       ; Defines a detector
;       number:      0L, $           ; Index number
;       name:        '', $           ; PV name
;       description: '', $           ; Description string
;       units:       '', $           ; Units string
;       pData:       ptr_new() $     ; Pointer to detector data
;                                    ; Array type=FLOAT
;                                    ; Array dimensions=(N, M, ...) where N
;                                    ; is npts for this scan, M is npts for
;                                    ; next outer scan, etc.
;   }
;
;   The next structure is the {epics_sscanScanTrigger}.  It describes a
;   single detector trigger. {epics_sscanScanHeader} points to an array of these.
;   This structure is defined as follows:
;   scanTrigger = $
;      {epics_sscanTrigger, $        ; Defines a scan trigger
;       number:  0L, $               ; Index number
;       name:    '', $               ; PV name
;       command: 0. $                ; Command value written to PV to trigger
;   }
;
;   The final structure is the {epics_sscanScanExtraPV}.  It describes a
;   single extra PV. {epics_sscanFileHeader} points to an array of these.
;   This structure is defined as follows:
;   extraPV = $
;      {epics_sscanExtraPV, $        ; Defines an "extra" PV stored with scan
;       name:        '', $           ; PV name
;       description: '', $           ; Description string
;       type:        0L, $           ; Data type (see db_access.h for defs)
;       count:       0L, $           ; Number of values
;       units:       '', $           ; Units string
;       pValue:      ptr_new() $     ; Pointer to value
;   }
;
; EXAMPLE:
;   IDL> s=obj_new('epics_sscan')
;   IDL> s->read_mda, '2idd_0087.mda'
;   IDL> h=s->getFileHeader()
;
; MODIFICATION HISTORY:
;   Written by:  Mark Rivers, Nov. 8, 2003
;-

   fileHeader = $
      {epics_sscanFileHeader, $   ; Defines the overall scan data set
       fileName:     '', $        ; Contains name of file read with ::read_mda
       version:      0., $        ; File version.  1.3 for current files.
       number:       0L, $        ; Scan number
       rank:         0S, $        ; Rank of outermost scan (1 for 1-D, 2 for 2-D, etc.)
       pDims:        ptr_new(), $ ; Pointer to array of scan dimensions
       isRegular:    0L, $        ; Don't know what this means yet
       numExtra:     0L, $        ; Number of extra PVs
       pScanHeader:  ptr_new(), $ ; Pointer to array of {epics_sscanScanHeader} structures
                                  ; Array dimensions = "rank"
       pExtraPVs:    ptr_new() $  ; Pointer to array of {epics_sscanExtraPV} structures
                                  ; Array dimensions = "numExtra"
   }


   scanHeader = $
      {epics_sscanScanHeader, $     ; Defines a single scan.
       rank:           0S, $        ; Rank of this scan (1 for 1-D, 2 for 2-D, etc.)
       npts:           0L, $        ; Number of points in this scan
       cpt:            0L, $        ; Current point.  <npts if scan is incomplete.
       pScanPointers:  ptr_new(), $ ; Pointers to offsets in file where scans start.
       name:           '', $        ; Name of this scan.  This seems wrong in MDA files.
       timeStamp:      '', $        ; Time when scan completed
       numPositioners: 0L, $        ; Number of positioners
       numDetectors:   0L, $        ; Number of detectors
       numTriggers:    0L, $        ; Number of detector triggers
       pPositioners:   ptr_new(), $ ; Pointer to array of {epics_sscanPositioner}
                                    ; Array dimensions = "numPositioners"
       pDetectors:     ptr_new(), $ ; Pointer to array of {epics_sscanDetector}
                                    ; Array dimensions = "numDetectors"
       pTriggers:      ptr_new()  $ ; Pointer to array of {epics_sscanTrigger}
                                    ; Array dimensions = "numTriggers"
   }

   scanPositioner = $
      {epics_sscanPositioner, $     ; Defines a positioner
       number:              0L, $   ; Index number
       name:                '', $   ; PV name
       description:         '', $   ; Description string
       stepMode:            '', $   ; Step mode (LINEAR, TABLE, etc.)
       units:               '', $   ; Units string
       readbackName:        '', $   ; PV name of readback
       readbackDescription: '', $   ; Readback description
       readbackUnits:       '', $   ; Readback units
       pData:               ptr_new() $ ; Pointer to positioner data array.
                                    ; Array type=DOUBLE
                                    ; Array dimensions = "npts" for this scan
   }

   scanDetector = $
      {epics_sscanDetector, $       ; Defines a detector
       number:      0L, $           ; Index number
       name:        '', $           ; PV name
       description: '', $           ; Description string
       units:       '', $           ; Units string
       pData:       ptr_new() $     ; Pointer to detector data
                                    ; Array type=FLOAT
                                    ; Array dimensions=(N, M, ...) where N
                                    ; is npts for this scan, M is npts for
                                    ; next outer scan, etc.
   }

   scanTrigger = $
      {epics_sscanTrigger, $        ; Defines a scan trigger
       number:  0L, $               ; Index number
       name:    '', $               ; PV name
       command: 0. $                ; Command value written to PV to trigger
   }

   extraPV = $
      {epics_sscanExtraPV, $        ; Defines an "extra" PV stored with scan
       name:        '', $           ; PV name
       description: '', $           ; Description string
       type:        0L, $           ; Data type (see dbAccess.h for defs)
       count:       0L, $           ; Number of values
       units:       '', $           ; Units string
       pValue:      ptr_new() $     ; Pointer to value
   }

   epics_sscan =  $
      {epics_sscan, $
       lun:            0L, $
       pDataOffset:    ptr_new(), $
       extraPointer:   0L, $
       fileHeader:     fileHeader $
   }
end
