pro show_mapcorrel, file=file, data=data, type=type, use_data=use_data, map=map
;
; show correlations from a map file:
;
; oread detector and positioner arrays from ascii-dump versions
; of data-catcher files

M_GROUPS    = 50
M_DETECTORS = 20

;

xtype = ''
if (keyword_set(type) ne 0) then xtype = type

if ((n_elements(file) eq 0) and (n_elements(data) eq 0)) then  begin
    print, ' syntax:   show_map,    file=file, data=data'
    print, '           show_correl, file=file, data=data'
    print, ' '
    print, ' purpose:  show maps and correlation plots from 2D Epics Scan'
    print, ' '
    print, ' notes:    show_correl and show_map will read data from a map'
    print, '           data file into the temporary data variable named by'
    print, '           the data keyword.  This data variable can be usd in'
    print, '           in subsequent calls to show_correl or show_map to '
    print, '           avoid having to re-read the whole file.'
    print, '  '
    print, '           That is, you can first say'
    print, "  >  show_correl, file='big_map.001', data=bigmap"
    print, '           to read the data, and then'
    print, "  >  show_correl, data=bigmap"
    print, '           and even'
    print, "  >  show_map,    data=bigmap"
    print, '           for faster maps and correlation plots'
    return
endif
str     = '; '
do_parsing = 0
nline      = 0
group_name = strarr(M_GROUPS)
detectors  = intarr(M_GROUPS,M_DETECTORS)
intlist    = intarr(M_DETECTORS)
group_list = strarr(M_GROUPS)
Det_String = strarr(m_groups)


will_read = 1
if (keyword_set(use_data) eq 1) then  will_read = 0
if ((n_elements(file) eq 0) and (n_elements(data) ne 0)) then  begin
    ErrorNo = 0
    Catch, ErrorNo
    if (ErrorNo ne 0) then begin
        print, ' the map data you gave is not the correct form.'
        print, ' Please read in the map with show_correl or show_map first.' 
        return
    endif
    x = data.x
    will_read = 0
endif

if (keyword_set(will_read) eq 0) then begin
    da = data.da
    x  = data.x
    y  = data.y
    group_name = data.group_name
    group_list = data.group_list
    filename   = data.filename
endif else begin
    print, 'reading datafile ', file
    read_escan2d, file=file, da=da, x=x,y=y
    filename = file
    openr, lun, file, /get_lun
    while not (eof(lun)) do begin
        readf,lun,str
        nline = nline + 1
        string= strtrim(str,2)
        char1 = strmid(string, 0, 1)
        char3 = strmid(string, 0, 3)
        char8 = strmid(strtrim(string,2) , 0,8)
        if (strlen(string) le 1) then goto, nextline
        if (char8 eq ';-------') then begin
            goto, endread
        endif else if (char8 eq ';=======')  then begin
            do_parsing = 1
        endif else if ( do_parsing eq 1)  then begin
            if (char3 ne '; D') then goto, nextline
            slen   = strlen(string) - 1
            clast  = strmid(string, slen, slen)
            if (clast eq 'N') then begin
                roi = strmid(string, slen-2, slen-1)
            endif else begin
                roi = strmid(string, slen-1, slen)
            endelse
            ds  = strmid(string, 3, 2)
            for i = 0, m_groups - 1 do begin
                if det_string[i] eq '' then begin
                    det_string[i]=roi
                    group_list[i]=ds
                    i1  = strpos(string, '{')
                    i2  = strpos(string, '}')
                    group_name[i]=strmid(string, i1+1, i2-i1-1)
                    goto, det_found
                endif else if(det_string[i] eq roi) then begin
                    group_list[i] = group_list[i] + ' ' + ds
                    goto, det_found
                endif
            endfor
det_found:
        endif
        nextline:
    endwhile
endread:
    
    
    close, lun
    free_lun, lun
endelse

i_user1 = 1
i_user2 = 2
print, " Available Data Groups from this map:"
for i = 0, m_groups - 1 do begin
    if group_name[i] ne ''  then begin
        length  = string_array(group_list[i], intlist)
        for j = 0, length-1 do detectors[i,j] = intlist[j]
        print, i+1 , '   ', group_name[i]
    endif
endfor

; print, ' type= ', xtype
if (xtype  eq 'map') then begin
    print, ' Select Data Group (by number) to Map: '
    read, i_user1
    ix       = i_user1 - 1
    map = da(*,*,detectors[ix,0]-1)
    for i = 1, m_detectors-1 do begin
        if (detectors[ix,i] ne 0) then   map = map + da(*,*,detectors[ix,i]-1)
    endfor
    map = map / (da(*,*,detectors[0,0]-1)>1)
    image_display, map, ydist=y, xdist=x(*,0), title=group_name[ix], subtitle=filename
endif else if (xtype eq 'correl') then begin
    print, 'Select 2 Data Groups to plot by number [x axis, y axis]'
    read, i_user1, i_user2
    ix = i_user1 - 1
    iy = i_user2 - 1
    map  = da(*,*,detectors[ix,0]-1)
    map2 = da(*,*,detectors[iy,0]-1)
    for i = 1, m_detectors-1 do begin
        if (detectors[ix,i] ne 0) then   map  = map  + da(*,*,detectors[ix,i]-1)
        if (detectors[iy,i] ne 0) then   map2 = map2 + da(*,*,detectors[iy,i]-1)
    endfor
    plot, map, map2, psym=1, xtitle=group_name[ix], ytitle=group_name[iy], title=filename
endif else begin
    print, "I can't tell whether you want a map or correlation plot"
endelse

data = {da:da, x:x,y:y, group_name:group_name, group_list:group_list, filename:filename}

return
end
;
