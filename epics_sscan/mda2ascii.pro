pro mda2ascii, file
;
; simple ASCII column-file dump of an MDA data file
; Warning: not well tested, and may not work on multi-dimensional data files
; 
; Usage: 
;   idl> mda2ascii, 'my.mda'
;     wrote   90 points to my.txt
; 
; Matt Newville , 2007-Mar-07

if (keyword_set(file)  eq 0)  then begin
   print, ' no mda file given'
   return
endif

fname = file
fmda = obj_new('epics_sscan')
fmda->read_mda, fname

det  = fmda->getDetector(scan=1,/all)
pos  = fmda->getPositioner(scan=1,/all)
head = fmda->getFileHeader()
npts = n_elements(*det[0].pdata)

wait, 0.05

idot = strpos(fname, '.mda')
if idot le 0 then idot = strlen(mda)

out_file = strmid(fname,0,idot) + '.dat'

openw, lun,out_file, /get_lun
printf, lun, '; Epics Scan 1 dimensional scan :   converted from MDA file = ', fname
printf, lun, ';    current scan = 1'
printf, lun, ';    scan dimension = 1'

printf, lun, '; scan began at time: unknown'
printf, lun, ';===================='
printf, lun, '; scan ended at time: ', (*head.pscanheader).timestamp
printf, lun, '; n_points      =    ', npts
printf, lun, '; column labels:'

label = ''
for i = 0, n_elements(pos)-1 do begin
    lab   =' P' + strtrim(string(i+1),2)
    label = label + lab
    printf, lun, ';', lab, ' = {', pos[i].description, '} --> ', pos[i].name
endfor

for i = 0, n_elements(det)-1 do begin
    lab   =' D' + strtrim(string(i+1),2)
    label = label + lab
    printf, lun, ';', lab, ' = {', det[i].description, '} --> ', det[i].name
endfor

printf, lun, ';-----------------------------------------'
printf, lun, '; ' + label


for i = 0, npts-1 do begin
    for j = 0, n_elements(pos)-1 do begin
        printf, lun,  format='(1x,g14.7,$)', (*pos[j].pdata)[i]
    endfor
    for j = 0, n_elements(det)-1 do begin
        printf, lun,  format='(1x,g14.7,$)', (*det[j].pdata)[i]
    endfor
    printf, lun, ' '
endfor

print, 'wrote ', npts, ' points to ', out_file
close, lun
free_lun, lun
return
end


