pro read_escan, file=file, da=da, pa=pa, npts=npts, npa=npa, nda=nda, help=help
;
; read detector and positioner arrays from ascii-dump versions 
; of data-catcher files
@scan_dims
;
if (keyword_set(help) ne 0) then begin
    print, 'Read_escan: Read data file from escan'
    print, ' argument         meaning      '
    print, '  file       input file name   '
    print, '  pa         positioner array [ fltarr([npts,npa]'
    print, '  da         detector array   [ fltarr([npts,nda)]'
    print, '  npts       number of data points in Scan'
    print, '  npa        number of positioners in Scan'
    print, '  nda        number of detectors in Scan'
    print, '  /help      print this help message'
    return
endif
;
if (n_elements(file) eq 0) then  begin
    print, 'read_sscan, file=file, da=da, pa=pa, npts=npts'
    print, ' type  read_sscan, /help   for more details'
    return
endif

on_ioerror, io_problem

str = '; '

openr, lun, file, /get_lun

tmp_pos = fltarr(MAX_SCAN_POINTS,MAX_POS)
tmp_det = fltarr(MAX_SCAN_POINTS,MAX_DET)
npos    = MAX_POS
ndet    = MAX_DET
vars    = fltarr(MAX_POS + MAX_DET)
npts    = -1
while not (eof(lun)) do begin
    readf,lun,str
    string = strtrim(str,2)
    if (strlen(string) le 1) then goto, nextline
    char1 = strmid(strtrim(string,2) , 0,1) 
    char_ = strmid(strtrim(string,2) , 0,8) 
    if ( char_ eq ';-------')  then begin
        readf,lun,string
        label = strmid(strtrim(string,2) , 2,strlen(string))
        cols = str_sep(label, ' ')
        npos = 0
        ndet = 0
        for k = 0, n_elements(cols)-1 do begin
            if (strmid(strtrim(cols[k],2), 0,1)  eq 'P') then npos = npos+1
            if (strmid(strtrim(cols[k],2), 0,1)  eq 'D') then ndet = ndet+1
        endfor
        vars = fltarr(npos+ndet)
    endif  else if ( char1 ne ';')  then begin
        cols = str_sep(strcompress(strtrim(string,2)), ' ')
        npts = npts + 1
; read data
;         vars = fltarr(npos+ndet)
        reads, str, vars            
        tmp_pos[npts, 0:npos-1] = vars[0:npos-1]
        tmp_det[npts, 0:ndet-1] = vars[npos:npos+ndet-1]
    endif
    nextline:
endwhile

io_problem:

print, " reads done:  npts = ", npts, npos, ndet
close, lun
free_lun, lun

nda = ndet
npa = npos
da  = fltarr(npts+1,nda)
pa  = fltarr(npts+1,npa)
for i = 0, npts do begin
    for j = 0, nda-1 do begin
        da(i,j) = tmp_det(i,j)
    endfor
endfor

for i = 0, npts do begin
    for j = 0, npa-1 do begin
        pa(i,j) = tmp_pos(i,j)
    endfor
endfor


return
end

;








