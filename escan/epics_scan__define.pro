; Mark Rivers, 12/7/00, added PREFIX keyword to INIT
; Mark Rivers, 12/8/00, only read positioner and detector arrays if they are valid,
; and only read "npts" values

function ca_put, pv, val
;
x = 0
x = caput(pv,val)
; print, ' CA_PUT ', pv
return, x
end

function epics_scan::beam_ok
;
;
r = 1
v = caget(self.beam_ok_pv, lock)
v = caget(self.shutter_pv, open)
if ((lock eq 0) or (open eq 0)) then r = 0

return, r
end


function epics_scan::get_current_dimension
v = self.prefix + 'ScanDim.VAL'
d = 0
x = caget(v,d)
return, d
end

pro epics_scan::pause_scan
v = self.prefix + 'scanPause.VAL'
x = ca_put(v,1)
self.cur_status   = 'Paused'
return
end

pro epics_scan::unpause_scan
v = self.prefix + 'scanPause.VAL'
x = ca_put(v,0)
self.cur_status   = ''
return
end


pro epics_scan::abort
;
v = self.prefix + 'AbortScans.PROC'
x = ca_put(v,1)
wait, 0.5
x = ca_put(v,0)
self.cur_status   = 'Aborted'
return
end

function epics_scan::is_scanning, dim=dim
;
if (keyword_set(dim) eq 0) then dim = 1
dim = dim-1 < 2 > 0
v = caget(self.scan[dim].scanpv + '.EXSC',ret)
return, ret
end

function epics_scan::cpt, dim=dim
;
if (keyword_set(dim) eq 0) then dim = 1
dim = dim-1 < 2 > 0
ret = 0
v = caget(self.scan[dim].scanpv + '.CPT',ret)
return, ret
end

function epics_scan::npts, dim=dim
;
if (keyword_set(dim) eq 0) then dim = 1
dim = dim-1 < 2 > 0
ret = 0
v   = caget(self.scan[dim].scanpv + '.NPTS',ret)
return, ret
end

function epics_scan::write_pv_list, lun=lun
;
; this reads the list of PVs in self.monitorfile and writes them out.
; if lun is specified, it writes to this unit (assumed opened for write)
; otherwise it writes to standard output
l_out = -999
if (keyword_set(lun) ne 0) then l_out = lun
ret = -1
tab = string(9B)
if (self.paramfile ne ' ') then begin
    on_ioerror, badfile
    ret = 0
    str = ' '
    openr, inp, self.monitorfile, /get_lun
    while not (eof(inp)) do begin
        readf, inp, str
        str  = strtrim(str,2)
        s   = strcompress(str)
        if (s eq ' ') then goto, loop_end
        ismc  = strpos(str, ';')
        ihash = strpos(str, '#')
        if ((ismc lt 0) and (ihash lt 0)) then begin
            sx    = str_sep(strcompress(str), ' ')
            if (n_elements(sx) lt 1) then goto, loop_end
            pv = sx[0]
            ti = pv
            il = strlen(pv)
            if (il le 3) then goto, loop_end
            if (n_elements(sx) gt 1) then begin
                tx = strtrim(strmid(str,strlen(sx[0]),strlen(str)),2)
                ti = tx +  " ("+ pv+ ')'
            endif else if (strupcase(strmid(pv,il-4,4)) eq '.VAL') then begin
                dv = strmid(pv,0,il-4) + '.DESC'
                stat = caget(dv, tn)
                if (stat eq 0) then ti = tn + " ("+ pv+ ')'
            endif
            stat = caget(pv, val)
            if (stat ne 0) then begin
                output = '; ' + ti + tab + " not connected "
            endif else begin
                output = '; ' + ti + tab + " = " + string(val)
            endelse
            if (l_out ge 0) then begin
                printf, l_out,  output
            endif else begin
                print, output
            endelse
        endif
        loop_end:
    endwhile
    close, inp
    free_lun, inp
    badfile: ret = -2
endif
return, ret
end

function epics_scan::close_scanfile
close, self.lun
free_lun, self.lun
self.lun = -3
return, 0
end


function epics_scan::write_to_scanfile, s
;
; write a single string to the current (already opened) scan file
catch, error
ret = -1
if (error ne 0) then return, ret
u   = strtrim(s,2)
if ((self.lun gt 0) and (strlen(u) ge 1)) then begin
    printf, self.lun, strtrim(s,2)
    ret = strlen(u)
endif 
return, ret
end

function epics_scan::open_scanfile, append=append

if (self.datafile eq ' ') then  self.datafile = 'scan_001.dat'
app  = 1
if (n_elements(append) ne  0)   then  app = append
openw,  lun,  self.datafile,  /get_lun, append=app

self.lun = lun
return, self.lun
end


function epics_scan::write_scan_data, short_labels=short_labels
;
; this reads the scan1 data from the crate, and writes the results
; out to self.lun (presumably, the already open scanfile)
;
ret = 0
SPV = self.scan[0].scanpv
write_labels  = 1
if (n_elements(short_labels) ne  0)   then  write_labels = short_labels
; print, ' write_scan_data,  labels = ' , write_labels
dat = self->read_data_from_crate()
lun = self.lun
mpos = n_elements(dat.p_used)
mdet = n_elements(dat.d_used)
npts = dat.npts
x    = self->lookup_positioners()

printf, lun, '; scan ended at time: ' , systime(0)
if (write_labels eq 1) then begin
    printf, lun, '; n_points      = ', npts
    printf, lun, '; column labels:'
endif
n = 0
label = '; '
for i  = 0,mpos-1 do begin
    if (dat.p_used(i) eq 1) then begin
        n    = n + 1
        sn   = strtrim(string(n,format='(i1.1)'),2)
        if (write_labels eq 1) then begin
            com  = '; P' + sn + ' = {'
            desc = self.scan[0].pos_names[i]
            printf, lun, com, desc , '} --> ', self.scan[0].posPVs[i]
        endif
        label = label + ' P' + sn
    endif
endfor

n = 0
for i  = 0, mdet-1 do begin
    if (dat.d_used(i) eq 1) then begin
        n    = n + 1
        sn   = strtrim(string(n),2)
        if (write_labels eq 1) then begin
            com  = '; D' + sn + ' = {'
            desc = self.detectors.desc[i]
            printf, lun, com, desc , '}  --> ', self.detectors.countPV[i]
        endif
        label = label + ' D' + sn
    endif
endfor
if (write_labels eq 1) then begin
    printf, lun, ';--------------------------------------------'
    printf, lun, label
endif else begin
    printf, lun, ';----------------'
    printf, lun, '; '
endelse


for i = 0,  npts-1  do  begin
    printf, lun,  format='(1x,g14.7,$)', dat.pa[ 0,i]
    for j = 1, mpos -1 do begin
        if (dat.p_used(j) eq 1) then printf, lun,  format='(1x,g14.7,$)', dat.pa[ j,i]
    endfor
    for j = 0, mdet-1 do begin
        if (dat.d_used(j) eq 1) then printf, lun,  format='(1x,g14.7,$)', dat.da[ j,i]
    endfor
    printf, lun, ' '
endfor

; flush file buffer for sure
flush, lun
return, ret
end

function epics_scan::start_scan1d, no_file=no_file, no_pv_list=no_pv_list,$
                   user_titles=user_titles, no_header=no_header
                   
;  begin scan1d (this __only__ does a 1d scan!!)
stime  = systime(0)

; check shutter status: if closed, then do NOT scan
; and return -1
; print, '  In start_scan1d'

r = caget(self.shutter_pv, shutter)
; if ((shutter ne 1) or (r ne 0)) then return, -1

;
; print, ' starting ', self.scan[0].scanpv 

; always explicitly set auto-wait for client
user_wait = 0
if (self.save_med) then user_wait = 1 
result = ca_put(self.scan[0].scanpv + '.AWCT',user_wait)

; start scan
result = ca_put(self.scan[0].scanpv + '.EXSC', 1)

if (self.lun lt -2) then begin
    x  = self->open_scanfile(/append)
endif
lun = self.lun

if (result ne 0) then return, result
write_file = 1
if (keyword_set(no_file)) then  write_file = 0
write_pvlist = 1
if (keyword_set(no_pv_list)) then  write_pvlist= 0
write_header = 1
if (keyword_set(no_header)) then  write_header= 0

if (write_file) then begin
    if (write_header eq 1) then begin
        printf, lun, ';  current scan  = ', f2a(self.current_scan)
        printf, lun, ';  scan dimension= ', f2a(self.dimension)
        printf, lun, ';  scan prefix   = ', self.prefix 
        if (keyword_set(user_titles)) then begin
            printf, lun, '; User titles:'
            for i = 0, n_elements(user_titles) - 1 do  begin
                s = strcompress(strtrim(user_titles[i],2))
                if (s ne ' ') then printf, lun, '; ' + user_titles[i]
            endfor
        endif
        if (write_pvlist) then  begin
            printf, lun, '; PV list:'
            x = self->write_pv_list(lun=lun)
        endif
        printf, lun, '; scan began at time: ', stime
        printf, lun, ';====================================================='
    endif
    self.lun = lun
endif
; print, '   start_scan1d result = ', result, lun
flush, lun
return, result
end


function epics_scan::check_scan_limits
;  check scan limits
y   = self.scan[self.current_scan-1].scanpv 
print, 'checking scan limits for scan ',y
x1  = ca_put(y + '.CMND', 1)
wait, 0.25
x   = caget(y + '.ALRT', ret)
if (x ne 0) then begin
    wait, 0.5
    x   = caget(y + '.ALRT', ret)
    if (x ne 0) then ret = x
endif
return, ret
end

function epics_scan::get_npts_total
;  get total number of points in scan
n = 1
for is = 0, self.dimension-1 do  n = n * self.scan[is].npts_total
return, n
end

function epics_scan::generate_scan_table, iscan, arr
n = 0
; print, ' <   Generating Scan Table ', iscan

sc       = self.scan[iscan]
nregs    = sc.n_regions
is_rel   = sc.is_rel
time_est = 0.0000 
delays   = sc.ddly  + sc.pdly
ETOK     = 0.2624682917
ref      = 0
e0       = sc.params[0]
if (sc.is_rel eq 1) then begin
    ref = sc.params[0]
    if (strupcase(sc.type) eq 'MOTOR') then begin
        mot = self->get_motor(sc.drives[0])   
        ref = mot.curpos
    endif
endif
; 
; print, ' gen_scan:  is_rel, ref  = ', sc.is_rel, ref, sc.type

; positioner #1  is the primary drive
arr = fltarr(4,self.max_scan_points)
ip  = -1
for j = 0, nregs-1 do begin
    ; print, ' reg ', j, ' of ', nregs
    ; print, 'start/stop/step/npts/time  '
    ; print, sc.start[j], sc.stop[j], sc.step[j], sc.npts[j], sc.time[j]
    for i = 0, sc.npts[j]-1 do begin
        ip        = ip + 1
        arr[0,ip] = ref + sc.start[j] + sc.step[j]*i 
        if (sc.is_kspace[j] eq 1) then begin
            ; note that the k-space values are _always_ relative, 
            ; so need to use e0, not ref.  tricky, huh?
            arr[0,ip] = e0  + (sc.start[j] + sc.step[j]*i)^2  / ETOK
        endif
        arr[1,ip] = sc.time[j]
        time_est  = time_est + sc.time[j] + delays
    endfor
    ; fix scan region boundaries from repeating points:
    ; remove the last point of the earlier region
    if (ip ge 0) and (j lt nregs-1) then begin
        ip       = ip - 1
        time_est = time_est - ( sc.time[j] + delays )
    endif
endfor
n = ip + 1
; print, ' Npts = '  , n, '  time = ', time_est, ' s'
; for i = 0, n-1 do begin
;     print, ' > ', i, arr[0,i], ' : ', arr[1,i]
; endfor


self.scan[iscan].time_est = time_est

return, n
end


function epics_scan::write_med_file, pt=pt, pt2=pt2, file=file
; 
retval = -1
if (obj_valid(self.med_obj)) then begin
    if (keyword_set(file) eq 0) then begin
        if (keyword_set(pt)  ne 0) then  pt = 0
        if (keyword_set(pt2) ne 0) then  pt2 = 0

        file = self.datafile  + '__'+ string(pt+1,format='(i3.3)')
        x    = caget(self.prefix + 'ScanDim.VAL', curdim)
        if (curdim ge 2) then file = file + '_'+ f2a(pt2+1)
        file = file + '.xrf'
    endif
    am_waiting  = self->check_scan_wait()
    print, ' saving XRF spectra to ', file
    self.med_obj->write_file, file
    retval  = 0
    if (am_waiting) then retval = self->clear_scan_wait()
endif 
return, retval
end


function epics_scan::check_scan_wait
wait = 0
x = caget(self.scan[0].scanpv + '.WTNG', wait)
return, wait
end

function epics_scan::clear_scan_wait
x = caget(self.scan[0].scanpv + '.WAIT', 0)
return, x
end

function epics_scan::read_data_from_crate
;
;  upload 1d scan results from crate
;  returns structure with members
;    npts     number of points collected
;    p_used   integer array for positioners  used
;    d_used   integer array for detectors  used
;    npos     number of positions used
;    pa      (npts,npos)
;    da      (npts,ndet)
;  pauses scan while reading!
SPV   = self.scan[0].scanpv
; Pause Scan for read
x     = caget(self.prefix + 'scanPause.VAL', pause_val)
x     = ca_put(self.prefix + 'scanPause.VAL', 1)

;
M_DET  = n_elements(self.detectors.countPV)
M_POS  = n_elements(self.scan[0].drives)
p_used = intarr(M_POS)
d_used = intarr(M_DET)
s      = caget(SPV+'.NPTS', npts)
;  print, ' scan: npts = ', npts
ret    = {npts:0, p_used:p_used, d_used:d_used, $
          pa:fltarr(M_POS,npts), da:fltarr(M_DET,npts)}
;
; gather scan data
for i = 0, M_POS-1 do begin
    d = string(i+1,format='(i1.1)') 
    s = caget(SPV + '.P' + d + 'NV', ix)
    if (ix eq 0) then begin
        ret.p_used(i) = 1
        s = caget(SPV + '.P' + d + 'RA', p, max=npts)
        for j=0, npts-1 do ret.pa[i, j] = p[j]
    endif

endfor
for i = 0, M_DET-1 do begin
    ; d   =  string(i+1,format='(i1.1)') 
    ; if (i ge 9) then  d = string(byte(i + 56))
    ; Matt 26-Sept-2000 switch to 70 detector scan record
    d =  string(i+1,format='(i2.2)') 
    s = caget(SPV + '.D' + d + 'NV', ix)
    if (ix eq 0) then begin
        ret.d_used(i) = 1
        x = caget( SPV + '.D' + d + 'DA', p, max=npts)
        for j=0, npts-1 do ret.da[i, j] = p[j]
    endif
endfor
ret.npts = npts
; Un-Pause Scan before return
x       = ca_put(self.prefix + 'scanPause.VAL', pause_val)
return, ret
end

function epics_scan::load_to_crate
;
; load a motor scan record to the crate
; 

; print, 'LOAD: current_scan ', self.current_scan,  '  dim: ', self.dimension

time_est = 0.000

for is = 0, self.dimension-1 do begin
    ; print, 'LOAD >> scan  ', is, ' << '
    imot   = self.scan[is].drives[0]
    SPV    = self.scan[is].scanpv
    type   = self.scan[is].type
    if (strupcase(self.scan[is].type) eq 'EXAFS') then imot = self.motors.e_drive

    x = ca_put( SPV + '.PASM', self.scan[is].pasm) ;  'Prior Pos' after scan
                                    ; [stay, start, prior, peak, valley, +edge, -edge]
    ; print, ' delays= ', self.scan[is].pdly, self.scan[is].ddly
    x = ca_put( SPV + '.PDLY', self.scan[is].pdly)
    x = ca_put( SPV + '.DDLY', self.scan[is].ddly)
    x = ca_put( SPV + '.P1AR', 0)    ;  always use 'Absolute mode'
    x = ca_put( SPV + '.P1SM', 1)    ;  always use table mode
    nx  = self->generate_scan_table(is, pos)
    self.scan[is].npts_total = nx
    ; help, pos
    ; print, " nx      = ", nx, ' table 0, table 1'
    ; print,  pos[0:1,0:nx-1] 
    ; print, " scan ", is+1, ' npts = ', nx, ' estimated time = ', self.scan[is].time_est
    ;print, self.motors.pv[imot], "  > ", self.motors.rbv[imot]

    x = ca_put( SPV + '.P1PV', self.motors.pv[imot]) ;
    x = ca_put( SPV + '.R1PV', self.motors.rbv[imot]) ;
    x = ca_put( SPV + '.P1PA', pos[0,0:nx-1]) ;
    x = ca_put( SPV + '.NPTS', nx)            ;  
    self.scan[is].pos_names[0] = self.motors.name[imot]

;
; for scan1 (is = 0):
;     setup the detector triggers, pos2 and pos3 arrays for count times
;                     
    if (is eq 0) then begin
        ; 
        ;  detector triggers:
        ;
        itrig      = 0
        scaler_set = 0
        med_set    = 0
        x = ca_put(SPV + '.T1PV', '')
        x = ca_put(SPV + '.T2PV', '')
        self.scan[is].pos_names[1] = ''
        self.scan[is].pos_names[2] = ''
        self.scan[is].pos_names[3] = ''
        for i = 0, n_elements(self.detgroups.name) - 1 do begin
            prex = self.detgroups.prefix[i]
            usex = self.detgroups.use_det[i]
            coux = prex + self.detgroups.counterpv[i]
            rbvx = coux
            trix = prex + self.detgroups.triggerpv[i]
                                ; print, ' detector: ', i, ' ', prex, usex, trix
            if (usex eq 1) then begin
                itrig = itrig + 1
                st_t  = string(itrig,format='(i1.1)')
                                ; print, ' TRIGGER  ', itrig, trix
                SPV_t = SPV + '.T' + st_t   + 'PV'
                x = ca_put(SPV_t, trix)
                if ((scaler_set eq 0) and (strpos(trix,'scaler') ne -1)) then begin
                                ;print , ' SCALER '
                    rbvx = strmid(coux,0, strlen(coux)-1)
                    x = ca_put( prex  + '.CONT', 0) ; put scaler in one-shot mode
                    x = ca_put( SPV + '.P2PV', coux)
                    x = ca_put( SPV + '.R2PV', rbvx)
                    x = ca_put( SPV + '.P2PA', pos[1,0:nx-1])
                    x = ca_put( SPV + '.P2AR', 0) ;  always use 'Absolute mode'
                    x = ca_put( SPV + '.P2SM', 1) ;  always use table mode
                    scaler_set = 1
                    self.scan[is].pos_names[1] = 'Scaler Count Time'
                endif else if ((med_set eq 0) and (strpos(trix,'med') ne -1)) then begin 
                                ;print , ' MED '
                    x = ca_put( prex + 'ReadSeq.SCAN', 0) ; set med to 'passive read rate'
                    x = ca_put( prex + 'StatusSeq.SCAN', 8) ; set med status rate to 0.2s
                    x = ca_put( prex + 'PresetReal', count_time) ; set med count time
                    x = ca_put( SPV + '.P3PV', coux)
                    x = ca_put( SPV + '.R3PV', rbvx)
                    x = ca_put( SPV + '.P3PA', pos[1,0:nx-1])
                    x = ca_put( SPV + '.P3AR', 0) ;  always use 'Absolute mode'
                    x = ca_put( SPV + '.P3SM', 1) ;  always use table mode
                    self.scan[is].pos_names[2] = 'MCA Count Time'
                    med_set = 1
                endif
            endif
        endfor
    endif else begin
        x = ca_put( SPV + '.T1PV',  self.scan[is-1].scanpv + '.EXSC')
    endelse
endfor

result  = self->check_scan_limits()
message = '  Ready to scan '
if (result ne 0) then begin
    message = ' Problem with Scan Definition:  Check Limits '
    print , ' SPV = ', SPV
    print , ' is  = ', is
    print , ' scan 2 = ', self.scan[1].scanpv
    print , ' scan 1 = ', self.scan[0].scanpv
endif

print, format='(1x,a,$)', message
return, result
end

function epics_scan::save_paramfile, use_dialog=use_dialog
  init_file = self.paramfile
  file      = init_file
; empirically determine ranges of data structures
  MAX_DET   = n_elements(self.detectors.countPV)
  MAX_MOT   = n_elements(self.motors.pv)
  xs        = size(self.scan[0].start)
  MAX_REG   = xs[1]
  MAX_POS   = xs[2]
  MAX_PAR   = n_elements(self.scan[0].params)
  frm_s0    = '(a,' +strtrim(string(MAX_REG),2) + 'f10.3)'
  frm_s1    = '(a,' +strtrim(string(MAX_REG),2) + 'g13.7)'
  frm_s2    = '(a,' +strtrim(string(MAX_PAR),2) + 'g13.7)'

  if (keyword_set (use_dialog)) then begin
      file = dialog_pickfile(filter='*.scn', get_path=path, $
                             /write, file = init_file)
  endif
  file  = strtrim(file,2)
  if (file eq '') then return, -1
  self.paramfile = file
  openw, lun,  file, /get_lun
  printf, lun,  ';Scan Parameters% v1.1'
  printf, lun,  ' prefix%       ',  self.prefix
  printf, lun,  ' shutter_pv%   ',  self.shutter_pv
  printf, lun,  ' shutter_open% ',  self.shutter_open
  printf, lun,  ' shutter_clos% ',  self.shutter_clos
  printf, lun,  ' beam_ok_pv%   ',  self.beam_ok_pv
  printf, lun,  ' datafile%     ',  self.datafile
  printf, lun,  ' monitorfile%  ',  self.monitorfile
  printf, lun,  ' dimension%    ',  self.dimension
  printf, lun,  ' save_med%     ',  self.save_med  
  printf, lun,  ' current_scan% ',  self.current_scan 
  for iscan = 0, 2 do begin
      scanname = 'scan  ' + string(iscan+1, format='(i1.1)')
      printf, lun, format='(";",a," %")', scanname
      printf, lun, format='("  scanpv%   ",a)',  self.scan[iscan].scanpv
      printf, lun, '  type%     ',  self.scan[iscan].type
      printf, lun, '  drives%   ',  string(self.scan[iscan].drives) + ' '
      printf, lun, '  n_regions%',  self.scan[iscan].n_regions
      printf, lun, '  is_rel%   ',  self.scan[iscan].is_rel
      printf, lun, '  delays%   ',  self.scan[iscan].pdly,  self.scan[iscan].ddly
      printf, lun, format=frm_s0, "  is_kspace%" ,  self.scan[iscan].is_kspace
      printf, lun, format=frm_s2, "  params%  ", self.scan[iscan].params
      printf, lun, format=frm_s0, "  time%    ", self.scan[iscan].time
      printf, lun, format=frm_s0, "  npts%    ", self.scan[iscan].npts
      for i = 0, MAX_POS-1 do begin
          printf, lun, '  pos%    ', string(i, format='(i1.1)'), ' '
          printf, lun, format=frm_s1, "    start% ", self.scan[iscan].start(*,i)
          printf, lun, format=frm_s1, "    stop%  ", self.scan[iscan].stop(*,i)
          printf, lun, format=frm_s1, "    step%  ", self.scan[iscan].step(*,i)
      endfor
  endfor
; write Motor PVs and Names (but not anything else from motor struct!)
  printf, lun,  ';motors% ', MAX_MOT
  for i = 1, MAX_MOT-1 do begin
      if (self.motors.name[i] ne '') then begin
          printf, lun,  '   ', self.motors.pv[i], '  | ', $
            self.motors.name[i]
      endif
  endfor
; write detector groups
  printf, lun,  ';detgroups%' , (n_elements(self.detgroups.name))
  for i = 0, n_elements(self.detgroups.name)-1 do begin
      if (self.detgroups.name[i] ne '') then begin
          s =  self.detgroups.name[i]       + ' | ' $ 
            +  self.detgroups.prefix[i]     + ' | ' $ 
            +  self.detgroups.triggerpv[i]  + ' | ' $ 
            +  self.detgroups.counterpv[i]  + ' | ' $ 
            +  f2a(self.detgroups.max_elems[i])  + ' | ' $ 
            +  f2a(self.detgroups.is_mca[i])      + ' | ' $ 
            +  f2a(self.detgroups.use_det[i] )    
            printf, lun,  '   ', s
      endif
  endfor


; write detector Count and Name PVs
  printf, lun,  ';detectors%' , (MAX_DET< self.detectors.ndetectors)
  for i = 0, MAX_DET-1 do begin
      if (self.detectors.countPV[i] ne '') then begin
          printf, lun,  '   ', self.detectors.countPV[i]
      endif
  endfor

  close, lun
  free_lun, lun
  print, ' wrote file = ', file
  return, 0
end

function epics_scan::read_paramfile, use_dialog=use_dialog, file=file
;
;  read scan file to (re)initialize epics_scan object
;  returns 0 for apparent succees, <0 for bad or unfound files
;
  s_file = self.paramfile
  if (keyword_set(file) ne 0) then s_file =  file

  if (keyword_set (use_dialog)) then begin
      s_file = dialog_pickfile(filter='*.scn', get_path=path, $
                               /must_exist, /read, file = s_file)
  endif
  retval = -3
  s_file  = strtrim(s_file,2)
  if (s_file eq '') then return, -2
  self.paramfile = s_file
  on_ioerror, bad_file
  openr, lun,  s_file, /get_lun
  retval  = 0
  read_det= 0
  nline   = 0
  ipos    = 0
  str     = ' '
  mode    = 'null'
  n_det   = -1
  n_dgrp  = -1
  n_mot   =  0
  for i = 0, n_elements(self.motors.name)-1 do begin
      self.motors.pv[i]   =  ''
      self.motors.name[i] =  ''
  endfor
  self.motors.name[0] =  'None'
;
  line1  =  1
  while not (eof(lun)) do begin
       readf, lun, str
       str  = strtrim(str,2)
       if ((str eq '') or (strmid(str, 0, 1)  eq '#')) then goto, loop_end
       if (line1 eq 1) then begin
           line1 = 0
           s = strmid(str, 0, 17) 
           t = strmid(str, 18, strlen(str)) 
           if (s ne ';Scan Parameters%') then begin
               print, ' File ', s_file,  ' is not a valid scan file'
               retval = -1
               goto, ret
           endif
           version = t
       endif
       iperc = strpos(str, '%')
       ismc = strpos(str, ';')
       if ((ismc eq 0) and (iperc ge 0)) then begin
           s    = strmid(str,ismc+1, iperc-1)
           mode = s
           iscan= 0
           ipos = 0
           stmp = strmid(s,0,4) 
           if (stmp eq 'scan') then begin
               stmp = strcompress(s)
               sx   = str_sep(stmp,' ')
               mode  = 'scan'
               iscan = fix(strtrim(sx[1],2)) - 1
               ipos  = 0
           endif
       endif else begin
           key = strlowcase(strmid(str,0, iperc))
           val = strtrim(strmid(str,iperc+1, strlen(str)), 2)
           case mode of 
               'Scan Parameters': begin
                  case key of 
                      'prefix':         self.prefix      = val
                      'datafile':       self.datafile    = val
                      'beam_ok_pv':     self.beam_ok_pv  = val
                      'shutter_pv':     self.shutter_pv  = val
                      'shutter_clos':   self.shutter_clos= val
                      'shutter_open':   self.shutter_open= val
                      'monitorfile':    self.monitorfile = val
                      'current_scan':   self.current_scan= val
                      'dimension':      self.dimension   = val
                      'save_med':       self.save_med    = val
                      'total_time':     self.total_time  = val
                      else: print, ' unknown key for Main: ', key
                  endcase
              end
              'scan': begin
                  case key of
                      'scanpv':    self.scan[iscan].scanpv    = val
                      'type':      self.scan[iscan].type      = val
                      'n_regions': self.scan[iscan].n_regions = val
                      'is_rel':    self.scan[iscan].is_rel    = val
                      'pos':     ipos = fix(val)
                      'delays': begin
                          n = string_array(val,arr)
                          self.scan[iscan].pdly = arr[0]
                          self.scan[iscan].ddly = arr[1]
                      end
                      'drives': begin
                          n = string_array(val,arr)
                          for i = 0, n-1 do $
                              self.scan[iscan].drives[i] = arr[i]
                      end
                      'params': begin
                          n = string_array(val,arr)
                          for i = 0, n-1 do $
                            self.scan[iscan].params[i] = arr[i]
                      end
                      'is_kspace': begin
                          n = string_array(val,arr)
                          for i = 0, n-1 do $
                            self.scan[iscan].is_kspace[i] = arr[i]
                      end
                      'time': begin
                          n = string_array(val,arr)
                          for i = 0, n-1 do $
                            self.scan[iscan].time[i] = arr[i]
                      end
                      'npts': begin
                          n = string_array(val,arr)
                          for i = 0, n-1 do $
                            self.scan[iscan].npts[i] = arr[i]
                      end
                      'start': begin
                          n = string_array(val,arr)
                          for i = 0, n-1 do $
                            self.scan[iscan].start[i,ipos] = arr[i]
                      end
                      'stop': begin
                          n = string_array(val,arr)
                          for i = 0, n-1 do $
                            self.scan[iscan].stop[i,ipos] = arr[i] 
                      end
                      'step': begin
                          n = string_array(val,arr)
                          for i = 0, n-1 do $
                            self.scan[iscan].step[i,ipos] = arr[i]
                      end
                      else: print, ' unknown key for scan: ', key
                  endcase
              end
              'detgroups': begin
                  n_dgrp = n_dgrp + 1
                  stmp  = strcompress(val)
                  sx    = str_sep(stmp,'|')
                  self.detgroups.name[n_dgrp]      = strtrim(sx[0],2)
                  self.detgroups.prefix[n_dgrp]    = strtrim(sx[1],2)
                  self.detgroups.triggerpv[n_dgrp] = strtrim(sx[2],2)
                  self.detgroups.counterpv[n_dgrp] = strtrim(sx[3],2)
                  self.detgroups.max_elems[n_dgrp] = strtrim(sx[4],2)
                  self.detgroups.is_mca[n_dgrp]    = a2f(sx[5])
                  self.detgroups.use_det[n_dgrp]   = a2f(sx[6])
              end
              'detectors': begin
                  read_det = 1
                  n_det = n_det + 1
                  self.detectors.countPV[n_det]  = val
              end
              'motors': begin
                  n_mot = n_mot + 1
                  stmp  = strcompress(val)
                  sx    = str_sep(stmp,'|')
                  self.motors.pv[n_mot]   =  strtrim(sx[0],2) 
                  if (n_elements(sx) ge 2) then begin
                      self.motors.name[n_mot] =  strtrim(sx[1],2) 
                  endif else begin
                      il   = strlen(self.motors.pv[n_mot])
                      dv   = strmid(self.motors.pv[n_mot],0,il-4) + '.DESC'
                      stat = caget(dv, tn)
                      if (stat eq 0) then  self.motors.name[n_mot] = tn
                  endelse
              end
              else: begin
                  print, ' unknown mode ', mode
              end
          endcase
      endelse
      loop_end:
  endwhile
ret:
  if (read_det eq 1) then   x = self->set_param('detectors',self.detectors)
  close, lun
  free_lun, lun
  return, retval
bad_file:
  print,  ' '
  print, '  Warning: scan parameter file ', s_file,  ' could not be loaded.'
  return, retval
end

function epics_scan::lookup_detectors
;
;  get detector valuse from the currently loaded scan ...
;  used for initializing detector structure

scan_pv = self.scan[0].scanpv
ndet    = 0
; print, '  IN  look up detectors: ',  n_elements(self.detectors.countPV) 
str  = ''
for i = 0, n_elements(self.detectors.countPV)-1 do begin
    ; det  =  string(i+1,format='(i1.1)') 
    ; if (i ge 9) then  det = string(byte(i + 56))
    ; Matt 26-Sept-2000 switch to 70 detector scan record
    det  =  string(i+1,format='(i2.2)') 
    x = caget(scan_pv + '.D' + det + 'PV', str)
    if ((x eq 0) and (str ne '')) then begin
        ds = strtrim(str,2)
        if (ds ne str) then x = ca_put(scan_pv + '.D' + det + 'PV', ds)
        str = ds
    endif else  begin
        str = ''
    endelse
    ;
    if (str ne '') then begin
        self.detectors.countPV[ndet]  = str        
        desc   = guess_det_desc(pv=str,net=net)
        self.detectors.desc[ndet] = desc
        igroup = -1
        for ig = 0, n_elements(self.detgroups.prefix)-1 do begin
            pr = self.detgroups.prefix[ig]
            if ((self.detgroups.use_det[ig] eq 1) and $
                (strmid(str,0,strlen(pr)) eq pr)) then igroup = ig
        endfor
        self.detectors.use_net[ndet] = net
        self.detectors.desc[ndet]    = desc
        self.detectors.group[ndet]   = igroup
        ; print, 'Fill Det: ', i, ' ' , str, ' | ', desc, igroup, net
        ndet  = ndet + 1
    endif 
endfor
self.detectors.ndetectors = ndet
return, ndet
end

function epics_scan::lookup_positioners
;
;  get positioner PVs
;
scan_pv = self.scan[0].scanpv
for i = 0, n_elements(self.scan[0].drives)-1 do begin
    pos  =  string(i+1,format='(i1.1)') 
    x = caget(scan_pv + '.P' + pos + 'PV', str)
    if ((x eq 0) and (str ne '')) then begin
        self.scan[0].posPVs[i] = str
    endif
endfor
return, 0
end

function epics_scan::lookup_motors
;
;  get motor settings for all defined motors 
;
for i = 1, n_elements(self.motors.name)-1 do  x = self->lookup_motor(i)
return, 0
end

function epics_scan::lookup_motor, i
;
; get motor settings for a particular motor (by index),
; and put them in the proper motor structure members
; returns:
;     0  complete success
;    -1  some caget failed
;    -2  null motor specified
;    -4  motor index out of range
if ((i le 0) or (i ge n_elements(self.motors.name))) then return, -4

pv = strtrim(self.motors.pv[i],2 )
if (pv eq '' )  then return, -3
il = strlen(pv)
if (strupcase(strmid(pv,il-4,4)) eq '.VAL') then pv = strmid(pv,0,il-4)
;;  print, ' lookup_motor ', i,  '  = ', pv
;
;  pv and rbv's
self.motors.pv[i]  = pv + '.VAL'
self.motors.rbv[i] = pv + '.RBV'
; current position
s  = caget(pv + '.RBV', x)
if (s ne 0 ) then return, -1
self.motors.curpos[i] = x
; name (if not pre-defined)
if (self.motors.name[i] eq '') then begin
    s  = caget(pv + '.DESC', x)
    if (s ne 0 ) then return, -1
    self.motors.name[i] = x
endif
; units
s  = caget(pv + '.EGU', x)
if (s ne 0 ) then return, -1
self.motors.units[i] = x
; limits
if (strpos(pv,'Energy') ne -1) then begin
    pvx = self.motors.rbv[i]
    n   = strpos(pvx,'Energy')
    self.motors.rbv[i]  = self.motors.pv[i]
    self.motors.hlim[i] = 35000.00 
    self.motors.llim[i] =  4000.00 
endif else begin
    s  = caget(pv + '.LLM', x)
    if (s ne 0 ) then return, -1
    self.motors.llim[i] = x
    s  = caget(pv + '.HLM', x)
    if (s ne 0 ) then return, -1
    self.motors.hlim[i] = x
endelse
; done
return,0
end


function epics_scan::get_motor, imotor
;
; returns a simple motor struct for a specified motor
;
mot = {name: ' ',  pv: ' ', rbv: ' ', units:' ', $
       curpos:0.,  llim:0.,  hlim:0.}
;---------
im = 1
if (keyword_set(imotor) ne 0) then im = imotor
mot.name  = self.motors.name[im]
mot.pv    = self.motors.pv[im]
mot.rbv   = self.motors.rbv[im]
mot.units = self.motors.units[im]
mot.curpos= self.motors.curpos[im]
mot.llim  = self.motors.llim[im]
mot.hlim  = self.motors.hlim[im]
;print, ' { get_motor: ', im
;help, mot, /struct
;print, ' } '
return, mot
end


function epics_scan::get_motor_position, imotor
;
; returns and updates current motor position
im = 1
if (keyword_set(imotor) ne 0) then im = imotor

res = caget(self.motors.rbv[im], xx)

self.motors.curpos[im] = xx

return, xx
end

function epics_scan::set_motor, imotor, mot
;
; sets a motor struct for a specified motor  
;
;----
retval = -1
if (keyword_set(imotor) ne 0) then begin
    retval = 0
    self.motors.name[imotor]    = mot.name  
    self.motors.pv[imotor]      = mot.pv    
    self.motors.rbv[imotor]     = mot.rbv   
    self.motors.units[imotor]   = mot.units 
    self.motors.curpos[imotor]  = mot.curpos
    self.motors.llim[imotor]    = mot.llim  
    self.motors.hlim[imotor]    = mot.hlim  
endif
return, retval
end


function epics_scan::get_scan_param, iscan, par
;
; returns a single attribute of a particular scan
;
retval = 0
is = 0
if (keyword_set(iscan) ne 0) then is = iscan
if (keyword_set(par) ne 0) then begin
    case par of
        'scanpv':       retval = self.scan[is].scanpv
        'type':         retval = self.scan[is].type
        'max_points':   retval = self.scan[is].max_points
        'n_regions':    retval = self.scan[is].n_regions
        'drives':       retval = self.scan[is].drives
        'pos_names':    retval = self.scan[is].pos_names
        'start':        retval = self.scan[is].start
        'stop':         retval = self.scan[is].stop
        'step':         retval = self.scan[is].step
        'npts':         retval = self.scan[is].npts
        'time':         retval = self.scan[is].time
        'params':       retval = self.scan[is].params
        'is_rel':       retval = self.scan[is].is_rel
        'is_kspace':    retval = self.scan[is].is_kspace
    endcase
endif
return, retval
end


function epics_scan::get_detector_list, pv=pv,desc=desc
;
; return string array of non-null detectors in use
; returns either list of pvs or list of descriptions
;
use_desc  = 1
if (keyword_set(pv)   ne 0) then use_desc = 0
if (keyword_set(decs) ne 0) then use_desc = 1

out= ['']
nd = n_elements(self.detectors.desc)
if (nd le 1) then return, out

l  = strarr(nd)
j  = -1
for i = 0, nd - 1 do begin
    if (self.detectors.desc[i] ne '') then  begin
        j    = j + 1
        l[j] = self.detectors.desc[i]
    endif
endfor

if (j ge 0) then begin
    out = strarr(j+1)
    for i = 0, j do  out[i] = l[i]
endif
return, out

end


function epics_scan::get_param, par
;
; return a copy of an object member structure
; for outside manipulation and later 'set_param'ing
val = 0
if (keyword_set(par) ne 0) then begin
    case par of
        'prefix':       val = self.prefix
        'lun':          val = self.lun
        'dimension':    val = self.dimension
        'total_time':   val = self.total_time
        'paramfile':    val = self.paramfile
        'detgroups':    val = self.detgroups
        'datafile':     val = self.datafile
        'beam_ok_pv':   val = self.beam_ok_pv
        'shutter_pv':   val = self.shutter_pv
        'shutter_clos': val = self.shutter_clos
        'shutter_open': val = self.shutter_open
        'monitorfile':  val = self.monitorfile
        'detectors':    val = self.detectors
        'ndetectors':   val = self.detectors.ndetectors
        'current_scan': val = self.current_scan
        'motors':       val = self.motors
        'scan1':        val = self.scan[0]
        'scan2':        val = self.scan[1]
        'scan3':        val = self.scan[2]
        'npts_total':   val = self->get_npts_total()
        'med_obj':      val = self.med_obj
        'save_med':     val = self.save_med
    endcase
endif

return, val
end

function epics_scan::set_param, par, val
retval = 0
if (keyword_set(par) ne 0) then begin
    retval  = 1
    case par of
        'prefix':       self.prefix       = val
        'lun':          self.lun          = val
        'dimension':    self.dimension    = val
        'total_time':   self.total_time   = val
        'paramfile':    self.paramfile    = val
        'datafile':     self.datafile     = val
        'monitorfile':  self.monitorfile  = val
        'beam_ok_pv':   self.beam_ok_pv   = val
        'shutter_pv':   self.shutter_pv   = val
        'shutter_clos': self.shutter_clos = val
        'shutter_open': self.shutter_open = val
        'detgroups':    self.detgroups    = val
        'current_scan': self.current_scan = val
        'motors':       self.motors       = val
        'scan1':        self.scan[0]      = val
        'scan2':        self.scan[1]      = val
        'scan3':        self.scan[2]      = val
        'save_med':     self.save_med     = val
        'detectors':    begin
            self.detectors   = val
            SPV  = self.scan[0].scanpv
            for i = 0, n_elements(self.detectors.countPV) - 1 do begin
                det  =  string(i+1,format='(i2.2)') 
                x = ca_put( SPV + '.D' + det + 'PV', self.detectors.countPV[i])
            endfor
        end
        else:           retval = 0
    endcase
endif
return, retval
end

function epics_scan::init, prefix=prefix, scan_file=scan_file, use_dialog=use_dialog
;
@scan_dims
;
caSetTimeout, 0.005
caSetRetryCount, 200

if (n_elements(prefix) eq 0) then prefix='13IDC:'
self.prefix            =  prefix
self.paramfile         = 'default.scn'
self.datafile          = 'scan_001.dat'
self.monitorfile       = 'scan_pvs.dat'
self.beam_ok_pv        = '13IDA:mono_pid1Locked'
self.shutter_pv        = '13IDA:eps_mbbi4'
self.shutter_clos      = '13IDA:eps_bo4'
self.shutter_open      = '13IDA:eps_bo3'
self.user_comments     = ''
self.cur_status        = ''
self.save_med          = 0
self.current_scan      = 1
self.dimension         = 1
self.max_scan_points   = MAX_SCAN_POINTS

self.detgroups.name[0]          = 'Scaler'
self.detgroups.use_det[0]       = 1
self.detgroups.prefix[0]        = '13IDC:scaler1.'
self.detgroups.max_elems[0]     = 8
self.detgroups.is_mca[0]        = 0
self.detgroups.triggerpv[0]     = 'CNT'
self.detgroups.counterpv[0]     = 'TP'
self.detgroups.name[1]          = 'Ge16 med'
self.detgroups.use_det[1]       = 0
self.detgroups.prefix[1]        = '13GE1:med:'
self.detgroups.max_elems[1]     = 16
self.detgroups.is_mca[1]        = 1
self.detgroups.triggerpv[1]     = 'EraseStart'
self.detgroups.counterpv[1]     = 'PresetReal'


self.scan[0].scanpv    = self.prefix + 'scan1'
self.scan[1].scanpv    = self.prefix + 'scan2'
self.scan[2].scanpv    = self.prefix + 'scan3'
for i = 0, 2 do begin
    self.scan[i].type      = 'motor'
    self.scan[i].is_rel    = 1
    self.scan[i].start[0]  = 0.
    self.scan[i].stop[0]   = 1.
    self.scan[i].n_regions = 1
    self.scan[i].time[0]   = 1
    self.scan[i].pasm      = 2
    self.scan[i].pdly      = 0.50
    self.scan[i].ddly      = 0.25
    self.scan[i].params[0] = 8980.
endfor


if (keyword_set(scan_file) ne 0) then begin
    print, '  Reading scan parameters from ', scan_file
    u = self->read_paramfile(file=scan_file,use_dialog=0)
    if (u lt 0) then  begin
        self.paramfile = ' '
        u = self->read_paramfile(use_dialog=1)
    endif
endif
print, format='(1x,a,$)', ' Getting current motor settings ... '
u = self->lookup_motors()
print, format='(1x,a,$)', ' detector settings ... '
u = self->lookup_detectors()
print, ' '
for i = 0,  n_elements(self.motors.name)-1 do begin
    if (strupcase(strtrim(self.motors.name[i],2)) eq 'ENERGY') then   self.motors.e_drive = i
endfor

x  = self->get_current_dimension()
m  = n_elements(self.detgroups.name)

for i = 0, m-1 do begin
    s = strlowcase(self.detgroups.name[i])
    if (strpos(s,'med') ge 0) then begin
        s = self.detgroups.prefix[i]
        print, '  connecting to MED detector ... ' , s
        self.med_obj   = obj_new('EPICS_MED', s) 
    endif
endfor


return, 1
end

pro epics_scan__define
;+
; NAME:
;       EPICS_SCAN__DEFINE
;
; PURPOSE:
;       Defines an EPICS scan object.
;
; CATEGORY:
;       EPICS class library.
;
; CALLING SEQUENCE:
;       my_scan = obj_new('EPICS_SCAN')
;
;
; INPUTS:
;       None.
;
; OPTIONAL INPUTS:
;       None.
;
; KEYWORD PARAMETERS:
;       None.
;
;
; OUTPUTS:
;       Return value will contain the object reference.
;
;
; OPTIONAL OUTPUTS:
;       None.
;
;
; COMMON BLOCKS:
;       None.
;
;
; SIDE EFFECTS:
;       EPICS_Scan object is created.
;
;
; RESTRICTIONS:
;       This routine is not called directly, but by IDL's own obj_new()
;
; PROCEDURE:
;
;
; EXAMPLE:
;       scan = obj_new('EPICS_SCAN')
;       x = scan->set_param('prefix', '13LAB:')
;
;
; MODIFICATION HISTORY:
;       May 30 2000: M Newville
;-
@scan_dims

MAX_MOT = 36  ; number of motors
MAX_SCA =  8  ; number of scalar channels
MAX_REG =  4  ; number of regions in segmented scan
MAX_PAR = 11  ; number of 'extra parameters' in scan: 
              ;     currently params[0] = E0 for EXAFS scan
              ;     params 1..10 are used for scanning 
              ;     specified points

MAX_DTY =  3  ; number of types of detectors

; detectors are the values read during a scan
detectors = { detectors, ndetectors: 0, $
              group:    intarr(MAX_DET), $
              use_net:  intarr(MAX_DET), $
              in_use:   intarr(MAX_DET), $
              countPV:  strarr(MAX_DET), $
              desc:     strarr(MAX_DET) }

; detgroups are the detector objects (Scaler, MED, etc)
detgroups  = { detgroups, $
               name:      strarr(MAX_DTY), $
               prefix:    strarr(MAX_DTY), $
               triggerpv: strarr(MAX_DTY), $
               counterpv: strarr(MAX_DTY), $
               max_elems: intarr(MAX_DTY), $
               is_mca:    intarr(MAX_DTY), $
               use_det:   intarr(MAX_DTY) }

motors    = { motors, name: strarr(MAX_MOT), e_drive:0L,$
              pv:     strarr(MAX_MOT),  rbv:   strarr(MAX_MOT), $
              curpos: fltarr(MAX_MOT),  units: strarr(MAX_MOT), $
              llim:   fltarr(MAX_MOT),  hlim:  fltarr(MAX_MOT) }


scan1     = { scan, scanpv: 'scan1',    type : 'Motor', $
              drives:    intarr(MAX_POS), $
              pos_names: strarr(MAX_POS), $
              posPVs:    strarr(MAX_POS), $
              start:     fltarr(MAX_REG, MAX_POS), $
              stop:      fltarr(MAX_REG, MAX_POS), $
              step:      fltarr(MAX_REG, MAX_POS), $
              npts:      intarr(MAX_REG), npts_total: 1, $
              time:      fltarr(MAX_REG), $
              params:    fltarr(MAX_PAR), $
              is_kspace: intarr(MAX_REG), $
              is_rel: 1, n_regions: 1, $
              pasm: 2, ddly: 0.25, pdly:0.5 , time_est:0.000}

scan2     = scan1
scan3     = scan1
scan2.scanpv = 'scan2'
scan3.scanpv = 'scan3'

epics_scan= { epics_scan, $
              prefix:       ' ', $
              paramfile:    ' ', $
              monitorfile:  ' ', $ ; file of PVs to write down at start of scan
              datafile:     ' ', $
              user_comments:' ', $
              save_med:0, $
              med_obj: obj_new(), $
              lun:         -3, $
              dimension:    1, $
              total_time:   1.00000000, $
              current_scan: 1, $
              beam_ok_pv:   ' ',$
              shutter_pv:   ' ',$
              shutter_clos:   ' ',$
              shutter_open:   ' ',$
              cur_status : '', $
              max_scan_points: MAX_SCAN_POINTS, $
              detgroups:    detgroups, $
              detectors:    detectors, $
              motors:       motors, $
              scan:         [scan1, scan2, scan3] }
end


