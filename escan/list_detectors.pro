function list_detectors, d, M
;
l = strarr(M)
j = -1
out = ['']
if (n_elements(d.desc) lt 1) then return, out


for i = 0, n_elements(d.desc) - 1 do begin
    if (d.desc[i] ne '') then  begin
        j    = j + 1
        l[j] = d.desc[i]
    endif
endfor

if (j lt 1) then return, out

out = strarr(j+1)
for i = 0, j do begin
    out[i] = l[i]
endfor

return, out
end
