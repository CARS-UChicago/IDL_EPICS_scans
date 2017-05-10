function increment_scanname, inpfile, newfile=newfile
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
;
;
; M Newville  24 Jan 2000  /  14 Jun 2000
;
;  21 Mar 2002   added 'newfile' option which will continue
;                incrementing until the output filename does
;                not already exist
;
start:
outfile = ''
f       = getfilename(inpfile)
x       = strtrim(f.suffix, 2)
prefix  = strmid(f.name, 0, strpos(f.name, '.'+f.suffix))
if ((prefix eq '') and (strpos(inpfile,'.') lt 0)) then prefix=inpfile

on_ioerror, non_numeric
i  = fix(x) + 1
n  = strlen(strtrim(string(i),2)) > 3
n  = strtrim(string(n),2)
outfile = f.path + '\' + prefix + '.' + string(i,format='(i'+n+'.'+n+')')

goto, done

;
; NON NUMERIC
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
    outfile = f.path + '\' + f.name + '.001'
endif

;
; DONE
done:

if ((strmid(outfile,0,1) eq '\') and $
    (strmid(inpfile,0,1) ne '\') )   then outfile = strmid(outfile,1)

char1 = strmid(outfile,0,1)

if (char1 eq '.') then begin
    print, ' Strange error incrementing scan name '
    if (prefix eq '') then prefix = 'datafile'
    outfile = prefix + outfile
endif

outfile = strtrim(outfile, 2)

;
if (keyword_set(newfile)) then begin
    on_ioerror, io_error
    openr, lx, outfile, /get_lun
    st1   = fstat(lx)
    close, lx
    free_lun, lx
    inpfile = outfile
    goto, start
;
; IO ERROR  could not open file, so it must not exist...
io_error:
    x = 1 ; success
endif

return, outfile
end


