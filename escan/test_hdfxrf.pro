pro test_hdfxrf

med = obj_new('EPICS_MED', 'dxpXMAP:', 4)

data = med->get_data()

print, 'ASCII:'
openw, xlun , 'test_ascii.out', /get_lun
printf, xlun, strcompress(string(1,2,data*1000.0,format='(8194i)'))   
close, xlun


print, 'HDF:'

sd_id = hdf_sd_start('foo.hdf', /create, /rdwr)
ds    = hdf_sd_create(sd_id, 'xrf spectra', [2048,4], /LONG)

hdf_sd_adddata,   ds, data
hdf_sd_endaccess, ds
hdf_sd_end, sd_id

return 
end


