pro read_sscan, file=file, da=da, pa=pa, npts=npts, help=help
;
; read detector and positioner arrays from ascii-dump versions 
; of data-catcher files

;
if (keyword_set(help) ne 0) then begin
    print, 'Read_sscan: Read data file from sscan'
    print, ' argument         meaning      '
    print, '  file       input file name   '
    print, '  pa         positioner array [ fltarr([npts,4)]'
    print, '  da         detector array   [ fltarr([npts,15)]'
    print, '  npts       number of data points in Scan'
    print, '  /help      print this help message'
    return
endif
;
if (n_elements(file) eq 0) then  begin
    print, 'read_sscan, file=file, da=da, pa=pa, npts=npts'
    print, ' type  read_sscan, /help   for more details'
    return
endif
string = '; '
openr, lun, file, /get_lun

tmp_pos  = fltarr(1000,4)
tmp_data = fltarr(1000,15)

npts = -1
while not (eof(lun)) do begin
    readf,lun,string
    char1 = strmid(strtrim(string,2) , 0,1) 
    if ( char1 ne ';')  then begin
;;        print, string
        reads, string, p1,p2,p3,p4, d01, d02,  d03,  d04,  d05, $        
          d06,d07,d08,d09,d10,d11,d12,d13,d14,d15          
;        reads, string, p1,d01, d02,  d03,  d04
        npts = npts + 1
        tmp_pos[npts, 0] = p1
        tmp_pos[npts, 1] = p2
        tmp_pos[npts, 2] = p3
        tmp_pos[npts, 3] = p4
        tmp_data[npts, 0] = d01
        tmp_data[npts, 1] = d02
        tmp_data[npts, 2] = d03
        tmp_data[npts, 3] = d04
        tmp_data[npts, 4] = d05
        tmp_data[npts, 5] = d06
        tmp_data[npts, 6] = d07
        tmp_data[npts, 7] = d08
        tmp_data[npts, 8] = d09
        tmp_data[npts, 9] = d10
        tmp_data[npts,10] = d11
        tmp_data[npts,11] = d12
        tmp_data[npts,12] = d13
        tmp_data[npts,13] = d14
        tmp_data[npts,14] = d15
    endif
endwhile

print, " npts = ", npts
da   = fltarr(npts+1,15)
da   = tmp_data(0:npts,*)
pa   = fltarr(npts+1,4)
pa   = tmp_pos(0:npts,*)
close, lun
free_lun, lun

return
end

;








