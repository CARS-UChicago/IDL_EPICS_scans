pro read_file, file=file

;
; read detector and positioner arrays from ascii-dump versions
; of data-catcher files

M_GROUPS    = 50
M_DETECTORS = 20

;
if (n_elements(file) eq 0) then  begin
    print, 'read_file, file=file'
    return
endif
str     = '; '
do_parsing = 0
nline      = 0
group_name  = strarr(M_GROUPS)
detectors  = intarr(M_GROUPS,M_DETECTORS)
intlist    = intarr(M_DETECTORS)
group_list = strarr(M_GROUPS)
Det_String = strarr(m_groups)


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
    ;    print, roi, ds
        for i = 0, m_groups - 1 do begin
            if det_string[i] eq '' then begin
                                ; print, ' New det = ', roi, i
                det_string[i]=roi
                group_list[i]=ds
                i1  = strpos(string, '{')
                i2  = strpos(string, '}')
                group_name[i]=strmid(string, i1+1, i2-i1-1)
                goto, nextline
            endif else if(det_string[i] eq roi) then begin
                group_list[i] = group_list[i] + ' ' + ds
                goto, nextline
            endif
        endfor
    endif
    nextline:
endwhile
endread:
close, lun
free_lun, lun

read_escan2d, file=file, da=da, x=x,y=y

print, " "
print, 'Enter desired output format'
print, '1 map'
print, '2 plot'
read, output
print, " "
print, " Available Groups:"
print, "------------------"
for i = 0, m_groups - 1 do begin
    if group_name[i] ne ''  then begin
        length  = string_array(group_list[i], intlist)
        for j = 0, length-1 do detectors[i,j] = intlist[j]
        print, i+1 , '   ', group_name[i], ' > ', intlist
    endif
endfor

print, ' '

if output eq '1' then begin
    print, ' Select Group to Map:'
    read, i_user
    ix   = i_user - 1
    print, ' you picked:  ', group_name[ix]
    print, ' Do you want to normalize by i0? (Y/N) [Y]'
    norm_ans= 'Y'
    read, ans
    norm_ans = strupcase(ans)
    map = da(*,*,detectors[ix,0]-1)
    print, ' start with ', detectors[ix,0]
    for i = 1, m_detectors-1 do begin
        if (detectors[ix,i] ne 0) then begin
            print, ' add ', detectors[ix,i]
            map = map + da(*,*,detectors[ix,i]-1)
        endif
    endfor
    if norm_ans eq 'Y' then begin
        map = map / da(*,*,detectors[0,0]-1)
    endif
    image_display, map, ydist=y,xdist=x(*,0)
endif else if output eq '2' then begin
    print, 'Select 2 groups to plot (y axis, x axis)'
    read, i_user1, i_user2
    iy = i_user1 - 1
    ix = i_user2 - 1
    print, 'You Selected ', group_name[iy], ' and ', group_name[ix]
    
    map1 = da(*,*,detectors[ix,0]-1)
    map2 = da(*,*,detectors[iy,0]-1)
    print, ' start with ', detectors[ix,0]
    for i = 1, m_detectors-1 do begin
        if (detectors[ix,i] ne 0) then begin
            print, ' add ', detectors[ix,i]
            map1 = map1 + da(*,*,detectors[ix,i]-1)
        endif
        if (detectors[iy,i] ne 0) then begin
            print, ' add ', detectors[iy,i]
            map2 = map2 + da(*,*,detectors[iy,i]-1)
        endif
    endfor
    wset
    plot, map1, map2, psym=1, xtitle=group_name[ix], ytitle=group_name[iy]
endif

return
end

;
