function read_escanfile, file
fn = file
x = obj_new('scan_data', file = fn)
return, x
end


