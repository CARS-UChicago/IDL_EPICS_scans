pro bsif_to_ascii, infile, outfile
@bsif_common
read_bsif, infile
openw, 1, outfile
printf, 1, 'File: ' + infile
printf, 1, 'Image title: ' + image_title
printf, 1, 'Number of columns: '+ strtrim(string(n_cols),2)
printf, 1, 'Number of rows: '+ strtrim(string(n_rows),2)
printf, 1, 'Starting and Stopping Positions (cols):'$
	+ strtrim(string(x_start),2), + ' , ', $
	+ strtrim(string(x_stop),2)
printf, 1, 'Starting and Stopping Positions (rows):'$
	+ strtrim(string(y_start),2), + ' , ', $
	+ strtrim(string(y_stop),2)
for j=0,n_data-1 do begin
printf, 1, data_title(j)
data=image_data(*,*,j)
;form='(11i7)'
;if (n_cols lt 11) then $
form='(' + strtrim(string(n_cols),2) + 'a8)'
for k=0,n_rows-1 do begin
	printf, 1, strtrim(string(image_data(*,k,j)),2) ;+ '/', format=form
endfor
endfor
close, 1
end
