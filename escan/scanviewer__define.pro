pro scanviewer::scan_finished

widget_control, self.form.start_btn, set_value='Start Scan'
widget_control, self.form.progress,  set_value='Scan Finished'
; widget_control, self.form.time_rem,  set_value = sec2hms(0.0)
self.is_scanning = 0

print, ' entered scan finished ' , self.dimension
self->plot_data

if (self.dimension eq 1) then begin
    x = self.es->write_scan_data()
    x = self.es->close_scanfile()
    self.cpt2   = 0
    self.cpt1   = 0
    prog_str = ' Scan Done:  wrote '+ self.datafile
    widget_control, self.form.progress,  set_value= prog_str

    self.datafile  = increment_scanname ( self.datafile )
    x  = self.es->set_param('datafile', self.datafile )
    widget_control, self.form.datafile, set_value=self.datafile

    if (self.data.nscans gt self.data.iscan) then begin
        self.data.iscan =  self.data.iscan  + 1
        ; widget_control, self.form.progress,  set_value=' Waiting ...'
        widget_control, self.form.iscan ,    set_value=  f2a(self.data.iscan)

        prog_str = ' starting scan '+ f2a(self.data.iscan)+ ' of ' + $
          f2a(self.data.nscans)
        wait, self.data.wait2dscan
        widget_control, self.form.progress,  set_value= prog_str
        self->start_scan
    endif else begin
        self.is_scanning = 0
        widget_control, self.form.time_rem,  set_value = sec2hms(0.0)
    endelse
    
endif else if (self.dimension eq 2) then begin
    short_labels= 1
    if  (self.cpt2 gt 1 ) then short_labels=0
    x = self.es->write_scan_data(short_labels=short_labels)
    prog_str = ' 2D Scan: ' +  f2a(self.cpt2) + ' / ' + f2a(self.mpts2) + $
      ' Done: wrote ' + self.datafile
    widget_control, self.form.progress,  set_value= prog_str
    if  ( self.cpt2 lt self.mpts2 ) then begin
        self->next_2d_row
        self->start_scan,  /no_header
    endif else begin
        x = self.es->close_scanfile()
        prog_str = ' 2D Scan Done: wrote ' + self.datafile
        self.datafile  = increment_scanname ( self.datafile )
        x  = self.es->set_param('datafile', self.datafile )
        widget_control, self.form.datafile,  set_value=self.datafile
        widget_control, self.form.progress,  set_value= prog_str

        self.is_scanning = 0
        widget_control, self.form.time_rem,  set_value = sec2hms(0.0)
    endelse
endif

return
end

pro scanviewer::update_detector_lists, no_lookup=no_lookup

; print, ' update detector lists'

; update detector selection
if (keyword_set(no_lookup)) then begin
    ndet  = self.es->lookup_detectors()
    d     = self.es->get_detector_list(/desc)
    
    self.plot.mdets = self.es->get_param('ndetectors')
    ; print, ' mdets = ', self.plot.mdets, ndet, n_elements(d)
    
    self.plot.det_list = ptr_new(['1.0' ,  d])
endif    

xl = (*self.plot.det_list)
j  = Widget_Info(self.form.ynum[0], /droplist_select)
Widget_Control,  self.form.ynum[0], set_value=xl
Widget_Control,  self.form.ynum[0], set_droplist_SELECT = j

k  = Widget_Info(self.form.yden[0], /droplist_select)
Widget_Control,  self.form.yden[0], set_value=xl
Widget_Control,  self.form.yden[0], set_droplist_SELECT = k

; j  = Widget_Info(self.form.ynum[1], /droplist_select)
; Widget_Control,  self.form.ynum[1], set_value=xl
; Widget_Control,  self.form.ynum[1], set_droplist_SELECT = j

; k  = Widget_Info(self.form.yden[1], /droplist_select)
; Widget_Control,  self.form.yden[1], set_value=xl
; Widget_Control,  self.form.yden[1], set_droplist_SELECT = k


return
end


pro scanviewer::update_point
; 

prog_str = " Point " + f2a(self.cpt1) + " / " + f2a( self.mpts1 )
if (self.dimension eq 2) then begin
    prog_str = prog_str + '  Row '+ f2a(self.cpt2) + ' / ' + f2a(self.mpts2) 
endif
widget_control, self.form.progress, set_value = prog_str


; time estimate
c  = self.cpt_total
tm = dxtime()
x  = ( (tm - self.data.start_time) * (self.npts_total - c) / (c>1) ) > 0
; print, 'time est: ', c, self.npts_total, tm, self.data.start_time, x
widget_control, self.form.time_rem, set_value = sec2hms(x)

if (self.cpt1 ge 1) then $
  widget_control, self.form.xpos, set_value=f2a(self.data.p1pa[0,self.cpt1-1])
if ((self.cpt2 ge 1) and (self.dimension eq 2)) then $
  widget_control, self.form.ypos, set_value=f2a(self.data.p2pa[0,self.cpt2-1])


self->plot_data

if (self.data.save_med eq 1) then begin
    w = self.es->check_scan_wait()
    if (w) then  x = self.es->write_med_file(pt=cpt, pt2=self.cpt2)
endif

return
end


pro scanviewer::plot_data
;
; get data from crate and plot it 
npts = self.cpt1
if (npts le 0) then return

if (self.is_scanning) then begin
    ; print, 'mdets = ', self.plot.mdets, npts
    for i = 0, self.plot.mdets - 1 do begin
        d = string(i+1,format='(i2.2)') 
        s = caget(self.scanpv1+'.D'+d+'CV', x)
        self.data.da[i,npts-1] = x
    endfor
    for i = 0, 3 do begin
        d = string(i+1,format='(i1.1)')
        s = caget(self.scanpv1+'.P'+d+'CV', x)
        self.data.p1pa[i,npts-1]  = x
    endfor
endif else begin
    for i = 0, 3 do begin
        d =  string(i+1,format='(i1.1)')
        s = caget(self.scanpv1+'.P'+d+'PA', x)
        self.data.p1pa[i,*]  = x
    endfor
    for i = 0, self.plot.mdets - 1 do begin
        d = string(i+1,format='(i2.2)') 
        s = caget(self.scanpv1+'.D'+d+'DA', x)
        self.data.da[i,*] = x
    endfor
    npts = self.mpts1
    ; print,' plot_data: scan done :  ', npts
endelse

;
; trace 1
j_op  = Widget_Info(self.form.yop[0], /droplist_select)
j_num = Widget_Info(self.form.ynum[0], /droplist_select)
j_den = Widget_Info(self.form.yden[0], /droplist_select)
j_col = Widget_Info(self.form.ycol[0], /droplist_select)
j_sym = Widget_Info(self.form.ysym[0], /droplist_select)

xop  = (*self.plot.operas)[j_op]

num1 = fltarr(self.plot.mpts) + 1
den1 = fltarr(self.plot.mpts) + 1

if (j_num ne 0) then  num1 = self.data.da[j_num-1,0:npts-1]
if (j_den ne 0) then  den1 = self.data.da[j_den-1,0:npts-1]
    
y1 =  num1/(den1> 1.e-8)

case xop of
    'log':         y1 =  alog(y1 > 1.e-8)
    '-log':        y1 = -alog(y1 > 1.e-8)
    'derivative':  y1 =  deriv(y1)
    '-derivative': y1 = -deriv(y1)
    else:          x  = 1
endcase


case j_sym of
    0:  psym1 =  0
    1:  psym1 = -1
    2:  psym1 = -2
    3:  psym1 =  1
    4:  psym1 =  2
endcase
; print, ' plot_data ', npts

;
; trace 2
do_plot2 = 0
; j_op  = Widget_Info(self.form.yop[1], /droplist_select)
; j_num = Widget_Info(self.form.ynum[1], /droplist_select)
; j_den = Widget_Info(self.form.yden[1], /droplist_select)

; do_plot2 = 1
; if ((j_num eq 0) and (j_den eq 0)) then do_plot2 = 0

; if (do_plot2) then begin
;     jcol2 = Widget_Info(self.form.ycol[1], /droplist_select)
;     j_sym = Widget_Info(self.form.ysym[1], /droplist_select)
    
;     xop  = (*self.plot.operas)[j_op]
;     num  = fltarr(self.plot.mpts) + 1
;     den  = fltarr(self.plot.mpts) + 1

;     if (j_num ne 0) then  num = self.data.da[j_num-1,0:npts-1]
;     if (j_den ne 0) then  den = self.data.da[j_den-1,0:npts-1]
    
;     y2 =  num/(den> 1.e-8)


;     case xop of
;         'log':         y2 =  alog(y2 > 1.e-8)
;         '-log':        y2 = -alog(y2 > 1.e-8)
;         'derivative':  y2 =  deriv(y2)
;         '-derivative': y2 = -deriv(y2)
;         else:          x  = 1
;     endcase

;     xl1 = 0.99 * min(y1)
;     xh1 = 1.01 * max(y1)
;     xl2 = 0.99 * min(y2)
;     xh2 = 1.01 * max(y2)

;     ; print, 'range: scale:' , (xh1-xl1)/((xh2-xl2)>1.e-8) , 'offset = ', (xl2-xl1)

;     y2 = (y2 - xl2 + xl1)*( (xh1-xl1)/((xh2-xl2)>1.e-8))
    
;     case j_sym of
;         0:  psym2 =  0
;         1:  psym2 = -1
;         2:  psym2 = -2
;         3:  psym2 =  1
;         4:  psym2 =  2
;     endcase
; endif
; print, ' plot_data ', npts

if (npts gt 1) then begin
    l =  self.plot.xlab + ' [' + self.plot.xunits + ']'
    plot,  self.data.p1pa[0,0:npts-1], y1, ystyle=17,  $
      charsize=self.plot.charsize, title=self.datafile, $
      xtitle = l, /nodata
    oplot, self.data.p1pa[0,0:npts-1], y1, psym=psym1, $
      color=set_color( (*self.plot.colors)[j_col] )

    if (do_plot2) then begin
        oplot, self.data.p1pa[0,0:npts-1], y2, psym=psym2, $
          color=set_color( (*self.plot.colors)[jcol2] )
    endif
endif


return
end



pro  scanviewer::abort
print, ' scanviewer abort'
; abort scan
if (self.is_scan_master) then begin
    widget_control, self.form.progress,  set_value='Aborting Scan'
    self.ask_abort   = 1
    self.is_scanning = 0
    self.is_paused   = 0
    self.auto_paused = 0
    self.cpt1        = 0
    self.cpt2        = 0
    self.es->abort
    widget_control, self.form.start_btn, set_value='Start Scan'
    widget_control, self.form.progress,  set_value='Scan Aborted'
    widget_control, self.form.iscan ,    set_value= f2a(self.data.iscan)
    widget_control, self.form.time_rem,  set_value = sec2hms(0.0)
endif
return
end


pro  scanviewer::pause, force=force

; toggle pause state of scan (pause/upause), or allow it to be forced

forced = 0
val    = 0
if (n_elements(force) gt 0) then begin
    forced = 1
    val   = force
endif

if ((self.is_scan_master) and (self.is_scanning eq 1)) then begin
    p = 0
    if (self.is_paused eq 0) then p = 1
    if (forced) then p = val
    self.is_paused = p
    print, ' scanviewer pause ', p
    if (self.is_paused eq 1) then begin
        widget_control, self.form.pause_btn, set_value='Resume '
        widget_control, self.form.progress,  set_value='Scan Paused'
        self.es->pause_scan
    endif else begin
        widget_control, self.form.pause_btn, set_value='Pause Scan'
        widget_control, self.form.progress,  set_value='Resuming Scan'
        self.es->unpause_scan
    endelse
endif
return
end

pro scanviewer::next_2d_row
  widget_control, self.form.progress,  set_value='Moving to Next Row ...'
  for i = 0, 3 do begin
      if (self.data.p2pv[i] ne '') then $
          x   = caput(self.data.p2pv[i], self.data.p2pa[i,self.cpt2-1] )
  endfor
  x = wait_for_motor(motor = self.data.p2pv[0], maxtrys=200, wait_time=0.01)
  wait, self.data.wait2dscan
  for i = 0, 3 do begin
      if (self.data.p2pv[i] ne '') then begin
          x   = caget(self.data.p2pv[i], cpv)
          self.data.p2pa[i,self.cpt2-1] = cpv
          str = ';2D ' + self.data.p2pv[i] + ': ' +  f2a(cpv)
          x   = self.es->write_to_scanfile(str)
      endif
  endfor
  widget_control, self.form.progress,  set_value='Starting ...'
return
end

pro scanviewer::start_scan, no_header=no_header, get_start_time=get_start_time
;
; does 'scan1' for scan_viewer

write_header = 1
if (keyword_set(no_header)) then  write_header= 0

self.is_scan_master = 1
self.is_scanning    = 1
self.is_paused      = 0
self.auto_paused    = 0

self.dimension = self.es->get_param('dimension')
lun = self.es->open_scanfile(/append)
if ((self.dimension eq 1) or (self.cpt2 le 0)) then $
  str =  '; Epics Scan ' + f2a( self.dimension ) +  ' dimensional scan'
x   = self.es->write_to_scanfile(str)                
self.cpt1  = 0

; print ,' start_scan:  starting scan: ', self.dimension, self.npts_total

widget_control, self.form.progress,  set_value=' Waiting ...'
widget_control, self.form.iscan ,    set_value=  f2a(self.data.iscan)

mots = self.es->get_param('motors')

px  = fltarr(self.mpts1+2)
spv = self.es->get_scan_param(0,'scanpv')
for i = 0, 3 do begin
    x =  string(i+1,format='(i1.1)')
    s = caget(spv+'.P'+x+'PA', px)
    self.data.p1pa[i,*]  = px
endfor
x  = caget(spv +'.P1PV', pvn)
for i = 0,  n_elements(mots.name)-1 do begin
    if (strtrim(mots.pv[i],2) eq pvn) then begin
        self.plot.xlab   = mots.name[i]
        self.plot.xunits = mots.units[i]
    endif
endfor

               
if (self.dimension eq 2) then begin
    self.cpt2       = self.cpt2 + 1
    self->next_2d_row
endif

Widget_Control, self.form.usertext, get_value=titles

if (keyword_set(get_start_time) ne 0) then self.data.start_time = dxtime()

if (write_header) then begin
    x = self.es->start_scan1d(user_titles=titles)
endif else begin
    x = self.es->start_scan1d(/no_header)
endelse
   
x  = self.es->get_param('total_time')
widget_control, self.form.time_est,  set_value= sec2hms( x )
widget_control, self.form.pause_btn, set_value='Pause Scan'
widget_control, self.form.start_btn, set_value='Abort Scan'
widget_control, self.form.progress,  set_value='Scan Starting'
widget_control, self.form.timer,     time = 0.25
    
return
end
;
;

pro dummy_eh, event
; 
;  idl appears to need a procedure that is _not_ a 
;  class method for an event handler.  We trick it
;  by attaching 'self' to the top-base widget, and 
;  passing the event to a real member function.
    widget_control, event.top, get_uvalue = p
    p->event, event
return
end

pro scanviewer::event, event
;
; the real event handler
;
@scan_dims

ErrorNo = 0
; Catch, ErrorNo
; if (ErrorNo ne 0) then begin
;     Catch, /CANCEL
;     ErrA = ['Error!', 'Number' + strtrim(!error, 2), !Err_String]
;     a = Dialog_Message(ErrA, /ERROR)
;     return
; endif

if (tag_names(event, /structure_name) eq 'WIDGET_TIMER') then begin
    exec      = self.is_scanning
    mon_exec  = cacheckmonitor(self.monitors.exec)
    mon_pause = cacheckmonitor(self.monitors.pause)
    mon_cpt   = cacheckmonitor(self.monitors.cpt)
    if (exec) then begin
        ; print, ' monitors: exec, pause, cpt: ', mon_exec,  mon_pause, mon_cpt
        m  = caget(self.monitors.exec, xxe)
        m  = caget(self.monitors.pause,xxp)
        m  = caget(self.monitors.cpt,  xxc)
        ; print, ' exec, pause, cpt' , xxe, xxp, xxc
    endif

    if (mon_cpt) then begin
        s = caget(self.monitors.cpt,cpt)
        print, 'cpt event: ', self.cpt1, ' to ', cpt
        if (cpt gt self.cpt1) then begin
            self.cpt1      = cpt
            self.cpt_total = self.cpt_total + 1
            if (self.is_scanning)  then self->update_point
        endif
    endif

    if (self.is_scanning and self.is_scan_master and (self.cpt1  eq self.mpts1)) then begin
        print, 'scan appears done'
;        self.is_scanning = 0
    endif


    if (mon_exec) then begin
        s = caget(self.monitors.exec,exec)
        print, 'exec event ', self.is_scan_master, exec, self.is_scanning
        if (mon_exec and self.is_scan_master) then begin
            if (self.is_scanning and (exec eq 0)) then begin
                if (self.is_paused eq 1) then self->pause,force=0
                self->scan_finished
            endif 
;            else begin
;                print, ' scan has started '
;            endelse
            self.cpt1           = 0
        endif 
        self.is_scanning = exec
        if (exec) then  self.cpt1        = 0
    endif
;
    if (mon_pause and self.is_scan_master) then begin
        paused = self.is_paused
        s = caget(self.monitors.pause,paused)
        print, 'scan pause went from ', self.is_paused, ' to ', paused
        if (paused ne self.is_paused) then  self->pause
    endif
;
; check feedback lock and shutter
; if scanning (and if this is the scan master) then 
    if ((self.wait_for_lock eq 1) and (self.is_scanning eq 1)) then begin
        ok_x   = self.es->beam_ok()
        if (self.is_scan_master eq 1) then begin
            if ((self.auto_paused eq 0) and (ok_x eq 0)) then begin
                self.auto_paused   = 1
                self->pause, force = 1
            endif else if ((self.auto_paused eq 1) and (ok_x eq 1)) then begin
                self.auto_paused   = 0
                self->pause, force = 0
            endif
        endif
        if (ok_x eq 0) then begin
            widget_control, self.form.progress,  set_value='Scan Paused: No Beam'
        endif
    endif


    widget_control, event.id, timer=0.10

endif else begin
    widget_control, event.id,  get_uvalue=uval
    if (strpos(uval,'trace_') ge 0) then  begin
        ; print, ' trace event: ', event.top
        ; self->update_detector_lists, /no_lookup
        self->plot_data
    endif
    x  = self.es->get_param('total_time')
    widget_control, self.form.time_est,  set_value= sec2hms( x )
    case uval of
        'exit':         Widget_Control, event.top, /destroy
        'pause_scan':   self->pause
        ; 'wait_lock':    self.wait_for_lock =event.select
        'start_scan': begin
            self.dimension = self.es->get_param('dimension')
            ; print, ' start scan  ', self.is_scanning, self.dimension
            print, self.is_scanning
            if (self.is_scanning eq 0)  then begin
                self->update_detector_lists
                self.is_scan_master = 1
                self.data.iscan     = 1
                self.cpt_total      = 0
                self.cpt1           = 0
                self.mpts1          = self.es->npts(dim=1)
                self.npts_total     = self.mpts1
                if (self.data.nscans ge 1) then $
                  self.npts_total = self.npts_total * self.data.nscans
                if (self.dimension eq 2) then begin
                    self.cpt2       = 0
                    self.mpts2      = self.es->npts(dim=2)
                    self.npts_total = self.npts_total * self.mpts2 
                    s2pv            = self.es->get_scan_param(1,'scanpv')
                    px              = fltarr(self.mpts2+2)
                    pvn             = ''
                    for i = 0, 3 do begin
                        x  =  string(i+1,format='(i1.1)')
                        s  = caget(s2pv+'.P'+x+'PA', px)
                        for jj = 0, n_elements(px)-1 do self.data.p2pa[i,jj]  = px[jj]
                        s  = caget(s2pv+'.P'+x+'PV', pvn)
                        self.data.p2pv[i]   = pvn
                    endfor
                endif
                self->start_scan, /get_start_time
                mon_exec = cacheckmonitor(self.monitors.exec)
                s        = caget(self.monitors.exec,exec)
            endif else begin
                self->abort
            endelse
        end
        'datafile': begin
            Widget_Control, self.form.datafile, get_value=t
            self.datafile = strtrim(t,2)
            x  = self.es->set_param('datafile', self.datafile )
        end
        'nscans': begin
            Widget_Control, self.form.nscans, get_value=t
            old = self.data.nscans
            self.data.nscans = fix(strtrim(t,2))>1
            if (self.is_scanning) then $
                self.npts_total = self.npts_total * self.data.nscans  / (old>1)
        end
        else: x=1
    endcase
endelse

return
end


function scanviewer::init, escan=escan, scan_file=scan_file, prefix=prefix

;
; gui for viewing and running epics scans:
; uses Epics Scan object, which can be supplied or created
; arguments: (give one 
;    escan       Epics Scan object 
;    scan_file   name of valid scan file to use for Epics Scan creation
;    prefix      Epics prefix PV  ('13IDA:') for Epics Scan creation
;
print, ' This is ScanViewer version 1.99x'
;
@scan_dims

if (keyword_set(escan) eq 0)  then begin
    escan = obj_new('EPICS_SCAN', scan_file=scan_file, prefix=prefix)
endif

self.es      = escan
self.scanpv1 = self.es->get_scan_param(0,'scanpv')
self.scanpv2 = self.es->get_scan_param(1,'scanpv')
det_desc     = self.es->get_detector_list( /desc)
self.plot.mdets = self.es->get_param('ndetectors')
cur_dim      = self.es->get_param('dimension')
prefix       = self.es->get_param('prefix')

self.mpts1   = self.es->npts(dim=1)
self.mpts2   = self.es->npts(dim=2)
self.datafile= self.es->get_param('datafile')
self.wait_for_lock = 0
self.dimension      = cur_dim
self.data.nscans    = 1
self.data.iscan     = 1
self.data.wait2dscan= 1.0

self.is_scan_master = 1
self.is_scanning    = 0
self.is_paused      = 0
self.auto_paused    = 0

self.monitors.exec  = self.scanpv1 + '.EXSC'
self.monitors.cpt   = self.scanpv1 + '.CPT'
self.monitors.pause = prefix + 'scanPause.VAL'


print, 'monitors: ', self.monitors.exec,  self.monitors.pause,  self.monitors.cpt

tags = tag_names(self.monitors)
u = ''
for i = 0, n_tags(self.monitors)-1 do begin
    x = casetmonitor(self.monitors.(i))
    x = caget(self.monitors.(i), u)
    print, ' mon ', i, ' : ' , self.monitors.(i), u
endfor

!p.background = set_color('white')
!p.color      = set_color('black')

self.plot.charsize  = 1.5
self.plot.xlab      = ''
self.plot.xunits    = ''

plot_size         = 850.0
self.plot.xsize   = fix(plot_size)
self.plot.ysize   = fix(plot_size * (0.63))
self.plot.syms    = ptr_new(['Solid', '-+-', '-*-', ' + ', ' * '])
self.plot.colors  = ptr_new(['blue',   'black', 'red',      'darkgreen', $
                            'magenta', 'cyan', 'goldenrod', 'purple'])

self.plot.operas   = ptr_new(['   ','log','-log','derivative','-derivative'])
self.plot.det_list = ptr_new(['1.0', det_desc])
self.plot.mpts     = MAX_SCAN_POINTS

main = Widget_Base(title = 'Scan Viewer', /col, app_mbar = mbar)
menu = Widget_Button(mbar, value = 'File')
x    = Widget_Button(menu, value = 'Exit',             uval = 'exit', /separator)
; x    = Widget_Button(menu, value = 'Print ',           uval = 'print')
; x    = Widget_Button(menu, value = 'Set Preferences',  uval = 'set_pref')


; menu = Widget_Button(mbar, value = 'Options')
; x    = Widget_Button(menu, value = 'Colors ...',       uval = 'colors')
; x    = Widget_Button(menu, value = 'Line Styles ...',  uval = 'styles')


top  = widget_base(main,/row)
tx   = widget_base(top,/col)

uv_  = ['op','num','den', 'sym','col']
ttls = ['Trace 1:', 'Trace 2:']


i = 0
; for i = 0, 1 do begin
    uvs  = 'trace_' + uv_ + string(i,format='(i1.1)')
    tl   = widget_base(tx,/row)
    x    = Widget_Label(tl, value = ttls[i] )
    self.form.yop[i] = Widget_DROPLIST(tl, value = (*self.plot.operas),  title='', $
                                       uvalue = uvs[0], /dynamic_resize)
    X    = Widget_Label(tl, value = ' ( ')
    self.form.ynum[i]= Widget_DROPLIST(tl, value = (*self.plot.det_list),  title='', $
                                       uvalue = uvs[1], /dynamic_resize)
    X    = Widget_Label(tl, value = ' / ')

    self.form.yden[i]= Widget_DROPLIST(tl, value = (*self.plot.det_list),  title='', $
                                      uvalue = uvs[2], /dynamic_resize)
    X    = Widget_Label(tl, value = ' )   Symbol/Color:')
    
    self.form.ysym[i]= Widget_DROPLIST(tl, value = (*self.plot.syms),  title='', $
                                       uvalue = uvs[3], /dynamic_resize)

    self.form.ycol[i]= Widget_DROPLIST(tl, value = (*self.plot.colors),  title='', $
                                       uvalue = uvs[4], /dynamic_resize)

    Widget_Control, self.form.ynum[i], set_droplist_SELECT = 0
    Widget_Control, self.form.yop[i],  set_droplist_SELECT = 0
    Widget_Control, self.form.yden[i], set_droplist_SELECT = 0
    Widget_Control, self.form.ycol[i], set_droplist_SELECT = 0
    Widget_Control, self.form.ysym[i], set_droplist_SELECT = 0
; endfor
Widget_Control, self.form.ynum[0], set_droplist_SELECT = 1
;Widget_Control, self.form.ysym[1], set_droplist_SELECT = 1
;Widget_Control, self.form.ycol[1], set_droplist_SELECT = 1


self.form.timer = widget_base(main,/row)
self.form.draw  = widget_draw(self.form.timer, xsize=self.plot.xsize, ysize=self.plot.ysize)

m     = widget_base(main, /row)
self.form.start_btn  = widget_button(m, val='Start Scan',  ysize=35, uval = 'start_scan')
self.form.pause_btn  = widget_button(m, val='Pause Scan',  uval = 'pause_scan')


sc    = widget_base(m,/row)
x     = Widget_Label(sc,   value = 'Scan # ')
self.form.iscan   = Widget_Label(sc,   value = strtrim(string(self.data.iscan),2) )
self.form.nscans  = CW_Field(sc,   title = ' of Total of Scans', $
                             xsize = 4, uval = 'nscans', $
                             value = strtrim(string(self.data.nscans),2), $
                             /return_events)

; x  = Widget_Label(m,  value = 'Wait for Beam Lock?')
; b  = Widget_Base(m,  /nonexclusive)
; self.form.wait_lock = Widget_Button(b, xsize=60, value = '  ', uvalue= 'wait_lock')


mid   = widget_base(main,/col)
mt    = widget_base(mid,/row)
x     = Widget_Label(mt, xsize=60, value = 'File Name:')

self.form.datafile = Widget_Text(mt, xsize=40,ysize=1,  $
                                 uval='datafile', /editable,  value=self.datafile)

mt    = widget_base(mid,/row)
x     = Widget_Label(mt, xsize=60, value = 'Titles:')
self.form.usertext = Widget_Text(mt, xsize=70,ysize=3,  $
                                 /editable,  value="", $
                                 uval='usertext')

; mr    = widget_base(mid,/col)
; mxx   = widget_base(mr,/row)
; x     = Widget_Label(mxx,   value = 'Delay Between Scans')
; timx  = 5.0
; self.form.wait2dscan = CW_Field(mxx, value= timx,  uval= 'wait2dscan', $
;                                title = '', xsize=5,  /return_events, /floating)


m   = widget_base(main,/row,/frame)
x     = Widget_Label(m, value = 'X Position: ')
self.form.xpos     = Widget_Label(m, xsize = 150, value = ' ')
x     = Widget_Label(m, value = 'Y Position: ')
self.form.ypos     = Widget_Label(m, xsize = 150, value = ' ')

x   = widget_label(m,  value = 'Estimated time:')
self.form.time_est = Widget_Label(m, value = '     0:00:00.00')
x     = self.es->get_param('total_time')
widget_control, self.form.time_est, set_Value= sec2hms( x )

m     = widget_base(main,/row,/frame)
x     = Widget_Label(m, value = "Info:")
self.form.progress = Widget_Label(m, xsize =385, value = 'Ready To Scan')

x     = Widget_Label(m, value = 'Time Remaining: ')
self.form.time_rem = Widget_Label(m, xsize = 100, value = ' ')
ut =  sec2hms(0.d0)
widget_control, self.form.time_rem,  set_value = ut


Widget_Control, main, /realize
Widget_Control, self.form.draw,  get_value=d
self.form.draw_id = d
wset, self.form.draw_id
device, retain=1
!p.background = set_color('white')
!p.color      = set_color('black')
plot, intarr(100), /nodata

widget_control, self.form.timer,     time = 1.0
widget_control, main, set_uvalue=self
xmanager, 'scanviewer', main,  event='dummy_eh', /no_block

return, 1
end

pro scanviewer__define
;
;
@scan_dims     
p1pa  = fltarr( 4, MAX_SCAN_POINTS)
p2pa  = fltarr( 4, MAX_SCAN_POINTS)
p2pv  = strarr( 4)
da    = fltarr(MAX_DET, MAX_SCAN_POINTS)
i2    = [0L,0L]
p     = ptr_new()
o     = obj_new()


data  = {data, da:da, p1pa:p1pa, p2pa:p2pa, $
         x_cur:0., y1_cur:0., y2_cur:0,  $
         nscans:1, iscan:1 , $
         start_time:0.d00, save_med:0L, $
         p2pv:p2pv, wait2dscan:1.00 }


form  = {form, xpos:0L, ypos:0L, datafile:0L, $
         ynum:i2,  yden:i2, yop:i2, yval:i2, ycol:i2, ysym:i2, $
         iscan:0L, nscans:0L,    usertext:0L, $
         pause_btn:0L, start_btn:0L, progress:0L, $
         wait2dscan:0L,  wait_lock:0L, $
         scan_dim:0L, time_est:0L, time_rem:0L,$
         time:0L, timer:0L, draw:0L, draw_id:0L}

plot = {plot, det_num:i2, det_den:i2, det_op:i2, color:i2, psym:i2, $
        xlab:'', ylab:'', xunits:'', title:'', mdets:0L, $
        xsize:600, ysize:400,  charsize:1.3, npts:0, mpts:0, $
        syms:p, colors:p, operas:p, det_list:p}


monitors   = {monitors, exec:'', cpt:'', pause:'' }
scanviewer = {scanviewer, $ 
              es:      o, $
              form: form, $
              data: data, $
              plot: plot, $
              monitors: monitors, $
              datafile:'', $
              scanpv1:'', $
              scanpv2:'', $
              dimension:1, $
              ask_abort:0, ask_start:0, ask_pause:0, $
              wait_for_lock:0, $
              is_scan_master:0, is_paused:0, is_scanning:0,auto_paused:0, $
              npts_total:0,  cpt_total:0, $
              mpts1:0, mpts2:0,   cpt1:0, cpt2:0  }

return
end
