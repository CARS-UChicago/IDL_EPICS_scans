pro fastmap, scan=scan, datafile=datafile
;
;  execute a fast map

mapper = '13XRM:map:'

s_file  = 'CurrentScan.ini'
d_file  = 'default.dat'
if (keyword_set(scan) ne 0 ) then s_file = scan
if (keyword_set(datafile) ne 0 ) then d_file = datafile

bd_file = bytarr(128)
bd_file[0:strlen(d_file)-1] = byte(d_file)
x = caput(mapper + 'filename', bd_file)

bs_file = bytarr(128)
bs_file[0:strlen(s_file)-1] = byte(s_file)
x = caput(mapper + 'scanfile', bs_file)

print, 'Starting FastMap '

x = caput(mapper + 'Start', 1)

; step 1 wait for collecting to start (status == 2)
collecting = 0
count = 0
while collecting ne 2 do begin
   x = caget(mapper + 'status', collecting)
   wait, 1.0
   count = count + 1
   if count ge 300 then collecting = 2
endwhile

print, 'FastMap has now started. Waiting for it to finish:'
nrow = 0
count = 0
maxrow = 2000
x = caget(mapper + 'maxrow', maxrow)
print, 'maxrow = ', maxrow
; wait for scan to get past row 1
while nrow le 1 do begin
   x = caget(mapper + 'nrow', nrow)
   wait, 5.0
   count = count + 1
   if count ge 60 then nrow = 3
endwhile

print, 'see nrow  is now ' , nrow
; wait for map to finish
collecting = 2
count = 0
nrowx = -1
while collecting ne 0 do begin
   wait, 2.0
   x = caget(mapper + 'nrow', nrow)
   x = caget(mapper + 'status', collecting)
   if nrowx ne nrow then begin
      print, ' map: now at row ', nrow, ' of ', maxrow, 'rows.'
      nrowx = nrow
   endif
   if (nrow ge maxrow) and collecting ne 2 then begin
      count = count + 1
   endif
   if count ge 30 then collecting = 0
endwhile
print, 'FastMap has finished!'
wait, 5.0

return
end
