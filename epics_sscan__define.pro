function epics_sscan::formatDimensions, dimensions
   dim_string = '['
   ndims = n_elements(dimensions)
   for idim=0, ndims-2 do begin
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


pro epics_sscan::display, scan=scan, positioner=positioner, detector=detector, $
                        all=all, grid=grid, z_slice=z_slice, _extra=extra
   if (n_elements(scan) eq 0) then scan=self.fileHeader.rank
   if (n_elements(z_slice) eq 0) then z_slice=0
   scan = (scan>1) < self.fileHeader.rank
   if (n_elements(positioner) eq 0) then positioner=1
   sh = (*self.scanHeader)[scan-1]
   if (sh.numDetectors lt 1) then begin
      print, 'No detectors, nothing to display!'
     return  ; Nothing to display
   endif
   positioner = (positioner>1) < sh.numPositioners
   if (positioner gt 0) then begin
      p = (*sh.positioners)[positioner-1]
   endif else begin
      p = {epics_sscanPositioner}
      p.data = ptr_new(findgen(sh.npts))
   endelse
   if (n_elements(detector) eq 0) then detector=1
   detector = (detector>1) < sh.numDetectors
   if (keyword_set(all)) then begin
      d = *sh.detectors
   endif else begin
      d = (*sh.detectors)[detector-1]
   endelse
   n_detectors = n_elements(d)
   data = *d[0].data
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
   data_rank = size(data, /n_dimensions)
   if (data_rank gt 1) then begin
      ; Get the data and title for the previous ("slow") positioner for 2-D data
      slow_sh = (*self.scanHeader)[scan-2]
      if (slow_sh.numPositioners gt 0) then begin
         slow_p = (*slow_sh.positioners)[0]
      endif else begin
         slow_p = {epics_sscanPositioner}
         slow_p.data = ptr_new(slow_sh.npts)
      endelse
      slow_data = *slow_p.data
      slow_title = slow_p.description + ' ' + slow_p.units + ' ('+slow_p.name+')'
   endif
   for i=0, n_detectors-1 do begin
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
      if (i eq 0) then begin
         x = *p.data
         xtitle = p.description + ' ' + p.units + ' ('+p.name+')'
        case data_rank of
         1: begin
               ; Get the min and max of this data set so we can adjust
               ymin = min(data, max=ymax)
               yspan = ymax-ymin
               if (yspan eq 0) then yspan=10
               yrange = [ymin-.1*yspan, ymax+.1*yspan]
               iplot, x, *d[i].data, _extra=extra, $
                  yrange=yrange, $
                  ytitle=ytitle, xtitle=xtitle, $
                  title=self.fileHeader.fileName, $
                  name=name, view_grid=view_grid, $
                  sym_index=sym_index, color=color, $
                  xtickfont_size=tickfont_size, ytickfont_size=tickfont_size
            end
         2: begin
               iimage, *d[i].data, x, slow_data, _extra=extra, $
                  ytitle=slow_title, xtitle=xtitle, $
                  title=self.fileHeader.fileName, $
                  name=name, view_grid=view_grid, $
                  xtickfont_size=tickfont_size, ytickfont_size=tickfont_size
            end
         3: begin
               data = reform((*d[i].data)[*,*,z_slice])
               iimage, data, x, slow_data, _extra=extra, $
                  ytitle=slow_title, xtitle=xtitle, $
                  title=self.fileHeader.fileName, $
                  name=name, view_grid=view_grid, $
                  xtickfont_size=tickfont_size, ytickfont_size=tickfont_size
            end
         else: begin
               print, 'Only rank 1-3 supported for now'
            end
         endcase
      endif else begin
         case data_rank of
         1: begin
               ; Get the min and max of this data set so we can adjust
               ymin1=min(*d[i].data, max=ymax1)
               if (overplot) then begin 
                  ymin = ymin < ymin1 & ymax = ymax > ymax1
               endif else begin
                  ymin = ymin1        & ymax = ymax1
               endelse
               yspan = ymax-ymin
               if (yspan eq 0) then yspan=10
               yrange= [ymin-.1*yspan, ymax+.1*yspan]
               iplot, x, *d[i].data, view_next=view_next, overplot=overplot, $
                  yrange=yrange, $
                  ytitle=ytitle, xtitle=xtitle, $
                  name=name, sym_index=sym_index, $
                  color=color,_extra=extra, $
                  xtickfont_size=tickfont_size, ytickfont_size=tickfont_size
            end
         2: begin
               iimage, *d[i].data, x, slow_data, $
                  ytitle=slow_title, xtitle=xtitle, $
                  view_next=view_next, overplot=overplot, $
                  name=name, _extra=extra, $
                  xtickfont_size=tickfont_size, ytickfont_size=tickfont_size
            end
         3: begin
               data = reform((*d[i].data)[*,*,z_slice])
               iimage, data, x, slow_data, $
                  ytitle=slow_title, xtitle=xtitle, $
                  view_next=view_next, overplot=overplot, name=name, $
                  _extra=extra, $
                  xtickfont_size=tickfont_size, ytickfont_size=tickfont_size
            end
         else: begin
               print, 'Only rank 1-3 supported for now'
            end
         endcase
      endelse
   endfor
end


pro epics_sscan::print, positioners=positioners, detectors=detectors, $
                      extraPVs=extraPVs, all=all, output=output
   if (keyword_set(all)) then begin
      positioners=1
      detectors=1
      extraPVs=1
   endif
   if (n_elements(output) eq 0) then begin
      tmpdir = getenv('IDL_TMPDIR')
      output = tmpdir+'epics_sscan.tmp'
   endif
   openw, lun, /get, output
   printf, lun, 'File name:  ', self.fileHeader.fileName
   printf, lun, 'Version:    ', self.fileHeader.version
   printf, lun, 'Dimensions: ', self->formatDimensions(*self.fileHeader.dims)
   for i=0, self.fileHeader.rank-1 do begin
      printf, lun
      sh = (*self.scanHeader)[i]
      printf, lun, 'Scan:             ', i+1
      printf, lun, '   Num. points:      ', sh.npts
      printf, lun, '   Last point:       ', sh.cpt
      printf, lun, '   Name:             ', sh.name
      printf, lun, '   Time stamp:       ', sh.timeStamp
      printf, lun, '   Num. positioners: ', sh.numPositioners
      printf, lun, '   Num. detectors:   ', sh.numDetectors
      printf, lun, '   Num. triggers:    ', sh.numTriggers
      if (1) then begin
         for j=0, sh.numPositioners-1 do begin
            p = (*sh.positioners)[j]
            printf, lun, '   Positioner: ', j+1
            printf, lun, '      Name:        ', p.name
            printf, lun, '      Description: ', p.description
            printf, lun, '      Step mode:   ', p.stepMode
            printf, lun, '      Units:       ', p.units
            printf, lun, '      Readback:   ', j+1
            printf, lun, '         Name:         ', p.readbackName
            printf, lun, '         Description:  ', p.readbackDescription
            printf, lun, '         Units:        ', p.readbackDescription
            data = *p.data
            dims = size(data, /dimensions)
            printf, lun, '      Dimensions: '+self->formatDimensions(dims)
            if (keyword_set(positioners)) then begin
               printf, lun, '      Data:'
               printf, lun, data
            endif
         endfor
         for j=0, sh.numTriggers-1 do begin
            t = (*sh.triggers)[j]
            printf, lun, '   Trigger: ', j+1
            printf, lun, '      Name:    ', t.name
            printf, lun, '      Command: ', t.command
         endfor
         for j=0, sh.numDetectors-1 do begin
            d = (*sh.detectors)[j]
            printf, lun, '   Detector: ', j+1
            printf, lun, '      Name:        ', d.name
            printf, lun, '      Description: ', d.description
            printf, lun, '      Units:       ', d.units
            data = *d.data
            dims = size(data, /dimensions)
            printf, lun, '      Dimensions: '+self->formatDimensions(dims)
            if (keyword_set(detectors)) then begin
               printf, lun, '      Data:'
               printf, lun, data
            endif
         endfor
      endif
   endfor
   if ((keyword_set(extraPVs)) and (self.fileHeader.extraPointer gt 0)) then begin
      for j=0, self.fileHeader.numExtra-1 do begin
         e = (*self.extraPVs)[j]
         printf, lun, 'Extra PV: ', j+1
         printf, lun, '   Name:        ', e.name
         printf, lun, '   Description: ', e.description
         printf, lun, '   Units:       ', e.units
         printf, lun, '   Value:       ', *e.value
      endfor
   endif
   free_lun, lun
   xdisplayfile, output, title=self.fileHeader.fileName
end


function epics_sscan::getFileHeader
   return, self.fileHeader
end

function epics_sscan::getScanHeader
   return, *self.scanHeader
end

function epics_sscan::getExtraPVs
   return, self.extraPVs
end



pro epics_sscan::readExtraPVs
   lun = self.lun
   if (self.fileHeader.extraPointer le 0) then return
   point_lun, lun, self.fileHeader.extraPointer
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
   num_extra = 0S
   readu, lun, num_extra
   self.fileHeader.numExtra = num_extra
   if (num_extra le 0) then return
   extraPVs = replicate({epics_sscanExtraPV}, num_extra)
   for i=0, num_extra-1 do begin
      name='' & description='' & type=0S
      readu, lun, name, description, type
      extraPVs[i].name = name
      extraPVs[i].description = description
      extraPVs[i].type = type
      if (type ne DBR_STRING) then begin
         count=0S & units=''
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
            print, 'Unknown data type in extraPV=', type
            value = ''
         end
      endcase
      readu, lun, value
      ptr_free, extraPVs[i].value
      extraPVs[i].value = ptr_new(value, /no_copy)
   endfor
   ptr_free, self.extraPVs
   self.extraPVs = ptr_new(extraPVs, /no_copy)
end



pro epics_sscan::readScanHeader
   lun = self.lun
   rank=0S & npts=0S & cpt=0S
   readu, lun, rank, npts, cpt
   if (rank gt 1) then begin
      scanPointers = lonarr(npts)
      readu, lun, scanPointers
   endif
   name='' & timeStamp='' & numPositioners=0S & numDetectors=0S & numTriggers=0S
   readu, lun, name, timeStamp, numPositioners, numDetectors, numTriggers
   if (numPositioners gt 0) then begin
      positioners = replicate({epics_sscanPositioner}, numPositioners)
      number=0S & name='' & description='' & stepMode='' & units=''
      readbackName='' & readbackDescription='' & readbackUnits=''
      for i=0, numPositioners-1 do begin
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
      number=0S & name='' & description='' & units=''
      for i=0, numDetectors-1 do begin
         readu, lun, number, name, description, units
         p = {epics_sscanDetector}
         p.number=number & p.name=name & p.description=description & p.units=units
         detectors[i] = p
      endfor
   endif
   if (numTriggers gt 0) then begin
      triggers = replicate({epics_sscanTrigger}, numTriggers)
      for i=0, numTriggers-1 do begin
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
   if ((*self.scanHeader)[index].rank eq 0) then begin
      ; This is the first scan of this rank.  Copy information to the scanHeader
      scanHeader = {epics_sscanScanHeader}
      scanHeader.rank = rank
      scanHeader.npts = npts
      scanHeader.cpt  = cpt
      if (rank gt 1 ) then scanHeader.scanPointers = ptr_new(scanPointers)
      scanHeader.name       = name
      scanHeader.timeStamp      = timeStamp
      scanHeader.numPositioners = numPositioners
      scanHeader.numDetectors   = numDetectors
      scanHeader.numTriggers    = numTriggers
      if (numPositioners gt 0) then begin
         scanHeader.positioners = ptr_new(positioners, /no_copy)
         for i=0, numPositioners-1 do begin
            (*scanHeader.positioners)[i].data = ptr_new(positionerData[*,i])
         endfor
      endif
      if (numDetectors gt 0) then begin
         scanHeader.detectors = ptr_new(detectors, /no_copy)
         dims = (*self.fileHeader.dims)[0:index]
         dims = reverse(dims)
         data = fltarr(dims)
         for i=0, numDetectors-1 do begin
            ; Create data arrays
            (*scanHeader.detectors)[i].data = ptr_new(data)
         endfor
      endif
      if (numTriggers gt 0) then scanHeader.triggers = ptr_new(triggers, /no_copy)
      (*self.scanHeader)[index] = scanHeader
   endif
   offset = (*self.dataOffset)[index]
   for i=0, numDetectors-1 do begin
      (*(*(*self.scanHeader)[index].detectors)[i].data)[offset] = detectorData[*,i]
   endfor
   (*self.dataOffset)[index] += npts
   if (rank gt 1) then begin
      ; Call ourselves recursively for each scan inside this scan
      for i=0, cpt-1 do begin
         self->readScanHeader
      endfor
   endif
end


pro epics_sscan::readFileHeader
   lun = self.lun
   version=0. & number=0L & rank=0S
   readu, lun, version, number, rank
   self.fileHeader.version = version
   self.fileHeader.number  = number
   self.fileHeader.rank    = rank
   ptr_free, self.scanHeader
   self.scanHeader = ptr_new(replicate({epics_sscanScanHeader}, rank))
   self.dataOffset = ptr_new(lonarr(rank))
   dims = intarr(rank)
   readu, lun, dims
   ptr_free, self.fileHeader.dims
   self.fileHeader.dims = ptr_new(dims)
   isRegular=0S & extraPointer=0L
   readu, lun, isRegular, extraPointer
   self.fileHeader.isRegular    = isRegular
   self.fileHeader.extraPointer = extraPointer
end

pro epics_sscan::read_mda, filename
   openr, lun, /get, /xdr, filename
   self.lun = lun
   self->readFileHeader
   self.fileHeader.fileName = filename
   self->readScanHeader
   self->readExtraPVs
   free_lun, lun
end


pro epics_sscan__define

   fileHeader = $
      {epics_sscanFileHeader, $
       fileName:     '', $
       version:      0., $
       number:       0L, $
       rank:         0S, $
       dims:         ptr_new(), $
       isRegular:    0S, $
       numExtra:     0S, $
       extraPointer: 0L $
   }

   scanHeader = $
      {epics_sscanScanHeader, $
       rank:           0S, $
       npts:           0S, $
       cpt:            0S, $
       scanPointers:   ptr_new(), $
       name:           '', $
       timeStamp:      '', $
       numPositioners: 0S, $
       numDetectors:   0S, $
       numTriggers:    0S, $
       positioners:    ptr_new(), $
       detectors:      ptr_new(), $
       triggers:       ptr_new()  $
   }

   scanPositioner = $
      {epics_sscanPositioner, $
       number:              0S, $
       name:                '', $
       description:         '', $
       stepMode:            '', $
       units:               '', $
       readbackName:        '', $
       readbackDescription: '', $
       readbackUnits:       '', $
       data:                ptr_new() $
   }

   scanDetector = $
      {epics_sscanDetector, $
       number:      0S, $
       name:        '', $
       description: '', $
       units:       '', $
       data:        ptr_new() $
   }

   scanTrigger = $
      {epics_sscanTrigger, $
       number:  0S, $
       name:    '', $
       command: 0. $
   }

   extraPV = $
      {epics_sscanExtraPV, $
       name:        '', $
       description: '', $
       type:        0S, $
       count:       0S, $
       units:       '', $
       value:      ptr_new() $
   }

   epics_sscan =  $
      {epics_sscan, $
       lun:            0L, $
       dataOffset:     ptr_new(), $
       fileHeader:     fileHeader, $
       scanHeader:     ptr_new(), $
       extraPVs:       ptr_new() $
   }
end
