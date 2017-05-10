;
;  simple procedures for fluorescence tomography, reading ESCAN data files,
;  and displaying fluorescence slices
;
;   Matt Newville
;

function read_escan_file, file
  return,  obj_new('scan_data', file = file)
end


function fluor_reconstruct, sino, center=center
 siz  = size(sino)
 tmp  = fltarr(siz(1),1,siz(2))
 tmp(*,0,*)= sino
 if (keyword_set(center) ne 0) then begin
     return, reconstruct_slice(0, tmp, /noring, /fluor, center=center, /debug)
 endif else begin
     return, reconstruct_slice(0, tmp, /noring, /fluor, center=auto, /debug)
 endelse
end


function fluor_slice, file=file,name=name, center=center
   f   = read_escan_file(file)
   sino= f->get_map(name=name, norm='i0')
   if (keyword_set(center) ne 0) then begin
      return, fluor_reconstruct(sino, center=cen)
   endif else begin
      return, fluor_reconstruct(sino)
   endelse
end


pro ftomo2ascii, file=file, name=name, norm=norm,  center=center
;
; save an ascii file of a tomographic slice from an escan_data file
; containing an x,theta sinogram
;
; idl> ftomo2ascii, file = 'my_dat.001', name='Sr Ka', norm='i0'
;  
;   uses 'norm' channel to normalize data
;

   if (n_elements(file) eq 0) then begin
      print, 'must supply file name'
     return
   endif

   f = read_escan_file(file)

   if (keyword_set(name) eq 0) then begin
      print, 'must supply a detector name: one of these:'
      f->show_detectors
      return
   endif

   if (keyword_set(norm) eq 0) then begin
     map = f->get_map(name=name)
   endif else begin
     map = f->get_map(name=name,norm=norm)
   endelse

   if (keyword_set(center) ne 0) then begin
       recon = fluor_reconstruct(map, center=cen)
   endif else begin
       recon = fluor_reconstruct(map)
   endelse

   sz = size(recon)
   nx = sz[1]
   x   = f->get_x()
   y   = f->get_y()
   nx  = n_elements(x)
   ny  = n_elements(y)
   
   fout = file + '_' +  name + '.slice'
   
   
   openw,lun, fout,/get_lun
   printf,lun, '; Tomographic slice from ', file, '  for detector ', name
   printf,lun, '; ', nx, '  rows  by ', nx, ' columns'
   printf,lun, ';------------------------------------------'
   printf,lun, ';  '
   printf,lun, format='(a,$)', ';       '
   
   for j = 0, nx-1 do printf, lun, format='(1x,f12.5,$)',j
   printf, lun, ''
     
   for i=0, nx-1 do begin
       printf, lun, format='(1x,f11.3,$)', i
       for j = 0, nx-1 do printf, lun, format='(1x,f12.5,$)', recon[i,j]
       printf, lun, ''
   endfor
   
   close,lun
   free_lun,lun
  
print, 'wrote file ' ,  fout
return
end

pro ftomo_display, file=file, name=name, center=center
    image_display, fluor_slice(file=file, name=name,  center=center)
end




; tomo_display, file = 'tomo_44a31.006', name='Sr Ka'
