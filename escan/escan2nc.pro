pro escan2nc, file, out

f    = read_scan(file)
f->save_netcdf, file=out
return
end
