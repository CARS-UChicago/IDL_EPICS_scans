 ;
; Scan Data Class: read and manipulate epics scan data and maps
; 
; function scan_data::match_detector_name
; function scan_data::get_map
; pro      scan_data::show_map
; pro      scan_data::show_correl
; function scan_data::get_orig_detector_list
; function scan_data::get_detector_list
; function scan_data::set_detector_list
; pro      scan_data::map_all_detectors
; pro      scan_data::plot_all_detectors
; function scan_data::get_data
; pro      scan_data::plot
; pro      scan_data::oplot
; function scan_data::read_data_file
; pro      scan_data::set_param
; function scan_data::get_param
; function scan_data::get_dimension
; function scan_data::get_filename
; function scan_data::get_plot_colors
; pro      scan_data::set_plot_colors
; function scan_data::get_x
; function scan_data::get_y
; pro      scan_data::help
; pro      scan_data::show_params
; pro      scan_data::show_detectors
; function scan_data::init

function scan_data::match_detector_name, str, strict=strict, show_error=show_error
;+
; NAME:               scan_data::match_detector_name
;
; PURPOSE:            look up detector group (ie, summed detectors) 
;                     by name (or closest match), return array index
;
; CALLING SEQUENCE:   n = scan_data->match_detector_name(string)
;
; INPUTS:             str        - string to look up as 'detector group name'
;
; KEYWORD PARAMETERS: strict     - flag to force exact string match
;                     show_error - flag to show error messagee on failure
;
; OUTPUTS:            integer index in scan_data.sums for detector group
;
; PROCEDURE:          the input string is first checked for an exact match with
;                     the set of detector names in scan_data.det_names.  if no
;                     exact match is found, then the passed string is checked 
;                     for exact match of the first word (blank delimited) of 
;                     each name in scan_data.det_names.  finally, if strict=0 
;                     (the default), the first close match is chosen.
;
;
; EXAMPLE:            d = obj_new('scan_data','scan_file_001.dat')
;                     n = d->match_detector_name('Cu')
;
; MODIFICATION HISTORY:  2001-aug-05  m newville
;
;-

if (n_elements(str) le 0) then begin
    print, " match_detector_name error -- no string given"
    return, -1
endif
s  = strlowcase(str)
n =  n_elements(*self.det_names) 
; look for exact match
for i = 0, n - 1 do begin
    if (s eq strlowcase((*self.det_names)[i])) then return, i
endfor

; inexact match:  check first word
for i = 0, n - 1 do begin
    sx   = str_sep(strlowcase((*self.det_names)[i]), ' ')
    if (s eq sx[0]) then return, i
endfor
;
; last resort: check for any similarity
if (keyword_set(strict) eq 0) then begin
    for i = 0, n - 1 do begin
        j = strpos(strlowcase((*self.det_names)[i]), s)
        if (j ge 0) then begin
            print, s,  ' is sort of like ', (*self.det_names)[i]
            return, i
        endif
    endfor
endif

if (keyword_set(show_error) ne 0) then begin
    print, " can't find  detector named ", str
    print, " available detectors: "
    self->show_detectors
endif
return, -1
end


function scan_data::get_map, name=name, index=index, $
             use_sum=use_sum, use_raw=use_raw, $
             norm=norm, inorm=inorm
;+
; NAME:               scan_data::get_map
;
; PURPOSE:            return map data from scan_data object
;
; CALLING SEQUENCE:   map = scan_data->get_map(name=name, index=index,...)
;
; KEYWORD PARAMETERS: name       name of detector group to use for map
;                     index      integer index for detector array to use
;                     use_sum    flag to use summed detectors [default]
;                     use_raw    flag to use raw (individual) detectors
;                     norm       norm of detector group for normalization
;                     inorm      index of detector for normalization
;
; OUTPUTS:            2d data for requested map
;
; PROCEDURE:          the map requested can be selected by detector name or
;                     array index. by default, the summed detectors are used,
;                     and the index would be the element in the summed list.
;
;                     a map from the raw detectors can  also be selected, but
;                     must be selected by index. 
;
;                     the output map can be normalized by any other map using
;                     norm or inorm.
;
;                     the name for detector group (and optional normalization 
;                     map) is found using match_detector_name
; 
;
;
; EXAMPLE:            d     = obj_new('scan_data','scan_file_001.dat')
;                     map1  = d->get_map(name='Cu')
;                     map2  = d->get_map(name='As', norm='i0')
;                     map23 = d->get_map(index=23, /use_raw)
;
; MODIFICATION HISTORY:  2001-aug-05  m newville
;
;-

stitle = ''
uname  = ''
nname  = ''
uindex = -1
nindex = -1
usum   =  1
do_norm=  0
empty  = fltarr(2,2) - 99
if (n_elements(name)    ne 0)  then uname = name
if (n_elements(index)   ne 0)  then uindex= index
if (n_elements(use_sum) ne 0)  then usum  = 1
if (n_elements(use_raw) ne 0)  then usum  = 0
if (n_elements(norm)    ne 0)  then nname = norm
if (n_elements(inorm)   ne 0)  then nindex=inorm

if (nname ne '')  then do_norm = 1
if (nindex ne -1) then do_norm = 2
; 
;
if (self.dimension eq 1) then begin
    print, ' get_map:  not a map file -- try get_data '
    return, empty
endif
if ((uname eq '') and (uindex eq -1)) then begin
    print, ' get_map:  no element index or name given'
    return, empty
endif else if (uname ne '') then begin
    uindex = self->match_detector_name(uname,/show_error)
    if (uindex lt 0) then return, empty
endif

if (usum eq 0) then begin
    map = (*self.raw)[*,*,uindex]
    stitle = 'Raw Detector ' + strtrim(uindex,2)
endif else if (usum eq 1) then begin
    map = (*self.sums)[*,*,uindex]
    stitle = (*self.det_names)[uindex]
endif
;
; determine normalization array
if (do_norm eq 1) then begin
    nindex = self->match_detector_name(nname, /show_error)
    if (nindex lt 0) then return, empty
endif
;
; normalize here
if ((nindex ge 0) and (do_norm ge 1)) then begin
    if (usum eq 0) then begin
        map = map / (*self.raw)[*,*,nindex]
        stitle = stitle + ' / Raw Detector ' +  strtrim(nindex,2)
    endif else if (usum eq 1) then begin
        map = map / (*self.sums)[*,*,nindex]
        stitle = stitle + ' / ' +  (*self.det_names)[nindex]
    endif

endif
self.subtitle = stitle
return, map
end


;;
pro      scan_data::show_map, name=name,  _extra=extra
;+
; NAME:               scan_data::show_map
;
; PURPOSE:            display selected map data from scan_data object
;
; CALLING SEQUENCE:   scan_data->show_map(name=name, index=index,...)
;
; KEYWORD PARAMETERS: see scan_data::get_map for list
;
; OUTPUTS:            none
;
; SIDE EFFECTS:       a map image is displayed using image_display
;
; PROCEDURE:          see notes in scan_data::get_map -- all keywords are 
;                     the same as for that function
;
; EXAMPLE:            d     = obj_new('scan_data','scan_file_001.dat')
;                     d->show_map, name='Cu'
;                     d->show_map, name='As', norm='i0'
;                     d->show_map, index=23, /use_raw
;
; MODIFICATION HISTORY:  2001-aug-05  m newville
;
;-

map = self->get_map(name=name, _extra=extra)
if ((map(0,0) ne -99)  or (map(1,0) ne -99) or (n_elements(map) gt 4)) then begin
    image_display, map, xdist=(*self.x),ydist=(*self.y),$
      title=self.filename, subtitle=self.subtitle
endif
self.subtitle=''
return
end

pro      scan_data::dump_ascii, file=file, norm=norm, title=title, $
                  use_raw=use_raw, use_sum=use_sum, cchar=cchar, label=label

;
; writes out column ascii file from data
;
titl  = ''
cchr  = '#'


if (keyword_set(file)  eq 0)  then begin
    file = self.filename + '.asc'
endif

x1   = (*self.x)
labl = self.xpos
if (keyword_set(label)  ne 0)  then labl = label

if (keyword_set(title)  ne 0)  then titl = title
if (keyword_set(cchar)  ne 0)  then cchr = cchar

usum = 1
if (keyword_set(use_raw) ne 0) then usum = 0
if (keyword_set(use_sum) ne 0) then usum = 1

lx   = (*self.det_names) + ' | '
ndet = n_elements(*self.det_names)

use_norm  = 0
if (keyword_set(norm) ne 0) then begin
    xnorm = self->get_data(name=norm, use_sum=usum)
    use_norm = 1
    i_norm   = -1
    for i  = 0, ndet -1 do begin
        if ((*self.det_names)[i] eq norm) then i_norm = i
    endfor
endif

openw, lun, file, /get_lun
if (titl ne '') then  titl = 'summed detectors'

printf, lun, cchr, titl
printf, lun, cchr, ' data from ' , self.filename
if ((i_norm ge 0) and (use_norm eq 1)) then begin
    printf, lun, cchr, ' normalized by detector ' , norm
endif

printf, lun, cchr, '------------------------'
printf, lun, cchr, ' ', labl, ' | ', lx

nx   = n_elements(x1)

form_str = '(1x,f10.4'
for i  = 0, ndet -1 do form_str = form_str + ',1x,g15.7'
form_str = form_str + ')'

for i = 0, nx-1 do begin
    dets = reform((*self.sums)[i,*])
    if ((i_norm ge 0) and (use_norm eq 1)) then begin
        for j = 0, ndet-1 do begin
            if (j ne i_norm) then dets[j] = dets[j]/dets[i_norm]
        endfor
    endif
    printf, lun, format=form_str, x1[i], dets
endfor

print, 'wrote ', file
close, lun
free_lun, lun
return
end


pro      scan_data::write_correl, x=x, y=y, file=file, cchar=cchar

map1 = self->get_map(name=x, /use_sum)
lab1 = self.subtitle

map2 = self->get_map(name=y, /use_sum)
lab2 = self.subtitle

npts = n_elements(map1)
m1   = reform(map1,1,npts)
m2   = reform(map2,1,npts)

titl  = ''
cchr  = '#'
labl = lab1 + ' | ' + lab2

if (keyword_set(title)  ne 0)  then titl = title
if (keyword_set(cchar)  ne 0)  then cchr = cchar
if (keyword_set(label)  ne 0)  then labl = label
if (keyword_set(file)   eq 0)  then file = self.filename + '.cor' 

openw, lun, file, /get_lun
if (titl ne '') then  printf, lun, cchr, titl

printf, lun, cchr, ' data from ' , self.filename
printf, lun, cchr, '--------------------'
printf, lun, cchr, ' ', labl

for i = 0, npts-1 do begin
    printf, lun, format='(1x,g15.7,1x,g15.7)' , m1[0,i], m2[0,i]
endfor

print, 'wrote ', file
close, lun
free_lun, lun

return
end

pro      scan_data::show_correl, x=x, y=y, _extra=extra
;+
; NAME:               scan_data::show_correl
;
; PURPOSE:            plot 2d correlation plot of two named detector groups
;
; CALLING SEQUENCE:   scan_data->show_correl(x=x, y=y, ...)
;
; KEYWORD PARAMETERS: x          name of detector group to use for x-axis
;                     y          name of detector group to use for y-axis
;                     additional keywords are sent to IDL's plot command
;
; OUTPUTS:            none
;
; SIDE EFFECTS:       a 2d correlation plot is displayed
;
; PROCEDURE:          this uses only summed detectors given by name
;
; EXAMPLE:            d     = obj_new('scan_data','scan_file_001.dat')
;                     d->show_correl, x='Cu', y='Fe'
;
; MODIFICATION HISTORY:  2001-aug-05  m newville
;
;-

map1 = self->get_map(name=x, /use_sum)
lab1 = self.subtitle

map2 = self->get_map(name=y, /use_sum)
lab2 = self.subtitle

self.subtitle=''
if ((map1(0,0) ne -99)  or (map1(1,0) ne -99) or (n_elements(map1) gt 4)) then begin
    plot, map1, map2, psym=1, xtitle=lab1, ytitle=lab2, title=self.filename, $
      back=set_color('white'), color=set_color('black'), _extra=extra
endif

return
end

;;

function scan_data::get_orig_detector_list, name=name, index=index
;+
; NAME:               scan_data::get_orig_detector_list
;
; PURPOSE:            return original list of detectors for a named detector groups
;
; CALLING SEQUENCE:   s = scan_data->get_orig_detector_list(name=name, index=index)
;
; KEYWORD PARAMETERS: name         name of detector group 
;                     index        integer index of detector group 
;
; OUTPUTS:            list of raw detectors assigned to this group when the 
;                     data file was originally read.  this list is not altered
;                     by scan_data::set_detector_list.
;
; SIDE EFFECTS:       none.
;
; PROCEDURE:          this uses only summed detectors given by name or index
;
; EXAMPLE:            d  = obj_new('scan_data','scan_file_001.dat')
;                     o  = d->get_orig_detector_list(name='Cu')
;
; MODIFICATION HISTORY:  2001-aug-05  m newville
;
;-

uname = ''
uindex= -1
if (n_elements(name)    ne 0)  then uname = name
if (n_elements(index)   ne 0)  then uindex= index

if (uindex lt 0) then begin
    uindex = self->match_detector_name(uname, /show_error)
endif

if (uindex lt 0) then return, uindex

n   = n_elements((*self.det_orig)) 
tmp = intarr(n) - 1
cnt = 0
for i = 0, n - 1 do begin
    if ((*self.det_orig)[i] eq uindex) then begin
        tmp[cnt] = i
        cnt = cnt + 1
    endif
endfor
return, tmp(0:cnt-1)
end

function scan_data::get_detector_list, name=name, index=index
;+
; NAME:               scan_data::get_detector_list
;
; PURPOSE:            return current list of detectors for a named detector groups
;
; CALLING SEQUENCE:   s = scan_data->get_detector_list(name=name, index=index)
;
; KEYWORD PARAMETERS: name         name of detector group 
;                     index        integer index of detector group 
;
; OUTPUTS:            list of raw detectors assigned to the specified group.
;                     this list may be altered by scan_data::set_detector_list.
;
; SIDE EFFECTS:       none.
;
; PROCEDURE:          this uses only summed detectors given by name or index
;
; EXAMPLE:            d  = obj_new('scan_data','scan_file_001.dat')
;                     lis= d->get_detector_list(name='Cu')
;
; MODIFICATION HISTORY:  2001-aug-05  m newville
;
;-

uname = ''
uindex= -1
if (n_elements(name)    ne 0)  then uname = name
if (n_elements(index)   ne 0)  then uindex= index

if (uindex lt 0) then begin
    uindex = self->match_detector_name(uname, /show_error)
endif

if (uindex lt 0) then return, uindex

n   = n_elements((*self.det_list)) 
tmp = intarr(n) - 1
cnt = 0
for i = 0, n - 1 do begin
    if ((*self.det_list)[i] eq uindex) then begin
        tmp[cnt] = i
        cnt = cnt + 1
    endif
endfor
return, tmp(0:cnt-1)
end

function scan_data::set_detector_list, name=name, index=index, list=list
;+
; NAME:               scan_data::set_detector_list
;
; PURPOSE:            overwrite the current list of detectors for a named detector groups
;
; CALLING SEQUENCE:   s = scan_data->set_detector_list(name=name, index=index,list=list)
;
; KEYWORD PARAMETERS: name         name of detector group 
;                     index        integer index of detector group 
;                     list         list of integer indices of raw detectors 
;                                  for this detector group 
;
; OUTPUTS:            list of raw detectors assigned to the specified group.
;                     this list may be altered by scan_data::set_detector_list.
;
; SIDE EFFECTS:       the sum for the specified detector group is recomputed.
;
; PROCEDURE:          the specified list is used for the sum of grouped detectors.
;                     if any element in the list is less than 0, that element is ignored
;
; EXAMPLE:            d  = obj_new('scan_data','scan_file_001.dat')
;                     old= d->get_detector_list(name='Cu')
;                     new= old
;                     new[3] = -1  ; remove detector 3 from the list
;                     tmp= d->set_detector_list(name='Cu')  
;
; MODIFICATION HISTORY:  2001-aug-05  m newville
;
;-

uname = ''
uindex= -1
if (n_elements(name)    ne 0)  then uname = name
if (n_elements(index)   ne 0)  then uindex= index

if (uindex lt 0) then begin
    uindex = self->match_detector_name(uname, /show_error)
endif

if (uindex lt 0) then begin
    print,  ' set_detector_list : no detector to set'
    return, -1
endif else if (n_elements(list)   le 0)  then begin
    print,  ' set_detector_list : no detector list given.'
    return, -1
endif

n     = n_elements((*self.det_list)) 
; print, 'unindex = ', uindex
;
; unset all detector elements for this sum
for j = 0, n - 1 do begin
    if ( (*self.det_list)[j] eq uindex ) then (*self.det_list)[j] = -1
endfor

help, (*self.sums), uindex
if (self.dimension eq 1) then begin
    (*self.sums)[*,uindex] = 0
endif else begin
    (*self.sums)[*,*,uindex] = 0
endelse

for i = 0, n_elements(list) - 1 do begin
    j = list[i]
    if (j ge 0) then begin
        (*self.det_list)[j] = uindex
        if (self.dimension eq 1) then begin
            (*self.sums)[*,uindex]   = (*self.sums)[*,uindex]    + (*self.raw)[*,j] 
        endif else begin
            (*self.sums)[*,*,uindex] = (*self.sums)[*,*,uindex]  + (*self.raw)[*,*,j] 
        endelse
    endif
endfor

return, list
end


pro      scan_data::map_all_detectors, name=name, index=index, _extra=extra

self->plot_all_detectors, name=name, index=index, _extra=extra

return
end

pro      scan_data::plot_all_detectors, name=name, index=index, _extra=extra
;

;  plot all detectors in a named group

if (n_elements(name) ne 0) then begin
    n  = self->match_detector_name(name)
    if (n ge 0) then   name = (*self.det_names)[n]
endif
list = self->get_detector_list(name=name, index=index)
ytitle = 'detectors ' + strtrim(list[0],2) + ':' +  strtrim(list[n_elements(list)-1],2) 
if (n_elements(name) ne 0) then ytitle = name + ' ( ' + ytitle + ' )'
dim    = self.dimension


if (n_elements(list) ge 1) then begin
    if (dim eq 1) then begin
        ymax = max( (*self.raw)[*,list] )
        ymin = min( (*self.raw)[*,list] )
        self->plot,  index=list[0], /use_raw, $
          yrange=[ymin,ymax], ytitle=ytitle, _extra=extra
        for i = 1, n_elements(list) - 1 do begin
            self->oplot, index=list[i], /use_raw, _extra=extra
        endfor
    endif else begin
        for i = 0, n_elements(list) - 1 do begin
            self->show_map,  index=list[i], /use_raw, _extra=extra
        endfor
    endelse
endif

return
end


function scan_data::get_data, name=name, index=index, $
             use_sum=use_sum, use_raw=use_raw, $
             norm=norm, inorm=inorm

empty  = fltarr(2)
data   = empty
stitle = ''
uname  = ''
nname  = ''
uindex = -1
nindex = -1
usum   =  1
do_norm=  0
is_map =  0
empty  = fltarr(2,2) - 99
if (n_elements(name)    ne 0)  then uname = name
if (n_elements(index)   ne 0)  then uindex= index
if (n_elements(use_sum) ne 0)  then usum  = 1
if (n_elements(use_raw) ne 0)  then usum  = 0
if (n_elements(norm)    ne 0)  then nname = norm
if (n_elements(inorm)   ne 0)  then nindex=inorm

if (nname ne '') then do_norm = 1
if (nindex ne -1) then do_norm = 2
; 
;
if (self.dimension eq 2) then begin
    print, ' get_data:  this is a map file -- getting row 0 (try get_map)!'
    is_map = 1
endif
if ((uname eq '') and (uindex eq -1)) then begin
    print, ' get_data:  no element index or name given'
    return, empty
endif else if (uname ne '') then begin
    uindex = self->match_detector_name(uname,/show_error)
    if (uindex lt 0) then return, empty
endif

if (usum eq 0) then begin
    if (is_map eq 1) then begin
        data = (*self.raw)[*,0,uindex]
    endif else begin
        data = (*self.raw)[*,uindex]
    endelse
    stitle = 'Raw Detector ' + strtrim(uindex,2)
endif else if (usum eq 1) then begin
    if (is_map eq 1) then begin
        data = (*self.sums)[*,0,uindex]
    endif else begin
        data = (*self.sums)[*,uindex]
    endelse
    stitle = (*self.det_names)[uindex]
endif
;
; determine normalization array
if (do_norm eq 1) then begin
    nindex = self->match_detector_name(nname, /show_error)
    if (nindex lt 0) then return, empty
endif
;
; normalize here
if ((nindex ge 0) and (do_norm ge 1)) then begin
    if (usum eq 0) then begin
        if (is_map eq 1) then begin
            data = data / (*self.raw)[*,0,nindex]
        endif else begin
            data = data / (*self.raw)[*,nindex]
        endelse
        stitle = stitle + ' / Raw Detector ' +  strtrim(nindex,2)
    endif else if (usum eq 1) then begin
        if (is_map eq 1) then begin
            data = data / (*self.sums)[*,0,nindex]
        endif else begin
            data = data / (*self.sums)[*,nindex]
        endelse
        stitle = stitle + ' / ' +  (*self.det_names)[nindex]
    endif
endif
self.subtitle = stitle
return, data
end


;;
pro      scan_data::plot, name=name, index=index, $
                  use_sum=use_sum, use_raw=use_raw, $
                  norm=norm, inorm=inorm, color=color, psym=psym, bw=bw,$
                  _extra=extra

ydat  = self->get_data(name=name,  index=index, $
                       use_sum=use_sum, use_raw=use_raw, $
                       norm=norm, inorm=inorm)

lab1 = self.subtitle
self.subtitle=''

ucol = set_color((*self.plot_colors)[0])
usym = 0
if (n_elements(color) ne 0) then ucol = set_color(color)
if (n_elements(psym) ne 0)  then usym = psym
if (keyword_set(bw) ne 0)   then ucol = set_color('black')

plot, (*self.x),  ydat,  xtitle=self.xpos, ytitle=lab1, title=self.filename, chars=1.5, thick=2, $
  back=set_color('white'), color=set_color('black'), _extra=extra,  /nodata
oplot, (*self.x),  ydat, psym=usym, color=ucol, _extra=extra
self.nplot = 0
return
end

function scan_data::filetype, file
;
; checks file type of file, returning:
;   2    NETCDF, Epics Scan
;   1    ASCII,  Epics Scan
;  -1    ASCII,  Not Epics Scan
;  -2    NETCDF, Not Epics Scan
;  -3    Unknown
; 
on_ioerror, not_cdf
u = ncdf_open(file,/nowrite)
retval = -2

on_ioerror, not_epics_cdf

at = ncdf_attinq(u, 'title', /global)
if (at.datatype ne 'UNKNOWN') then begin
    ncdf_attget, u, 'title', /global, ff
    if (strpos(string(ff), 'Epics Scan: netcdf') ge 0) then retval = 2
endif

not_epics_cdf:
ncdf_close, u

return, retval

not_cdf:
on_ioerror, not_ascii

openr, lun, file, /get_lun
s = ''
readf, lun, s, format='(a16)'
retval = -1
if (strpos(s,'Epics Scan') ge 0) then retval = 1
close, lun
free_lun, lun
return, retval

not_ascii:
return, -3
end


pro      scan_data::oplot, name=name, index=index, $
                  use_sum=use_sum, use_raw=use_raw, $
                  norm=norm, inorm=inorm, color=color, psym=psym, bw=bw, $
                  _extra=extra

ydat  = self->get_data(name=name,  index=index, $
                       use_sum=use_sum, use_raw=use_raw, $
                       norm=norm, inorm=inorm)
self.nplot = self.nplot + 1
lab1 = self.subtitle
self.subtitle=''
nc   = n_elements((*self.plot_colors))
ucol = set_color((*self.plot_colors)[self.nplot mod nc])
if (keyword_set(bw) ne 0) then begin
    ucol = set_color('black')
    nc   = 1
endif
usym =-self.nplot/nc
if (n_elements(psym) ne 0)  then usym = psym

if (n_elements(color) ne 0) then ucol = set_color(color)
oplot, (*self.x),  ydat, psym=usym, color=ucol, _extra=extra

return
end

;;

function scan_data::read_data_file, file
;
; read epics scan data file
;
@scan_dims
retval = -1
if ((n_elements(file) eq 0) or  (keyword_set(help) ne 0)) then begin
    print, ' function scan_data::read_data_file(filename)'
    return, retval
endif
;

filetype  = self->filetype(file)
print, ' file type = ' , filetype
case filetype of
    1: begin
        retval = self->read_ascii_data_file(file)
    end
    2: begin
        retval = self->read_netcdf_data_file(file)
    end
    else: begin
        retval = -3
    end
endcase
if (retval eq 0) then begin
    print, '   OK.'
endif else begin
    print, ' file ', file , ' is not a valid scan data file: ', retval
endelse

return, retval
end


function scan_data::read_ascii_data_file, file
;
; read epics scan data file
;
@scan_dims

M_GROUPS = 50
MPVLIST  = 64
MTITLES  = 16
MDIM     = 500
retval   = -1

;
; read detector and positioner arrays from ascii-dump versions 
; of data-catcher files

if ((n_elements(file) eq 0) or  (keyword_set(help) ne 0)) then begin
    print, ' function scan_data::read_data_file(filename)'
    return, retval
endif
;

str     = '; '
print, format='(3a,$)', 'opening file ', file, ' ... '

filetype   = self->filetype(file)
if (filetype ne 1) then return, retval

openr, lun, file, /get_lun
tmp_x      = fltarr(MDIM, MAX_POS)
tmp_det    = fltarr(MDIM, MDIM, MAX_DET)
vars       = fltarr(MAX_POS+MAX_DET)
tmp_y      = fltarr(MDIM)
det_name   = strarr(M_GROUPS)
pos_name   = strarr(MAX_POS)
pv_list    = strarr(MPVLIST)
user_titles = strarr(MTITLES)
ypos       = ''
ypv        = ''
det_desc   = strarr(MAX_DET)
det_pv     = strarr(MAX_DET)
det_list   = intarr(MAX_DET)
group_list = strarr(M_GROUPS)
Det_String = strarr(m_groups)

npts       = -1
nrow       = -1
ngroups    = -1
npos       = -1
ndet       = -1
ntitles    = -1
nt         =  0
first_line = 1
ncols      = 1
nline      = 1
dimen      = 2
; read mode: 0  front matter
;            1  User titles:
;            2  PV list:
;            3  scan began at' to ;  'scan ended at'
;            4  column labels
;            5  '-----------------'
;
read_mode  = 0 
; 
print, 'reading ...'
while not (eof(lun)) do begin
    readf,lun,str
    nline = nline + 1
    string = strtrim(str,2)
    if (strlen(string) le 3) then goto, next_line
    char1 = strmid(string, 0, 1) 
    char3 = strmid(string, 0, 3) 
    char8 = strmid(strtrim(string,2) , 0,8) 

    if (strpos(string,'User titles:') ge 1) then begin
        read_mode = 1
        nt = 0
        goto, next_line
    endif else if (strpos(string,'PV list:') ge 1) then begin
        read_mode = 2
        ntitles = nt
        nt = 0
        goto, next_line
    endif else if (strpos(string,'began at time:') ge 1) then begin
        read_mode = 3
    endif else if (strpos(string,'column labels:') ge 1) then begin
        read_mode = 4
        goto, next_line
    endif else if (strpos(string,'--------') ge 1) then begin
        read_mode = 5
        readf, lun, str
        npos = npos + 1
        ndet = ndet + 1
        ; print, ' npos , ndet = ', npos, ndet
        vars = fltarr(npos+ndet)
        goto, next_line
    endif
    if (read_mode eq 0) then begin ; front
        if (first_line eq 1) then begin
            stmp = strmid(string, 0, 12)
            s2   = strmid(string, 12, 13)
            sx   = str_sep(strtrim(s2,2), ' ')
            if (stmp ne '; Epics Scan') then begin
                print, ' Not a valid scan file! '
                goto, endread
            endif
            dimen = fix(sx[0])
            first_line = 0
        endif
        if ((dimen ge 2) and (char3 eq ';2D'))  then begin
            nrow = nrow + 1
            sc = strmid(string,3, strlen(string))
            sx = str_sep(strtrim(sc,2), ' ' )
            tmp_y[nrow] = sx[1]
            npts = -1
            n = strpos(string,':', /reverse_search)
            ypv = strmid(string,4, n-4)
        endif
    endif else if (read_mode eq 1) then begin ; user titles
        if (nt lt MTITLES) then begin
            if strlen(string) ge 2 then  begin
                tx1 = strtrim( strmid(string,2, strlen(string)), 2)
                if strlen(tx1) ge 2 then  begin
                    user_titles[nt] = tx1
                    nt  = nt + 1                    
                endif
            endif
        endif
    endif else if (read_mode eq 2)  then begin ; PV list
        if (nt lt MPVLIST) then begin
            tx1 = strtrim( strmid(string,2, strlen(string)), 2)
            if strlen(tx1) ge 2 then  begin
                pv_list[nt] = tx1
                nt  = nt + 1                    
            endif
        endif
        if ((ypos eq '') and (ypv ne '')) then begin
; searching for name of 2D positioner  in list of saved values
            i1  = strpos(string, '(')
            i2  = strpos(string, ')')
            if (i2 gt i1) then begin
                pv =strmid(string, i1+1, i2-i1-1)  
                if (pv eq ypv) then ypos = strtrim(strmid(string,2,i1-2),2)
            endif
        endif
    endif else if (read_mode eq 3) then begin
        i = strpos(string,'began at time:')
        self.start_time = strtrim(strmid(string,i+15,strlen(string)),2)
        readf, lun, string
        readf, lun, string
        i = strpos(string,'ended at time:')
        self.stop_time = strtrim(strmid(string,i+15,strlen(string)),2)
        readf, lun, string
    endif else if (read_mode eq 4)  then begin ; column labels
; reading list of positioner/detectors for 1d scan
        ;print, ' mode 4 ', npos, ndet
        if (char3 eq '; P') then begin
            npos = npos + 1
            n  = -1 + fix(strmid(string,3,3))
            i1 = strpos(string, '{')
            i2 = strpos(string, '}')
            pos_name[n]=strmid(string, i1+1, i2-i1-1)  
        endif else if (char3 eq '; D') then begin
            ndet = ndet + 1
            slen   = strlen(string) - 1
            clast  = strmid(string, slen, slen)
            if (clast eq 'N') then begin
                roi = strmid(string, slen-2, slen-1)
            endif else begin
                roi = strmid(string, slen-1, slen)
            endelse
            ds  = strmid(string, 3, 2)
; force all non-mca detectors (like, scalars) into individual groups
            i1  = strpos(string, '{')
            i2  = strpos(string, '}')
            i3  = strpos(string, '-->')
            det_desc[ndet]=strmid(string, i1+1, i2-i1-1)
            det_pv[ndet]  =strmid(string, i3+4, strlen(string))
            ; print , ' ds = ', det_desc[ndet], det_pv[ndet]
            if (strpos(string,'mca') lt 2) then  roi = string
            for i = 0, m_groups - 1 do begin
                if det_string[i] eq '' then begin
                    ngroups      = i
                    det_string[i]= roi
                    group_list[i]= ds
                    i1  = strpos(string, '{')
                    i2  = strpos(string, '}')
                    det_name[i]=strmid(string, i1+1, i2-i1-1)  
                    i1  = strpos(det_name[i], 'mca')
                    if (i1 ge 0) then begin
                        i2  = strpos(det_name[i], ':')
                        il  = i1+3 > i2
                        det_name[i] = strmid(det_name[i],il+1,strlen(det_name[i]))
                    endif
                    goto, next_line
                endif else if(det_string[i] eq roi) then begin
                    group_list[i] = group_list[i] + ' ' + ds
                    goto, next_line
                endif
            endfor
        endif
    endif else if (read_mode eq 5) then begin ; read data
        if (char1 ne ';') then begin
            npts = npts + 1
            reads, string, vars            
            if (nrow lt 0) then nrow = 0
            if (nrow eq 0) then  tmp_x[npts, 0:npos-1] = vars[0:npos-1]
            tmp_det[npts, nrow, 0:ndet-1] = vars[npos:npos+ndet-1]
        endif else if ((dimen eq 2) and (char3 eq ';2D')) then begin
            nrow = nrow + 1
            if ((nrow gt 5) and ( ((nrow) mod 10) eq 0)) then print, ";"
            print, format='(a,i3,$)', '  ' , nrow
            sc = strmid(string,3, strlen(string))
            sx = str_sep(strtrim(sc,2), ' ' )
            tmp_y[nrow] = sx[1]
            npts_old = npts
            npts = -1
            readf, lun, stmp
            stmp = strtrim(stmp,2)
            isx  = strpos(stmp,'ended at time:')
            if (isx gt 1) then  $
              self.stop_time = strtrim(strmid(stmp,isx+15,strlen(stmp)),2)
            readf, lun, stmp
            readf, lun, stmp
        endif
    endif
next_line:
endwhile


dname    = strarr(ngroups+1)
detectors= intarr(ndet)
for i = 0, ngroups do begin
    if det_name[i] ne ''  then begin
        dname[i] = strtrim(det_name[i],2)
        g        = strtrim(group_list[i],2)
        length   = string_array(g, det_list)
        for j = 0, length-1 do  detectors[det_list[j]-1] = i
    endif
endfor

nx   = npts
if (nx eq -1) then nx = npts_old
ny   = nrow
y    = fltarr(ny+1)
da   = fltarr(nx+1, ny+1, ndet)
x    = fltarr(nx+1)
xa   = fltarr(nx+1,npos)
for i = 0, nx do begin
    for j = 0, ny do begin
        for k = 0, ndet-1 do da(i,j,k) = tmp_det(i,j,k)
   endfor
endfor

for j = 0, ny do  y[j] = tmp_y[j] 
for j = 0, nx do  x[j] = tmp_x[j,0] 
for j = 0, nx do  begin
    for k = 0, npos-1 do xa[j,k] = tmp_x[j,k]
endfor

p_name = strarr(npos)
for k = 0, npos-1 do p_name[k] = pos_name[k]

sums     = fltarr(nx+1,ny+1,ngroups+1)
for i = 0, ngroups do begin
    for j = 0, ndet - 1 do begin
        if (detectors[j] eq i) then  sums(*,*,i) = sums(*,*,i) + da(*,*,j)
    endfor
endfor
;
; refom 1d data
if (dimen eq 1) then begin
    da  = reform(da)
    sums= reform(sums)
endif

retval  = 0

endread:

close, lun
free_lun, lun

self.ndetectors= ndet
self.npositioners= npos
self.dimension = dimen
self.filename  = file
self.xpos      = pos_name[0]
self.ypos      = ypos
self.raw       = ptr_new(da)
self.sums      = ptr_new(sums)
self.x         = ptr_new(x)
self.pos_raw   = ptr_new(xa)
self.pos_names = ptr_new(p_name)
self.y         = ptr_new(y)
self.det_names = ptr_new(dname)
self.det_list  = ptr_new(detectors)
self.det_orig  = ptr_new(detectors)

if (ndet le 0) then ndet = 1

ut = strarr(ndet)
for i = 0, n_elements(ut)-1 do ut[i] = det_desc[i]
self.detfull_desc = ptr_new(ut)

ut = strarr(ndet)
for i = 0, n_elements(ut)-1 do ut[i] = det_pv[i]
self.detfull_pv   = ptr_new(ut)
; print, 'size of detfull_pv = ', n_elements(ut), n_elements(*self.detfull_pv)

if (ntitles le 0) then begin
    ntitles = 1
    user_titles[0] = '<- No User Titles ->'
endif
ut = strarr(ntitles)
for i = 0, n_elements(ut)-1 do ut[i] = user_titles[i]
self.user_titles  = ptr_new(ut)

if (nt gt 0) then begin
    ut = strarr(nt)
    for i = 0, n_elements(ut)-1 do ut[i] = pv_list[i]
endif else begin
    ut = strarr(1)
    ut[0] = '<- No PV LIST ->'
endelse
self.pv_list      = ptr_new(ut)

; print, ' read done'
return, retval
end

;
;
function scan_data::read_netcdf_data_file, file
;
; read epics scan data file in netcdf format
;
@scan_dims

M_GROUPS    = 50
MPVLIST     = 64
MTITLES     = 16
MDIM        = 500
retval = -1

str     = '; '
print, format='(3a,$)', 'opening file ', file, ' ... '

filetype   = self->filetype(file)
if (filetype ne 2) then return, retval

ncid = ncdf_open(file,/nowrite)
at   = ncdf_attinq(ncid, 'title', /global)
if (at.datatype ne 'UNKNOWN') then begin
    ncdf_attget, ncid, 'title', /global, ff
    if (strpos(string(ff), 'Epics Scan: netcdf') ge 0) then retval = -2
endif

u  = ncdf_inquire(ncid)

dimens = {val:intarr(u.ndims), name:strarr(u.ndims)}

s = ''
for i = 0, u.ndims - 1 do begin
    ncdf_diminq, ncid, i, s, n
    case s of
        'string length':   nstr = n
        'scan dimension':  ndim = n
        'n positioners':   npos = n
        'n detectors':     ndet = n
        'n sums':          nsum = n
        'n user_titles':   n_ut = n
        'n pv_list':       n_pv = n
        'nx':              nx   = n
        'ny':              ny   = n
        else: begin
            print,  ' unknown dimension ', s
        end
    endcase
endfor

self.filename    = file
self.dimension   = ndim
self.ndetectors  = ndet
self.npositioners= npos
self.subtitle    = ''
self.nplot       = 0

s  = ''
ncdf_varget, ncid, 'user titles', s
self.user_titles = ptr_new(string(s))

ncdf_varget, ncid, 'pv list', s
self.pv_list = ptr_new(string(s))

ncdf_varget, ncid, 'start time', s
self.start_time = (string(s))

ncdf_varget, ncid, 'stop time', s
self.stop_time = (string(s))

ncdf_varget, ncid, 'x name', s
self.xpos = (string(s))

ncdf_varget, ncid, 'y name', s
self.ypos = (string(s))

ncdf_varget, ncid, 'det desc', s
self.detfull_desc = ptr_new(string(s))

ncdf_varget, ncid, 'det pv', s
self.detfull_pv = ptr_new(string(s))

ncdf_varget, ncid, 'sums names', s
self.det_names = ptr_new(string(s))

ncdf_varget, ncid, 'pos desc', s
self.pos_names = ptr_new(string(s))

ncdf_varget, ncid, 'x', x
self.x  = ptr_new(x)

ncdf_varget, ncid, 'y', x
self.y  = ptr_new(x)

ncdf_varget, ncid, 'sums map', x
self.det_list  = ptr_new(x)
self.det_orig = self.det_list

ncdf_varget, ncid, 'positioners', x
self.pos_raw = ptr_new(x)

ncdf_varget, ncid, 'detectors', x
self.raw  = ptr_new(x)

ncdf_varget, ncid, 'det sums', x
self.sums = ptr_new(x)

; ncdf_varput, ncid, 'positioners', (*self.pos_raw)
; ncdf_varput, ncid, 'det sums',    (*self.sums)
; ncdf_varput, ncid, 'detectors',   (*self.raw)

ncdf_close, ncid
retval = 0

return, retval
end

pro      scan_data::save_netcdf, file=file
;
; save current data structure to a netcdf file
;
; things not saved to netcdf file:
;  filename, subtitle, plot_colors, nplot, det_orig


if (keyword_set(file)  eq 0)  then file = self.filename + '.nc'
ncid    = ncdf_create(file, /clobber)
;
ncdf_attput, ncid, /global, 'title', 'Epics Scan: netcdf version 0.1'

;
; max string size
str_max = 48
str_max = max(str_max > max(strlen((*self.detfull_pv))) > max(strlen((*self.detfull_desc))))
str_max = max(str_max > max(strlen((self.start_time)))  > max(strlen((self.stop_time))))
str_max = max(str_max > max(strlen((*self.pv_list)))    > max(strlen((*self.user_titles))))
str_max = max(str_max > max(strlen((*self.pos_names)))  > max(strlen((*self.det_names))))
str_max = 8 * (1 + fix(str_max+1)/8) 

nstr = ncdf_dimdef(ncid, 'string length',  str_max)
ndim = ncdf_dimdef(ncid, 'scan dimension', self.dimension)
npos = ncdf_dimdef(ncid, 'n positioners',  self.npositioners)
ndet = ncdf_dimdef(ncid, 'n detectors',    self.ndetectors)
nsum = ncdf_dimdef(ncid, 'n sums',         n_elements(*self.det_names))
n_ut = ncdf_dimdef(ncid, 'n user_titles',  n_elements(*self.user_titles))
n_pv = ncdf_dimdef(ncid, 'n pv_list',      n_elements(*self.pv_list))
nx   = ncdf_dimdef(ncid, 'nx',             n_elements(*self.x))
ny   = ncdf_dimdef(ncid, 'ny',             n_elements(*self.y))

id   = ncdf_vardef(ncid, 'user titles', [nstr,n_ut], /char)
id   = ncdf_vardef(ncid, 'pv list',     [nstr,n_pv], /char)
id   = ncdf_vardef(ncid, 'start time',  [nstr],      /char)
id   = ncdf_vardef(ncid, 'stop time',   [nstr],      /char)
id   = ncdf_vardef(ncid, 'x',           [nx],        /float)
id   = ncdf_vardef(ncid, 'y',           [ny],        /float)
id   = ncdf_vardef(ncid, 'x name',      [nstr],      /char)
id   = ncdf_vardef(ncid, 'y name',      [nstr],      /char)
id   = ncdf_vardef(ncid, 'positioners', [nx,npos],   /float)
id   = ncdf_vardef(ncid, 'pos desc',    [nstr,npos], /char)
id   = ncdf_vardef(ncid, 'det desc',    [nstr,ndet], /char)
id   = ncdf_vardef(ncid, 'det pv',      [nstr,ndet], /char)
id   = ncdf_vardef(ncid, 'sums names',  [nstr,nsum], /char)
id   = ncdf_vardef(ncid, 'sums map',    [ndet],      /short)

if (self.dimension ge 2) then begin
    id = ncdf_vardef(ncid, 'detectors',   [nx,ny,ndet], /float)
    id = ncdf_vardef(ncid, 'det sums',    [nx,ny,nsum], /float)
endif else begin
    id = ncdf_vardef(ncid, 'detectors',   [nx,ndet],   /float)
    id = ncdf_vardef(ncid, 'det sums',    [nx,nsum],   /float)
endelse

ncdf_control, ncid, /endef

ncdf_varput, ncid, 'user titles', (*self.user_titles)
ncdf_varput, ncid, 'pv list',     (*self.pv_list)
ncdf_varput, ncid, 'start time',  (self.start_time)
ncdf_varput, ncid, 'stop time',   (self.stop_time)
ncdf_varput, ncid, 'x',           (*self.x)
ncdf_varput, ncid, 'y',           (*self.y)
ncdf_varput, ncid, 'x name',      (self.xpos)
ncdf_varput, ncid, 'y name',      (self.ypos)
ncdf_varput, ncid, 'positioners', (*self.pos_raw)
ncdf_varput, ncid, 'det desc',    (*self.detfull_desc)
ncdf_varput, ncid, 'det pv',      (*self.detfull_pv)
ncdf_varput, ncid, 'sums names',  (*self.det_names)
ncdf_varput, ncid, 'sums map',    (*self.det_list)
ncdf_varput, ncid, 'pos desc',    (*self.pos_names)
ncdf_varput, ncid, 'det sums',    (*self.sums)
ncdf_varput, ncid, 'detectors',   (*self.raw)

ncdf_close, ncid
;

return
end


pro      scan_data::set_param, par, val
;
; returns a single attribute of a particular scan
;
is = 0
if (keyword_set(iscan) ne 0) then is = iscan
if (keyword_set(par) ne 0) then begin
    case par of
        'dimension':    self.dimension    = val
        'filename':     self.filename     = val
        'raw_data':     (*self.raw)       = val
        'sums':         (*self.sums)      = val
        'x':            (*self.x)         = val
        'y':            (*self.y)         = val
        'xpos':         self.xpos         = val
        'ypos':         self.ypos         = val
        'det_names':    (*self.det_names) = val
        'pos_names':    (*self.pos_names) = val
        'det_list':     (*self.det_list)  = val
        'plot_colors':  (*self.plot_colors)  = val
    endcase
endif
return
end

function scan_data::get_param, par
;
; return a copy of an object member structure
; for outside manipulation and later 'set_param'ing
val = 0
if (keyword_set(par) ne 0) then begin
    case par of
        'ndetectors':   val = self.ndetectors
        'npositioners': val = self.npositioners
        'dimension':    val = self.dimension
        'filename':     val = self.filename
        'raw_pos':      val = (*self.pos_raw)
        'raw_data':     val = (*self.raw)
        'sums':         val = (*self.sums)
        'x':            val = (*self.x)
        'y':            val = (*self.y)
        'xpos':         val = self.xpos
        'ypos':         val = self.ypos
        'pos_names':    val = (*self.pos_names)
        'det_names':    val = (*self.det_names)
        'det_list':     val = (*self.det_list)
        'det_orig':     val = (*self.det_orig)
        'detfull_desc': val = (*self.detfull_desc)
        'detfull_pv':   val = (*self.detfull_pv)
        'pv_list':      val = (*self.pv_list)
        'plot_colors':  val = (*self.plot_colors)
        'user_titles':  val = (*self.user_titles)
        'ntitles':      val = n_elements(*self.user_titles)
        'start_time':   val = self.start_time
        'stop_time':    val = self.stop_time
    endcase
endif

return, val
end

function scan_data::get_dimension
return, self->get_param('dimension')
end
function scan_data::get_ndetectors
return, self->get_param('ndetectors')
end

function scan_data::get_npositioners
return, self->get_param('npositioners')
end

function scan_data::get_filename
return, self->get_param('filename')
end

function scan_data::get_plot_colors
return, self->get_param('plot_colors')
end

pro      scan_data::set_plot_colors, val
self->set_param, 'plot_colors', val
end

function scan_data::get_x
return, self->get_param('x')
end

function scan_data::get_y
return, self->get_param('y')
end


pro      scan_data::help
;+
; NAME:
;
;
;
; PURPOSE:
;
;
;

; CALLING SEQUENCE:
;
;
;
; INPUTS:
;
;
;
; OPTIONAL INPUTS:
;
;
;
; KEYWORD PARAMETERS:
;
;
;
; OUTPUTS:
;
;
;
; OPTIONAL OUTPUTS:
;
;
;
; COMMON BLOCKS:
;
;
;
; SIDE EFFECTS:
;
;
;
; RESTRICTIONS:
;
;
;
; PROCEDURE:
;
;
;
; EXAMPLE:
;
;
;
; MODIFICATION HISTORY:
;
;-

print, ' Methods for scan_data class:'
print, ' --------------------------------------------------------'
print, ' function get_map '
print, ' pro      show_map '
print, ' pro      show_correl '
print, ' pro      show_detectors'
print, ' function read_data_file'
print, ' pro      help'
print, ' pro      set_param'
print, ' function get_param'
print, ' pro      show_params'
print, ' function match_detector_name'
print, ' '
self->show_params

return
end

pro      scan_data::show_params
;
; list available parameters
;
print, ' Parameters accessible for scan file '
print, '   using get_param / set_param:'
print, ' --------------------------------------------------------'
print, '   name                meaning'
print, ' filename        scan file name '
print, ' dimension       scan dimension'
print, ' raw_data        complete set of raw detector data  '
print, ' sums            summed detectors, grouped by detector element '
print, ' det_names       names for summed detector groups'
print, ' det_list        2d integer array list of raw detectors for sums'
print, ' x               array of x positions '
print, ' y               array of y positions (for 2d scans)'
print, ' xpos            name of x positioner'
print, ' ypos            name of y positioner (for 2d scans)'
print, ' --------------------------------------------------------'
return
end


pro      scan_data::show_detectors
n =  n_elements(*self.det_names) 

print, format='(a,$)', '[  '
for i = 0, n - 2 do begin
    print, format='(a,a,$)', (*self.det_names)[i], ', '
endfor
print, format='(a,a)', (*self.det_names)[n-1], ' ]'
return
end


function scan_data::init, file=file

cols = ['blue', 'red', 'black', 'magenta', 'forestgreen']
self.plot_colors =   ptr_new(cols)


if (n_elements(file) ne 0) then begin
    u = self->read_data_file(file)
endif
return, 1
end

pro      scan_data__define
;+
; NAME:
;       EPICS_SCAN__DEFINE
;
; PURPOSE:
;       Defines an object for EPICS scan data files from epics_scan object
;
;
; CALLING SEQUENCE:
;       dat = obj_new('scan_data')
;
;
; INPUTS:
;       None.
;
; OPTIONAL INPUTS:
;       None.
;
; KEYWORD PARAMETERS:
;       None.
;
;
; OUTPUTS:
;       Return value will contain the object reference.
;
;
; OPTIONAL OUTPUTS:
;       None.
;
;
; COMMON BLOCKS:
;       None.
;
;
; SIDE EFFECTS:
;       EPICS_Scan object is created.
;
;
; RESTRICTIONS:
;       This routine is not called directly, but by IDL's own obj_new()
;
; PROCEDURE:
;
;
; EXAMPLE:
;       data = obj_new('scan_data', 'my_data_file.001')
;       data->read_scan_file('my_data_file.001')
;
; MODIFICATION HISTORY:
;       Aug 03 2001: M Newville
;-
@scan_dims
MAX_SUM_ELEMS = 16  ; max number of detectors to add together for sum

p = ptr_new()
scan_data = { scan_data, filename:   ' ', dimension: 1, $
              ndetectors:0, npositioners:0, pos_raw:p, $
              subtitle:' ',    user_titles:p, pv_list:p, $
              raw:  p, sums:p,  plot_colors:p, nplot:0, $
              x: p, y: p,  xpos: '', ypos:'', $
              start_time:'', stop_time:'', $
              detfull_desc:p,  detfull_pv:p, $
              pos_names: p,  det_names: p, $
              det_list: p, det_orig: p} 

end
