pro set_exafs_regions, e0=e0, e1=e1, de1=de1, e2=e2, de2=de2, $
                       e3=e3, de3=de3, emax=emax, verbose=verbose,quiet=quiet,$
                       relative=relative,absolute=absolute, nregions=nregions, $
                       kmax=kmax, dk=dk, kspace=kspace, espace=espace, $
                       energy = energy, npts=npts, mpts=mpts, time=time,$
                       load=load, help=help, prefix=prefix, scanPV=scanPV
;
; define EXAFS scan with regions  three regions
;
;     type 'set_exafs_regions, /help'  for syntax
;
if (keyword_set(help) ne 0) then begin
    print, 'Help on SET_EXAFS_REGION:  An EXAFS Scan consists of 3 regions'
    print, '   Regions 1 and 2 are in constant energy steps'
    print, '   Region 3 can be in either constant energy or wavenumber steps'
    print, ' '
    print, ' The following parameters specify a scan (default values in []):'
    print, '   e0        : Edge Energy                               [5465]'
    print, '   e1        : Starting Energy  for Region 1 (Pre-Edge)  [-100]'
    print, '   de1       : Energy Increment for Region 1 (Pre-Edge)  [  10]'
    print, '   e2        : Starting Energy  for Region 2 (Edge)      [ -20]'
    print, '   de2       : Energy Increment for Region 2 (Edge)      [ 0.5]'
    print, '   e3        : Starting Energy  for Region 3 (Post-Edge) [  30]'
    print, '   de3       : Energy Increment for Region 3 (Post-Edge) [ 2.0]'
    print, '   emax      : Highest Energy   for Scan                 [ 200]'

    print, '   dk        : K-space Increment for Region 3 (Post-Edge)[0.05]'
    print, '   kmax      : Highest Wavenumber for Scan                 [13]'
    print, '   /kspace   : set Region 3 as constant wavenumber          [1]'
    print, '   /espace   : set Region 3 as constant energy              [0]'

    print, '   /relative : use energies relative to e0 for e1, e2, e3   [1]'
    print, '   /absolute : use absolute energies for e1, e2, e3         [0]'
    print, '   nregions  : number of regions to use                     [3]'

    print, 'These arguments control the interaction with the Scan Record'
    print, '   time      : integration time     [current scaler count time]'
    print, '   scanPV    : sets the scan PV                         [scan1]'
    print, '   prefix    : sets the scan prefix                    [13IDC:]'
    print, '   /load     : load energy array into scan record           [0]'

    print, 'These arguments return useful output values:'
    print, '   energy    : array of energy points calculated'
    print, '   npts      : useful length of energy array'
    print, '   mpts      : total length of energy array'
    print, '   /verbose  : print parameters and debugging info'
    return
endif
;
; default values

prefix_ = '13IDC:'
SPV     = '13IDC:scan1'


if (n_elements(scanPV) ne 0) then  SPV     = scanPV
if (n_elements(prefix) ne 0) then  Prefix_ = prefix


pos1   = prefix_  + 'E:Energy'
rbv1   = prefix_  + 'E:Energy'
medPV  = prefix_  + 'med:'
scalerPV = prefix_ + 'scaler1'
ETOK   =     0.2624682917
E_0    =  6540.0
E_1    =  -160.0
E_2    =   -20.0
E_3    =    30.0
E_MAX  =   500.0
DE_1   =    10.0
DE_2   =     0.50
DE_3   =     2.00
K_MAX  =    15.00
DK_1   =     0.05
is_kspace   = 1
is_verbose  = 1
is_relative = 1
n_regs      = 3
count_time  = -1
load_pvs    = 0
; read arguments into local variables
if (keyword_set(kspace))     then is_kspace  = 1
if (keyword_set(espace))     then is_kspace  = 0
if (keyword_set(relative))   then is_relative= 1
if (keyword_set(absolute))   then is_relative= 0
if (keyword_set(verbose))    then is_verbose = 1
if (keyword_set(quiet))      then is_verbose = 0
if (keyword_set(load))       then load_pvs   = 1

;;;;
if (n_elements(time) ne 0)   then  count_time= time
if (n_elements(nregions) ne 0)  then  n_regs = nregions > 1
if (n_elements(e0)   ne 0)   then  E_0   = e0
if (n_elements(e1)   ne 0)   then  E_1   = e1
if (n_elements(e2)   ne 0)   then  E_2   = e2
if (n_elements(e3)   ne 0)   then  E_3   = e3
if (n_elements(emax) ne 0)   then  E_MAX = emax
if (n_elements(de1)  ne 0)   then  DE_1  = de1
if (n_elements(de2)  ne 0)   then  DE_2  = de2
if (n_elements(de3)  ne 0)   then  DE_3  = de3
if (n_elements(kmax) ne 0)   then  K_MAX = kmax
if (n_elements(dk)   ne 0)   then  DK_1  = dk
if (n_elements(relative) ne 0)   then  is_relative = relative
if (n_elements(kspace)   ne 0)   then  is_kspace    = kspace
if (n_elements(de1)  ne 0)   then  DE_1  = de1

; print, ' relative , kspace = ', is_relative,  is_kspace
; print, ' E_0  E_1 E_2 E_3 = ', E_0, E_1, E_2, E_3


if (is_relative) then begin
    E_1 = E_1 + E_0
    E_2 = E_2 + E_0
    E_3 = E_3 + E_0
    E_MAX = E_MAX + E_0
endif

if (n_regs le 2) then begin
    E_MAX = E_3 + 0.001
    is_kspace = 0
endif
if (n_regs eq 1) then begin
    e_3   = e_2 + 0.005
    e_max = e_3 + 0.005
endif


if (is_kspace) then E_MAX  = E_0 + (K_MAX * K_MAX) / ETOK
if (count_time le 0) then s = caget(scalerPV + '.TP', count_time)

;-------------------------
; error checking and warnings
error= 0
if ( (abs(E_2-E_1) gt 1000) or $
     (abs(E_2-E_0) gt 1000) or $
     (abs(E_3-E_2) gt 1000) or $
     (abs(E_MAX-E_3) gt 2000)) then  begin
    print,  ' WARNING:  Mixed Absolute and Relative Energies??'
    print,  '   e0  = ' , e_0
    print,  '   e1, e2, e3, emax = ' , e_1, e_2, e_3, e_max
endif

if ( is_kspace and (E_3 le E_0)) then begin
    print,  ' ERROR: E3 must be greater than E0 in k-space mode'
    print,  '   e0, e3 = ' , e_0, e_3
    error = 1
endif
if ( (E_1 ge E_2) or (E_2 ge E_3) or (E_3 ge E_MAX))  then begin
    print,  ' ERROR: These energies must be in ascending order:'
    print,  '   e1, e2, e3, emax = ' , e_1, e_2, e_3, e_max
    error = 2
endif

if (error gt 0) then return
;-------------------------

; get max number of points from scan record, create energy array
mpts     = 1000
mpts_str = SPV + '.MPTS'
ret      = caget(mpts_str, mpts)

energy   = fltarr(mpts)
npts     = 0
npts_1   = 0
npts_2   = 0
npts_3   = 0
energy[0]= E_1


while (energy[npts] lt E_2) do begin
    npts = npts + 1
    energy[npts] = energy[npts - 1] + DE_1
endwhile
npts_1 = npts + 1

if (n_regs ge 2) then begin
    while (energy[npts] lt E_3) do begin
        npts = npts + 1
        energy[npts] = energy[npts - 1] + DE_2
    endwhile
    npts_2 = npts - npts_1 + 1
endif

if (n_regs ge 3) then begin
    if (is_kspace) then begin
        K_INIT = sqrt( (energy[npts]  -E_0) * ETOK)
        nkpts  = npts
        while (energy[npts] le E_MAX) do begin
            npts  = npts + 1
            K_VAL = K_INIT + (npts - nkpts) * DK_1
            energy[npts] =  E_0 + (K_VAL * K_VAL) / ETOK
        endwhile
    endif else begin
        while (energy[npts] le E_MAX) do begin
            npts = npts + 1
            energy[npts] = energy[npts - 1] + DE_3
        endwhile
    endelse
    npts_3 = npts - npts_2 - npts_1 + 1
endif
npts = npts + 1

;
if (is_verbose) then begin
    reg_str = 'regions'
    if (n_regs eq 1) then reg_str = 'region'
    print,  format='(1x,a,i5,a,i5,1x,2a,f9.2)', 'SET_EXAFS_REGIONS:', npts, $
      ' points, ',  n_regs, reg_str, ',  e0 =', E_0
    if (is_kspace) then begin
        print, format='(3x,a,4f9.2,a,f7.2,a)', 'e1, e2, e3, emax, kmax= ',$
          E_1,E_2,E_3,E_MAX, ' (', K_MAX, ' Ang^-1)'
        print, format='(3x,a,4x,3f9.2,a)',     'de1, de2, dk          = ',$
          DE_1,DE_2,DK_1, '  Ang^-1'
    endif else begin
        print, format='(3x,a,4f9.2)',          'e1, e2, e3, emax      = ',$
          E_1,E_2,E_3,E_MAX
        print, format='(3x,a,4x,3f9.2)',       'de1, de2, de3         = ',$
          DE_1,DE_2,DE_3
    endelse
    print, format='(3x,a,3x,3i9)',             'npts per region       = ',$
      npts_1, npts_2, npts_3
endif

;---
; check that energy array is  strictly increasing
order_ok = 1
for i = 1, npts-1 do begin
    if (energy[i] le energy[i-1]) then order_ok = 0
endfor
if (not order_ok) then begin
    print, ' --- WARNING --- energy array is out of order'
    if (load_pvs) then begin
        print, ' --- NOT LOADING ARRAY ---'
        load_pvs = 0
    endif
endif

if (load_pvs) then begin
    x = -1
    if (is_verbose) then print, format='(1x,a,$)',  $
      'writing to EPICS Scan Record ... '
    x = caput( SPV + '.PASM', 2) ;  'Prior Pos' after scan
    x = caput( SPV + '.P1AR', 0) ;  'Absolute'  mode
    x = caput( SPV + '.P1SM', 1) ;  'Table' mode, duh
    x = caput( SPV + '.P1PV', pos1)
    x = caput( SPV + '.R1PV', rbv1)
    x = caput( SPV + '.NPTS', npts) 
    x = caput( SPV + '.P1PA', energy)

; positioner and detector settling time for SSCAN record: set minima
    x = caget( SPV + '.PDLY', p_delay)
    if (p_delay le 0.10) then begin
        p_delay = 0.10
        x = caput( SPV + '.PDLY', p_delay)
    endif
    x = caget( SPV + '.DDLY', d_delay)
    if (d_delay le 0.05) then begin
        d_delay = 0.05
        x = caput( SPV + '.DDLY', d_delay)
    endif


; put scaler in one-shot mode
    x = caput( scalerPV + '.CONT', 0)
; set scaler count time
    x = caput( scalerPV + '.TP', count_time)

;
; set med count time
    x = caput( medPV + 'PresetReal', count_time)
    x = caput( medPV + 'StatusSeq.SCAN', 8) ; set med status rate to 0.2sec
    x = caput( medPV + 'ReadSeq.SCAN', 0) ; set med in 'passive read rate'
    if (x ne 0) and (is_verbose) then print, ' ... Med Count Time Failed!'
;
    print, ' ready to scan!'
endif

return
end

function exafs_scan_help
   print, ' in exafs_scan_help'
   return, 0
end

function set_sensitive_exafs_regions, p
   x = (*p).scan1.nregs 
   if (x eq 1) then begin
       Widget_Control, (*p).wid.r3space, SENSITIVE = 0
       Widget_Control, (*p).wid.r3start, SENSITIVE = 0
       Widget_Control, (*p).wid.r3stop,  SENSITIVE = 0
       Widget_Control, (*p).wid.r3step,  SENSITIVE = 0
       Widget_Control, (*p).wid.r2start, SENSITIVE = 0
       Widget_Control, (*p).wid.r2stop,  SENSITIVE = 0
       Widget_Control, (*p).wid.r2step,  SENSITIVE = 0
   endif else if (x eq 2) then begin
       Widget_Control, (*p).wid.r3space, SENSITIVE = 0
       Widget_Control, (*p).wid.r3start, SENSITIVE = 0
       Widget_Control, (*p).wid.r3stop,  SENSITIVE = 0
       Widget_Control, (*p).wid.r3step,  SENSITIVE = 0
       Widget_Control, (*p).wid.r2start, SENSITIVE = 1
       Widget_Control, (*p).wid.r2stop,  SENSITIVE = 1
       Widget_Control, (*p).wid.r2step,  SENSITIVE = 1
   endif else begin
       Widget_Control, (*p).wid.r3space, SENSITIVE = 1
       Widget_Control, (*p).wid.r3start, SENSITIVE = 1
       Widget_Control, (*p).wid.r3stop,  SENSITIVE = 1
       Widget_Control, (*p).wid.r3step,  SENSITIVE = 1
       Widget_Control, (*p).wid.r2start, SENSITIVE = 1
       Widget_Control, (*p).wid.r2stop,  SENSITIVE = 1
       Widget_Control, (*p).wid.r2step,  SENSITIVE = 1
   endelse
return,0
end

PRO exafs_scan_event, event

Widget_Control, event.top, GET_UVALUE = p
Widget_Control, event.id,  GET_UVALUE = uval

ErrorNo = 0
Catch, ErrorNo
if (ErrorNo ne 0) then begin;
    Catch, /CANCEL
    ErrArray = ['Application Error!', $
                'Error Number: '+strtrim(!error,2), !Err_String]
    a = DIALOG_MESSAGE(ErrArray, /ERROR)
    return
endif

ETOK  = 0.2624682917
; print , ' see event: ', uval
case uval of
    'exit':   Widget_Control, event.top, /DESTROY
    'load_cfg': begin
        f   =  (*p).main.file
        retval = read_scan_param_file(p)
        Widget_Control, (*p).wid.e0,        SET_VALUE  = string((*p).scan1.e0)
        Widget_Control, (*p).wid.nregs,     SET_VALUE  = string((*p).scan1.nregs)
        Widget_Control, (*p).wid.time,      SET_VALUE  = string((*p).scan1.time)
        Widget_Control, (*p).wid.r1start,   SET_VALUE  = string((*p).scan1.r1start)
        Widget_Control, (*p).wid.r1stop,    SET_VALUE  = string((*p).scan1.r1stop)
        Widget_Control, (*p).wid.r1step,    SET_VALUE  = string((*p).scan1.r1step)
        Widget_Control, (*p).wid.r2start,   SET_VALUE  = string((*p).scan1.r2start)
        Widget_Control, (*p).wid.r2stop,    SET_VALUE  = string((*p).scan1.r2stop)
        Widget_Control, (*p).wid.r2step,    SET_VALUE  = string((*p).scan1.r2step)
        Widget_Control, (*p).wid.r3start,   SET_VALUE  = string((*p).scan1.r3start)
        Widget_Control, (*p).wid.r3stop,    SET_VALUE  = string((*p).scan1.r3stop)
        Widget_Control, (*p).wid.r3step,    SET_VALUE  = string((*p).scan1.r3step)
        Widget_Control, (*p).wid.r3space,   SET_DROPLIST_SELECT = string((*p).scan1.is_kspace)
        Widget_Control, (*p).wid.is_rel,    SET_DROPLIST_SELECT = string((*p).scan1.is_rel)
        retval = set_sensitive_exafs_regions(p)
    end
    'start_scan': begin
        print, ' starting scan'
        sfile =  (*p).main.scanname
        pdet  =  (*p).main.plotdet
        x = sscan(file = sfile, view = pdet , scan= '13IDC:scan1')
    end
    'pause_scan': begin
        print, ' sending pause scan'
        x = caput('13IDC:scanPause.VAL', 1)
    end
    'scanname': begin
        Widget_Control, (*p).wid.scanname, GET_VALUE = t
        t =  strtrim(t[0],2)
        (*p).main.scanname = t
    end
    'plotdet': begin
        Widget_Control, (*p).wid.plotdet, GET_VALUE = t
        (*p).main.plotdet = t
    end
    'save_cfg': begin
        f   =  (*p).main.file
        retval = save_scan_param_file(p,1)
    end
    'saveas_cfg': begin
        f   =  (*p).main.file
        retval = save_scan_param_file(p,1)
    end
    'EXAFS_help': begin
        retval = exafs_scan_help()
    end
    'IDLhelp': begin
        online_help
    end
    'e0': begin
        Widget_Control, (*p).wid.e0, GET_VALUE = t
        t =  strtrim(t,2)
        (*p).scan1.e0 = t
    end
    'nregs': begin
        Widget_Control, (*p).wid.nregs, GET_VALUE = t
        x =  fix(strtrim(t[0],2))
        if ((x ne 1) and (x ne 2)) then x = 3
        (*p).scan1.nregs = x
        retval = set_sensitive_exafs_regions(p)
    end
    'time': begin
        Widget_Control, (*p).wid.time, GET_VALUE = t
        t =  strtrim(t,2)
        (*p).scan1.time = t
    end
    'r1start': begin
        Widget_Control, (*p).wid.r1start, GET_VALUE = t
        t =  strtrim(t,2)
        (*p).scan1.r1start = t
    end
    'r1stop': begin
        Widget_Control, (*p).wid.r1stop, GET_VALUE = t
        t =  strtrim(t,2)
        (*p).scan1.r1stop  = t
        (*p).scan1.r2start = t
        Widget_Control, (*p).wid.r2start, SET_VALUE = t
    end
    'r1step': begin
        Widget_Control, (*p).wid.r1step, GET_VALUE = t
        t =  strtrim(t,2)
        (*p).scan1.r1step = t
    end
    'r1npts': begin
        Widget_Control, (*p).wid.r1npts, GET_VALUE = t
        start = (*p).scan1.r1start
        stop  = (*p).scan1.r1stop
        npts  = strtrim(t,2)
        if (npts le 1) then npts = 2
        step  = abs(start-stop)/(npts  - 1)
        print, 'npts = ' ,  npts, ' step = ', step
        (*p).scan1.r1step = step
        Widget_Control, (*p).wid.r1step, SET_VALUE = strtrim(string(step),2)
    end
    'r2start': begin
        Widget_Control, (*p).wid.r2start, GET_VALUE = t
        t =  strtrim(t,2)
        (*p).scan1.r2start = t
        (*p).scan1.r1stop  = t
        Widget_Control, (*p).wid.r1stop, SET_VALUE = t
    end
    'r2stop': begin
        Widget_Control, (*p).wid.r2stop, GET_VALUE = t
        t =  strtrim(t,2)
        (*p).scan1.r2stop = t
        s = double(t)
        if ((*p).scan1.is_kspace) then begin
            if ((*p).scan1.is_rel eq 0) then s = s - (*p).scan1.e0 
            s = sqrt(abs(s) * ETOK)
        endif
        Widget_Control, (*p).wid.r3start, SET_VALUE = strtrim(string(s),2)
    end
    'r2step': begin
        Widget_Control, (*p).wid.r2step, GET_VALUE = t
        t =  strtrim(t,2)
        (*p).scan1.r2step = t
    end
    'r3start': begin
        Widget_Control, (*p).wid.r3start, GET_VALUE = t
        t =  strtrim(t,2)
        (*p).scan1.r3start = t
        s = double(t)
        if ((*p).scan1.is_kspace eq 1) then begin
            s = s*s / ETOK
            if ((*p).scan1.is_rel eq 0) then s = s + (*p).scan1.e0 
        endif
        Widget_Control, (*p).wid.r2stop, SET_VALUE = strtrim(string(s),2)
    end
    'r3stop': begin
        Widget_Control, (*p).wid.r3stop, GET_VALUE = t
        t =  strtrim(t,2)
        (*p).scan1.r3stop = t
    end
    'r3step': begin
        Widget_Control, (*p).wid.r3step, GET_VALUE = t
        t =  strtrim(t,2)
        (*p).scan1.r3step = t
    end
    'EXAFS_space': begin
        space = event.index
        is_rela = (*p).scan1.is_rel
        if (space eq 1) then begin ;  choose 'Ang^-1'
            if ((*p).scan1.is_kspace eq 0) then begin
; switching from E to k space
                (*p).scan1.is_kspace = 1
                Widget_Control, (*p).wid.r3start, GET_VALUE = t
                t =  strtrim(t,2)
                d = double(t)
                if (is_rela eq 0) then d = d - (*p).scan1.e0
                d = sqrt(d * ETOK)
                (*p).scan1.r3start = d
                Widget_Control, (*p).wid.r3start, SET_VALUE = strtrim(string(d),2)
                d = d*d/ETOK
                (*p).scan1.r2stop  = d
                if (is_rela eq 0) then d = d + (*p).scan1.e0
                Widget_Control, (*p).wid.r2stop, SET_VALUE = strtrim(string(d),2)
                Widget_Control, (*p).wid.r3stop, GET_VALUE = t
                t =  strtrim(t,2)
                d = double(t)
                if (is_rela eq 0) then d = d - (*p).scan1.e0 
                d = sqrt(d * ETOK)
                (*p).scan1.r3stop = d
                Widget_Control, (*p).wid.r3stop, SET_VALUE = strtrim(string(d),2)
                d = 0.05
                (*p).scan1.r3step = d
                Widget_Control, (*p).wid.r3step, SET_VALUE = strtrim(string(d),2)
            endif
        endif else begin;  choose 'eV'
            if ((*p).scan1.is_kspace eq 1) then begin
; switching from k to E space
                (*p).scan1.is_kspace = 0
                Widget_Control, (*p).wid.r3start, GET_VALUE = t
                t =  strtrim(t,2)
                d = double(t) * double(t) / ETOK
                if (is_rela eq 0) then d = d + (*p).scan1.e0 
                (*p).scan1.r3start = d
                Widget_Control, (*p).wid.r3start, SET_VALUE = strtrim(string(d),2)
                (*p).scan1.r2stop  = d
                Widget_Control, (*p).wid.r2stop,  SET_VALUE = strtrim(string(d),2)
                Widget_Control, (*p).wid.r3stop, GET_VALUE = t
                t =  strtrim(t,2)
                d = double(t) * double(t) / ETOK
                if (is_rela eq 0) then d = d + (*p).scan1.e0 
                (*p).scan1.r3stop = d
                Widget_Control, (*p).wid.r3stop, SET_VALUE = strtrim(string(d),2)
                d = 2.0
                (*p).scan1.r3step = d
                Widget_Control, (*p).wid.r3step, SET_VALUE = strtrim(string(d),2)
            endif
        endelse
    end
    'use_rel': begin
        do_change = 0
        if ((event.index eq 1) and ((*p).scan1.is_rel eq 0)) then begin ;
            do_change = 1
            (*p).scan1.is_rel = 1
            de0  = -( (*p).scan1.e0)
        endif else if ((event.index eq 0) and ((*p).scan1.is_rel eq 1)) then begin
            do_change = 1
            (*p).scan1.is_rel = 0
            de0  = (*p).scan1.e0
        endif 
        if (do_change eq 1) then begin
            Widget_Control, (*p).wid.r1start, GET_VALUE = d1
            Widget_Control, (*p).wid.r1stop,  GET_VALUE = d2
            Widget_Control, (*p).wid.r2stop,  GET_VALUE = d3
            d1  = d1 + de0
            d2  = d2 + de0
            d3  = d3 + de0
            (*p).scan1.r1start = d1
            (*p).scan1.r1stop  = d2
            (*p).scan1.r2start = d2
            (*p).scan1.r2stop  = d3
            Widget_Control, (*p).wid.r1start, SET_VALUE = strtrim(string(d1),2)
            Widget_Control, (*p).wid.r1stop,  SET_VALUE = strtrim(string(d2),2)
            Widget_Control, (*p).wid.r2start, SET_VALUE = strtrim(string(d2),2)
            Widget_Control, (*p).wid.r2stop,  SET_VALUE = strtrim(string(d3),2)
            if ((*p).scan1.is_kspace eq 0) then begin
                d1 = (*p).scan1.r3start + de0
                d2 = (*p).scan1.r3stop  + de0
                (*p).scan1.r3start = d1
                (*p).scan1.r3stop  = d2
                Widget_Control, (*p).wid.r3start, $
                  SET_VALUE = strtrim(string(d1),2)
                Widget_Control, (*p).wid.r2stop, $
                  SET_VALUE = strtrim(string(d1),2)
                Widget_Control, (*p).wid.r3stop, $
                  SET_VALUE = strtrim(string(d2),2)
            endif
        endif
    end
    'load': begin
        print, ' loading scan parameters'
; make sure we have the latest parameters
        Widget_Control, (*p).wid.e0,      GET_VALUE = t
        (*p).scan1.e0      = t
        Widget_Control, (*p).wid.nregs,   GET_VALUE = t
        (*p).scan1.nregs      = t
        Widget_Control, (*p).wid.r1start, GET_VALUE = t
        (*p).scan1.r1start = t
        Widget_Control, (*p).wid.time,    GET_VALUE = t
        (*p).scan1.time = t
        Widget_Control, (*p).wid.r1start, GET_VALUE = t
        (*p).scan1.r1start = t
        Widget_Control, (*p).wid.r2start, GET_VALUE = t
        (*p).scan1.r2start = t
        Widget_Control, (*p).wid.r3start, GET_VALUE = t
        (*p).scan1.r3start = t
        Widget_Control, (*p).wid.r1stop,  GET_VALUE = t
        (*p).scan1.r1stop = t
        Widget_Control, (*p).wid.r2stop,  GET_VALUE = t
        (*p).scan1.r2stop = t
        Widget_Control, (*p).wid.r3stop,  GET_VALUE = t
        (*p).scan1.r3stop = t
        Widget_Control, (*p).wid.r1step,  GET_VALUE = t
        (*p).scan1.r1step = t
        Widget_Control, (*p).wid.r2step,  GET_VALUE = t
        (*p).scan1.r2step = t
        Widget_Control, (*p).wid.r3step,  GET_VALUE = t
        (*p).scan1.r3step = t
;
        if ((*p).scan1.is_kspace eq 1) then begin
            e3 = (*p).scan1.r3start
            e3 = e3*e3/ETOK
            if ((*p).scan1.is_rel eq 0) then e3 = e3 + (*p).scan1.e0
            set_exafs_regions,  $
              e0       = (*p).scan1.e0,       $
              e1       = (*p).scan1.r1start,  $
              de1      = (*p).scan1.r1step,   $
              e2       = (*p).scan1.r2start,  $
              de2      = (*p).scan1.r2step,   $
              e3       = e3, $
              dk       = (*p).scan1.r3step,   $
              kmax     = (*p).scan1.r3stop,   $
              relative = (*p).scan1.is_rel,   $
              nregions = (*p).scan1.nregs,    $
              time     = (*p).scan1.time,     $
              verbose  = 0,  kspace=1, /load
        endif else begin
            set_exafs_regions,  $
              e0       = (*p).scan1.e0,       $
              e1       = (*p).scan1.r1start,  $
              de1      = (*p).scan1.r1step,   $
              e2       = (*p).scan1.r2start,  $
              de2      = (*p).scan1.r2step,   $
              e3       = (*p).scan1.r3start,  $
              de3      = (*p).scan1.r3step,   $
              emax     = (*p).scan1.r3stop,   $
              relative = (*p).scan1.is_rel,   $
              nregions = (*p).scan1.nregs,    $
              time     = (*p).scan1.time,     $
              verbose  = 0,  kspace=0, /load
        endelse
    end
    else: begin
        print, 'unknown event:  uval = ', uval
    end
endcase

return
end

pro exafs_scan

;
; GUI interface to set_exafs_regions
;

ETOK  = 0.2624682917
;
R3_spaces   =  ['eV', 'Ang^(-1) ']
Rel_choices =  ['Absolute', 'Relative']

; default values
main = {prefix:'13IDC:', file:'unknown.scn', dimension:'1',$
        detectors: 15,  current_scan:1, plotdet:1L,$
        scanname:'scan.001', $
        trigger1:'med:EraseStart', trigger2:'scaler1.CNT'}

scan1 = {type:'EXAFS', ScanPV:'scan1', motor_name:'E:Energy',$
         pos1: 'E:Energy.VAL', rbv1: 'E:Energy', units:'eV', $
         llimit:0.0, ulimit:0.0, cur_pos:0.0, plotdet:1L, $
         e0:7112., is_rel:1, is_kspace:1, nregs:3, time:1.0, $
         r1start:-200., r1step: 10. , r1stop: -30., r1npts: 18, $
         r2start: -30., r2step: 0.5 , r2stop:  30., r2npts: 61, $
         r3start:  0., r3step: 0.05, r3stop:  15. , r3npts: 300 }

scan2 = {type:'Motor', ScanPV:'scan2', motor_name:'',$
         pos1: '', rbv1: '', units:'mm', $
         llimit:0.0, ulimit:0.0, cur_pos:0.0, $
         e0:0., is_rel:1, is_kspace:0, nregs:1, time:1.0, $
         r1start:-200., r1step: 10. , r1stop: 200., $
         r2start: -30., r2step: 0.5 , r2stop:  30., $
         r3start:  0., r3step: 0.05, r3stop:  15.  }

scan3 = {type:'Motor', ScanPV:'scan3', motor_name:'',$
         pos1: '', rbv1: '', units:'mm', $
         llimit:0.0, ulimit:0.0, cur_pos:0.0, $
         e0:0., is_rel:1, is_kspace:0, nregs:1, time:1.0, $
         r1start:-200., r1step: 10. , r1stop: 200., $
         r2start: -30., r2step: 0.5 , r2stop:  30., $
         r3start:  0., r3step: 0.05, r3stop:  15.  }


wid  = {e0:0L, nregs:0L, time:0L, is_rel:Rel_choices[1],$
        startscan:0L, pausescan:0L, scanname:' ', $
        plotdet:1L, $
        r1start:0L,  r1stop:0L, r1step:0L, r1npts:0L, $
        r2start:0L,  r2stop:0L, r2step:0L, r2npts:0L, $
        r3start:0L,  r3stop:0L, r3step:0L, r3space:R3_spaces[1], r3npts:0L}

info = {main:main, scan1:scan1, scan2:scan2, scan3:scan3, wid:wid}

s = scan1.r2stop
s = sqrt(double(s) * ETOK)
info.scan1.r3start = strtrim(string(s),2)
info.scan1.r1npts  = fix ( abs(info.scan1.r1start - info.scan1.r1stop) / info.scan1.r1step) + 1
info.scan1.r2npts  = fix ( abs(info.scan1.r2start - info.scan1.r2stop) / info.scan1.r2step) + 1
info.scan1.r3npts  = fix ( abs(info.scan1.r3start - info.scan1.r3stop) / info.scan1.r3step) + 1

MAIN      = Widget_Base(TITLE = 'EXAFS Scan', /COLUMN, APP_MBAR = menubar)
fileMenu  = Widget_Button(menubar,  VALUE = 'File', /HELP)
loadMB    = Widget_Button(fileMenu, VALUE = 'Read Scan File ...', UVALUE = 'load_cfg')
saveMB    = Widget_Button(fileMenu, VALUE = 'Save Scan File ...', UVALUE = 'save_cfg')
saveasMB  = Widget_Button(fileMenu, VALUE = 'Save As ...', UVALUE = 'saveas_cfg')

exitMB    = Widget_Button(fileMenu, VALUE = 'Exit', UVALUE = 'exit', $
                          /SEPARATOR)
; Help menu
helpMenu  = Widget_Button(menubar,  VALUE = 'Help', /MENU, /HELP)
exahelpMB = Widget_Button(helpMenu, VALUE = 'Help on EXAFS Scan',  UVALUE = 'EXAFS_help')
idlhelpMB = Widget_Button(helpMenu, VALUE = 'Help on IDL',  UVALUE = 'IDLhelp')

MAINFRAME = Widget_Base(MAIN, /COLUMN)
R0_Base   = Widget_Base(MAINFRAME, /ROW)


info.wid.e0    = CW_FIELD(R0_Base, /FLOATING,  /ROW,  XSIZE = 9,  $
                          TITLE = 'E0 ',  UVALUE = 'e0', $
                          VALUE = strtrim(string(info.scan1.e0),2), $
                          /ALL_EVENTS)


info.wid.nregs = CW_FIELD(R0_Base, /INTEGER,  /ROW,  XSIZE = 5, $
                          TITLE = 'Number of Regions', UVALUE = 'nregs', $
                          VALUE = strtrim(string(info.scan1.nregs),2), $
                          /ALL_EVENTS)


info.wid.time  = CW_FIELD(R0_Base, /FLOATING,  /ROW,  XSIZE = 7, $
                          TITLE = 'Count Time', UVALUE = 'time', $
                          VALUE = strtrim(string(info.scan1.time),2), $
                          /ALL_EVENTS)
X              = Widget_Label(R0_Base, SCR_XSIZE=40,  VALUE = 'sec')



R4_Base   = Widget_Base(MAINFRAME, /ROW)
info.wid.is_rel = Widget_DROPLIST(R4_Base, TITLE = 'use ', $
                               VALUE = Rel_choices, UVALUE = 'use_rel')
Widget_Control, info.wid.is_rel, SET_DROPLIST_SELECT = 1
X = Widget_Label(R4_Base, SCR_XSIZE=90,  VALUE = ' Energies ')

T = Widget_Base(MAINFRAME, /ROW, /FRAME)
X = Widget_Label(T, XSIZE=100,  VALUE = ' Region ', /ALIGN_LEFT)
X = Widget_Label(T, XSIZE=100,  VALUE = ' Start  ', /ALIGN_LEFT)
X = Widget_Label(T, XSIZE=100,  VALUE = ' Stop   ', /ALIGN_LEFT)
X = Widget_Label(T, XSIZE=100,  VALUE = ' Step   ', /ALIGN_LEFT)
X = Widget_Label(T, XSIZE=100,  VALUE = ' Units  ', /ALIGN_LEFT)
; X = Widget_Label(T, SCR_XSIZE=90,  VALUE = '   Npts   ')

R1_Base           = Widget_Base(MAINFRAME, /ROW)
X                 = Widget_Label(R1_Base, XSIZE= 90,  VALUE = ' Pre-edge', /ALIGN_LEFT)
info.wid.r1start  = CW_FIELD(R1_Base,  Title= ' ', XSIZE = 11,  UVALUE = 'r1start', $
                            VALUE = strtrim(string(info.scan1.r1start),2), $
                            /ALL_EVENTS, /FLOATING)
info.wid.r1stop   = CW_FIELD(R1_Base, Title= ' ',  XSIZE = 11,  UVALUE = 'r1stop', $
                            VALUE = strtrim(string(info.scan1.r1stop),2), $
                            /ALL_EVENTS, /FLOATING)
info.wid.r1step   = CW_FIELD(R1_Base,  Title = ' ', XSIZE = 11,  UVALUE = 'r1step', $
                            VALUE = strtrim(string(info.scan1.r1step),2), $
                            /ALL_EVENTS, /FLOATING)
X                 = Widget_Label(R1_Base, XSIZE=65,  VALUE = ' eV ', /ALIGN_LEFT)


R2_Base           = Widget_Base(MAINFRAME, /ROW)
X                 = Widget_Label(R2_Base,  XSIZE = 90, VALUE = ' Edge ', /ALIGN_LEFT)
info.wid.r2start  = CW_FIELD(R2_Base,  Title = ' ', XSIZE = 11,  UVALUE = 'r2start', $
                                VALUE = strtrim(string(info.scan1.r2start),2), $
                                /ALL_EVENTS, /FLOATING)
info.wid.r2stop   = CW_FIELD(R2_Base,  Title = ' ', XSIZE = 11,  UVALUE = 'r2stop', $
                                VALUE = strtrim(string(info.scan1.r2stop),2), $
                                /ALL_EVENTS, /FLOATING)
info.wid.r2step   = CW_FIELD(R2_Base,  Title= ' ', XSIZE = 11,  UVALUE = 'r2step', $
                                VALUE = strtrim(string(info.scan1.r2step),2), $
                                /ALL_EVENTS, /FLOATING)
X                 = Widget_Label(R2_Base, XSIZE=65,  VALUE = ' eV ', /ALIGN_LEFT)

R3_Base           = Widget_Base(MAINFRAME, /ROW)
X                 = Widget_Label(R3_Base,XSIZE= 90,  VALUE = ' EXAFS ', /ALIGN_LEFT)
info.wid.r3start  = CW_FIELD(R3_Base,  Title=' ', XSIZE = 11,  UVALUE = 'r3start', $
                                VALUE = strtrim(string(info.scan1.r3start),2), $
                                /ALL_EVENTS, /FLOATING)

info.wid.r3stop   = CW_FIELD(R3_Base,  Title=' ', XSIZE = 11,  UVALUE = 'r3stop', $
                             VALUE = strtrim(string(info.scan1.r3stop),2), $
                             /ALL_EVENTS, /FLOATING)

info.wid.r3step   = CW_FIELD(R3_Base, Title =' ',  XSIZE=11,  UVALUE = 'r3step', $
                             VALUE = strtrim(string(info.scan1.r3step),2), $
                             /ALL_EVENTS, /FLOATING)

R3a_Base          = Widget_Base(R3_Base, /ROW)

info.wid.r3space  = Widget_DROPLIST(R3a_Base, TITLE = ' ', $
                                    VALUE = R3_spaces, UVALUE = 'EXAFS_space')
Widget_Control, info.wid.r3space, SET_DROPLIST_SELECT = 1


R4_Base  = Widget_Base(MAINFRAME, /ROW)
X        = Widget_Label(R4_Base,XSIZE= 90,  VALUE = 'Scan File ', /ALIGN_LEFT)
info.wid.scanname  = WIDGET_TEXT(R4_Base,  UVALUE = 'scanname', /editable, $
                                VALUE = info.main.scanname)
;X        = Widget_Label(R4_Base,XSIZE= 100,  VALUE = 'Detector to Plot', /ALIGN_LEFT)
info.wid.plotdet = CW_FIELD(R4_Base, Title ='Detector to Plot',  XSIZE=8,  UVALUE = 'plotdet', $
                              VALUE = strtrim(string(info.main.plotdet),2), $
                              /ALL_EVENTS, /FLOATING)

R5_Base  = Widget_Base(MAINFRAME, /ROW)
X        = Widget_Button(R5_Base,  VALUE = 'Load Scan Parameters', UVALUE='load')
info.wid.startscan = Widget_Button(R5_Base,  VALUE = 'Begin Scan', UVALUE='start_scan')
; info.wid.pausescan = Widget_Button(R5_Base,  VALUE = 'Pause Scan', UVALUE='pause_scan')
X        = Widget_Button(R5_Base,  VALUE = 'EXIT ', UVALUE='exit')

; render widgets, load info structure into MAIN
Widget_Control, MAIN, /REALIZE
p_info = ptr_new(info,/NO_COPY)
Widget_Control, MAIN, SET_UVALUE=p_info
xmanager, 'exafs_scan', MAIN, /NO_BLOCK

return
end
