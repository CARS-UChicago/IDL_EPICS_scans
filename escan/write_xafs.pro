pro write_xafs, file=file, energy=energy, xmu=xmu, title=title
;
; writes out an exafs energy/xmu file from data

;       'points' : header.npoints = long(words[1])
;       'begin'  : header.emax = angstroms_to_kev/(long(words[1]) / 1.e4)
;       'end'    : header.emin = angstroms_to_kev/(long(words[1]) / 1.e4)
;       'sltsiz' : header.slit_size = float(words[1])
;       'sltpos' : header.slit_position = float(words[1])
if (keyword_set(file)  eq 0)  then begin
   print, ' no output file'
   return
endif
if (keyword_set(energy)  eq 0)  then begin
   print, ' no energy array'
   return
endif
if (keyword_set(xmu)  eq 0)  then begin
   print, ' no xmu array'
   return
endif
titl = ' '
if (keyword_set(title)  ne 0)  then titl = title

openw, lun,file, /get_lun
printf, lun, '# ', titl
printf, lun, '#--------------------'
printf, lun, '# energy  xmu'
nx = size_of(xmu)
for i = 0, nx-1 do begin
    printf, lun, format='(1x,f9.3,1x,g15.7)' , energy[i], xmu[i]
endfor

print, 'wrote ', file
close, lun
free_lun, lun
return
end


