pro show_correl, file=file, data=data
   wset
   print, 'show correl'
   show_mapcorrel,  file=file, data=data, type='correl'
return
end

