pro read_escan2d, file=file, da=da, x=x, y=y, npts=npts, npos=npos, $
                  ndet=ndet, nx=nx,ny=ny, help=help

@scan_dims

;
; read detector and positioner arrays from ascii-dump versions 
; of data-catcher files

;
if (keyword_set(help) ne 0) then begin
    print, 'Read_escan2d: Read data file from escan'
    print, ' argument         meaning      '
    print, '  file       input file name   '
    print, '  x          positioner array(s) for column fltarr(nx,npos)'
    print, '  y          positioner array for row'
    print, '  da         detector array   [ fltarr([nx,ny,ndet)]'
    print, '  npts       number of data points in Scan'
    print, '  npos       number of positioners in Scan'
    print, '  ndet       number of detectors in Scan'
    print, '  /help      print this help message'
    return
endif
;
if (n_elements(file) eq 0) then  begin
    print, 'read_sscan, file=file, da=da, pa=pa, npts=npts'
    print, ' type  read_sscan, /help   for more details'
    return
endif
str     = '; '
print, format='(a,$)', 'opening file ...'
openr, lun, file, /get_lun
print, format='(a,$)', ' allocating memory ...'
MDIM    = 500
tmp_x   = fltarr(MDIM, MAX_POS)
tmp_det = fltarr(MDIM, MDIM, MAX_DET)
vars    = fltarr(MAX_POS+MAX_DET)
tmp_y   = fltarr(MDIM)
npts    = -1
nrow    = -1
npos    =  4
ndet    = MAX_DET
first_line = 1
ncols      = 1
nline      = 1
read_labels= 1
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
            endif 
        endelse
    endif
endwhile

print, ""
nx   = npts
if (nx eq -1) then nx = npts_old
ny   = nrow
y    = fltarr(ny+1)
da   = fltarr(nx+1, ny+1, ndet)
x    = fltarr(nx+1, npos)
for i = 0, nx do begin
    for k = 0, npos-1 do x(i,k) = tmp_x(i,k)
    for j = 0, ny do begin
        for k = 0, ndet-1 do da(i,j,k) = tmp_det(i,j,k)
   endfor
endfor

for j = 0, ny do  y[j] = tmp_y[j] 

endread:
close, lun
free_lun, lun
return
end

; ;
