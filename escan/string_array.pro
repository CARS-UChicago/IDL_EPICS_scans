function string_array, str, array
;  convert string of space-separated values to an array
array = str_sep(strcompress(str),' ')
n     = n_elements(array)
for i = 0, n-1 do array[i] = strtrim(array[i],2)
return, n
end
