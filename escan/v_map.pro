function read_map, file=file

@scan_dims

M_GROUPS    = 50
M_DETECTORS = 20

;
; read detector and positioner arrays from ascii-dump versions 
; of data-catcher files

if ((n_elements(file) eq 0) or  (keyword_set(help) ne 0)) then begin
    print, 'function read_map: read 2d scan data file'
    print, '  d = read_map(file=file)'
    return,0
endif
;

str     = '; '
print, format='(a,$)', 'opening file ...'
openr, lun, file, /get_lun
; print, format='(a,$)', ' allocating memory ...'
MDIM    = 500
tmp_x   = fltarr(MDIM, MAX_POS)
tmp_det = fltarr(MDIM, MDIM, MAX_DET)
vars    = fltarr(MAX_POS+MAX_DET)
tmp_y   = fltarr(MDIM)
det_name   = strarr(M_GROUPS)
det_list   = intarr(M_DETECTORS)
group_list = strarr(M_GROUPS)
Det_String = strarr(m_groups)

npts    = -1
nrow    = -1
npos    =  4
ndet    = MAX_DET
ngroups = -1
first_line = 1
ncols      = 1
nline      = 1
read_labels= 1
do_parsing = 0
print, 'reading ...'
while not (eof(lun)) do begin
    readf,lun,str
    nline = nline + 1
    string = strtrim(str,2)
    if (strlen(string) gt 1) then begin
        char1 = strmid(string, 0, 1) 
        if ((char1 ne ';') and (read_labels eq 0)) then begin
; read data

            npts = npts + 1
            reads, string, vars            
            if (nrow eq 0) then  tmp_x[npts, 0:npos-1] = vars[0:npos-1]
            tmp_det[npts, nrow, 0:ndet-1] = vars[npos:npos+ndet-1]
        endif else begin
            if (first_line eq 1) then begin
                stmp = strmid(string, 0, 12)
                s2   = strmid(string, 12, 13)
                sx   = str_sep(strtrim(s2,2), ' ')
                if (((sx[0] ne '2') and (sx[0] ne '3')) or $
                    (stmp ne '; Epics Scan')) then begin
                    print, ' Not a 2d scan file! '
                    goto, endread
                endif
                first_line = 0
            endif
            char1 = strmid(string, 0, 1) 
            char3 = strmid(string, 0, 3) 
            char8 = strmid(strtrim(string,2) , 0,8) 
            if (char3 eq ';2D')  then begin
                nrow = nrow + 1
                if ((nrow gt 5) and ( ((nrow) mod 10) eq 0)) then print, ";"
                print, format='(a,i3,$)', '  ' , nrow
                sc = strmid(string,3, strlen(string))
                sx = str_sep(strtrim(sc,2), ' ' )
                tmp_y[nrow] = sx[1]
                npts_old = npts
                npts = -1
            endif else if (char8 eq ';=======')  then begin
                do_parsing = 1
            endif else if ((read_labels eq 1) and (char8 eq ';-------'))  then begin
                read_labels = 0
                readf,lun,string
                label = strmid(strtrim(string,2) , 2,strlen(string))
                nline = nline + 1
                cols = str_sep(label, ' ')
                npos = 0
                ndet = 0
                for k = 0, n_elements(cols)-1 do begin
                    if (strmid(strtrim(cols[k],2), 0,1)  eq 'P') then npos = npos+1
                    if (strmid(strtrim(cols[k],2), 0,1)  eq 'D') then ndet = ndet+1
                endfor
                vars = fltarr(npos+ndet)
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
                        ngroups = i
                        det_string[i]=roi
                        group_list[i]=ds
                        i1  = strpos(string, '{')
                        i2  = strpos(string, '}')
                        det_name[i]=strmid(string, i1+1, i2-i1-1)  
                        i1  = strpos(det_name[i], 'mca')
                        if (i1 ge 0) then begin
                            i2  = strpos(det_name[i], ':')
                            il  = i1+3 > i2
                            det_name[i] = strmid(det_name[i],il+1,strlen(det_name[i]))
                        endif
                        goto, det_found
                    endif else if(det_string[i] eq roi) then begin
                        group_list[i] = group_list[i] + ' ' + ds
                        goto, det_found
                    endif
                endfor
            endif 
        endelse
det_found:
nextline:
    endif
endwhile

print, ""
; print, " Available groups from map: ", ngroups
dname    = strarr(ngroups+1)
detectors= intarr(ngroups+1,M_DETECTORS) - 1
for i = 0, ngroups do begin
    if det_name[i] ne ''  then begin
        dname[i] = strtrim(det_name[i],2)
        g        = strtrim(group_list[i],2)
        length   = string_array(g, det_list)
;        print, ' g : ', i, ' :: ',  group_list[i], ' :: ', length
        for j = 0, length-1 do detectors[i,j] = det_list[j] - 1

;        print, dname[i]
    endif
endfor


nx   = npts
if (nx eq -1) then nx = npts_old
ny   = nrow
; print, " nx,ny = ", nx, ny, npts , npts_old
y    = fltarr(ny+1)
da   = fltarr(nx+1, ny+1, ndet)
x    = fltarr(nx+1)
for i = 0, nx do begin
    for j = 0, ny do begin
        for k = 0, ndet-1 do da(i,j,k) = tmp_det(i,j,k)
   endfor
endfor

for j = 0, ny do  y[j] = tmp_y[j] 
for j = 0, nx do  x[j] = tmp_x[j,0] 
;;    for k = 0, npos-1 do x(i,k) = tmp_x(i,k)

sums     = fltarr(nx+1,ny+1,ngroups+1)
for i = 0, ngroups do begin
    for j = 0, M_DETECTORS-1 do begin
        if (detectors[i,j] gt 0) then begin
            sums(*,*,i) = sums(*,*,i) + da(*,*,detectors[i,j])
        endif
;        print, dname[i]
    endfor
endfor


data = {map_data, filename:file, map:da, sums:sums, x:x,y:y, $
        det_name:dname, det:detectors}

endread:
close, lun
free_lun, lun
return, data
end

; ;


