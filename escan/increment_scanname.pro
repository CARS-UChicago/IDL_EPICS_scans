function increment_scanname, inpfile
;
; increment a scan data file name
; strategy:  uses getfilename() 
;   first see if a number is before '.'.  if so, increment it.
;   second look for number in the prefix. if so, increment it.
;   lastly, insert a '_001' before the '.', preserving suffix.
; 
; note: the numerical part of the file name will contain 
;       at least three digits.
; examples:
;    increment_scanname('a.dat')        -> 'a.dat.001'
;    increment_scanname('a_001.dat')    -> 'a_002.dat'
;    increment_scanname('a.001')        -> 'a.002'
;    increment_scanname('a_102031.dat') -> 'a_103.dat'     !!!
;    increment_scanname('a_6.dat')      -> 'a_007.dat'
;    increment_scanname('a_001.002')    -> 'a_001.003'
;    increment_scanname('path/a.001')   -> 'path/a.002' 
;    increment_scanname('/path/a.001')  -> '/path/a.002' 
;
; (note the fortran-ish and suffix-preserving behavior!)
; 
; M Newville  24 Jan 2000  /  14 Jun 2000
;
outfile = ''
f       = getfilename(inpfile)
x       = strtrim(f.suffix, 2)
nsuffix = strpos(f.name, f.suffix)
prefix  = strmid(f.name, 0, nsuffix-1)

; help, f, /struct
; print, " : ", x, nsuffix, "     ", prefix

on_ioerror, non_numeric
i  = fix(x) + 1
n  = strlen(strtrim(string(i),2)) > 3
n  = strtrim(string(n),2)
outfile = f.path + '/' + prefix + '.' + string(i,format='(i'+n+'.'+n+')')
goto, done

non_numeric:
if (outfile eq '') and (f.number ne -1) then begin
    i  = f.number + 1
    n  = strlen(strtrim(string(i),2)) > 3
    n  = strtrim(string(n),2)
    m  = string(i,format='(i'+n+'.'+n+')')
    suffix = '.'  + f.suffix
    outfile = f.namestem + m + suffix
endif 
if ((outfile eq '') or (strlen(f.namestem) lt strlen(f.path))) then begin
    outfile = f.path + '/' + f.name + '.001'
endif

done:
; print, ' O2 = ' , outfile, ' n = ', n, i
; print, f
if ((strmid(outfile,0,1) eq '/') and $
    (strmid(inpfile,0,1) ne '/') )   then outfile = strmid(outfile,1)
return, outfile
end


