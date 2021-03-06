pro plotwin_eh, event
; 
;  idl appears to require the event handler to be a procedure that 
;  is _not_ a class method.  We trick it by attaching 'self' to the 
;  top-base widget, and passing event to a real member function.
    widget_control, event.top, get_uvalue = p
    p->plotwin_event, event
return
end


pro main_eh, event
; 
;  idl appears to require the event handler to be a procedure that 
;  is _not_ a class method.  We trick it by attaching 'self' to the 
;  top-base widget, and passing event to a real member function.
;     print, ' main eh '
;     help, event
    widget_control, event.top, get_uvalue = p
    p->event, event
return
end


pro scanviewer::scan_finished

widget_control, self.form.start_btn, set_value='Start Scan'
widget_control, self.form.progress,  set_value='Scan Finished'
; widget_control, self.form.time_rem,  set_value = ' '

Widget_Control, self.form.nscans, get_value=t
old = self.data.nscans
self.data.nscans = fix(strtrim(t,2))>1

self.is_scanning = 0
self.data.donecount = 0
self.plot.show_zoombox = 0
self->plot_data

; print, ' scan finished '
self.scan_master  =  self.es->check_clientid()

if (self.scan_master eq 0) then begin
    prog_str = ' Scan Finished (observer mode)'
    self.es->set_observer_mode

    widget_control, self.form.progress,  set_value= prog_str
    return
endif
; 
;
if (self.dimension eq 1) then begin

    x = self.es->write_scan_data()
    prog_str = ' Scan Done:  wrote '+ self.datafile ;  self.es->get_param('datafile')
    widget_control, self.form.progress,  set_value= prog_str

    ;
    self.datafile  = increment_scanname ( self.datafile, /newfile)
    x  = self.es->set_param('datafile', self.datafile )
    widget_control, self.form.datafile, set_value=self.datafile

    self.cpt2   = 0
    self.cpt1   = 0  ; print, ' incrementing dim = 1 ', self.datafile
    
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
        self.is_scanning  = 0
        self.data.iscan   = 1
        widget_control, self.form.iscan ,    set_value=  f2a(self.data.iscan)
        widget_control, self.form.time_rem,  set_value = sec2hms(0.0)
    endelse
    
endif else if (self.dimension eq 2) then begin

    prog_str = ' 2D Scan: ' +  f2a(self.cpt2) + ' / ' + f2a(self.mpts2) + $
      ' Done: wrote ' + self.datafile
    widget_control, self.form.progress,  set_value= prog_str

    short_labels= 0
    if  (self.cpt2 gt 1 ) then short_labels=1
        
    x = self.es->write_scan_data(short_labels=short_labels)
    
    if  ( self.cpt2 lt self.mpts2 ) then begin
        self->start_scan,  /no_header
    endif else begin
        x = self.es->close_scanfile()
        self.datafile  = increment_scanname ( self.datafile, /newfile)
        prog_str = ' 2D Scan Done: wrote ' + self.datafile
        x  = self.es->set_param('datafile', self.datafile )
        widget_control, self.form.datafile,  set_value=self.datafile
        widget_control, self.form.progress,  set_value= prog_str
            
        self.cpt2       = 0
        self.mpts2      = self.es->npts(dim=2)
        
        if (self.data.nscans gt self.data.iscan) then begin
            self.data.iscan =  self.data.iscan  + 1
            widget_control, self.form.iscan ,    set_value=  f2a(self.data.iscan)
            prog_str = ' starting scan '+ f2a(self.data.iscan)+ ' of ' + $
              f2a(self.data.nscans)
            wait, self.data.wait2dscan
            widget_control, self.form.progress,  set_value= prog_str
            self->start_scan
        endif else begin
            self.is_scanning    = 0
            self.data.iscan   = 1
            widget_control, self.form.iscan ,    set_value=  f2a(self.data.iscan)
            widget_control, self.form.time_rem,  set_value = sec2hms(0.0)
        endelse
    endelse
endif

return
end

pro scanviewer::update_detector_lists

; print, ' update detector lists'

; update detector selection
ndet  = self.es->lookup_detectors()
d     = self.es->get_detector_list(/desc)

self.plot.mdets = self.es->get_param('ndetectors')
; print, ' mdets = ', self.plot.mdets, ndet, n_elements(d)
self.plot.det_list = ptr_new(['1.0' ,  d])

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

;
; get data from crate and plot it 
npts = self.cpt1

; print, ' I AM UPDATE_POINT ', npts
if (npts le 0) then begin
    prog_str = " Scan Starting..."
endif else begin
    prog_str = " Completed Point " + f2a(self.cpt1) + " / " + f2a( self.mpts1 )
endelse
; print, 'scanviewer update point ', prog_str
if (self.dimension eq 2) then begin
    if (self.scan_master eq 1) and (self.cpt2 ge 0) then begin
        prog_str = prog_str + '  Row '+ f2a(self.cpt2) + ' / ' + f2a(self.mpts2) 
    endif else begin
        prog_str = prog_str + '  (observer mode)'
        self.es->set_observer_mode
    endelse
endif
widget_control, self.form.progress, set_value = prog_str

widget_control, self.form.curs_move, sensitive=0


; time estimate
c  = self.cpt_total
tm = dxtime()
x  = ( (tm - self.data.start_time) * (self.npts_total - c) / (c>1) ) > 0
; print, 'time est: ', c, self.npts_total, tm-self.data.start_time, x
widget_control, self.form.time_rem, set_value = sec2hms(x)

if (self.cpt1 ge 1) then  begin
    s = caget(self.scanpv1+'.P1DV', x1)
    widget_control, self.form.xpos, set_value=f2a(x1)
endif
if ((self.cpt2 ge 1) and (self.dimension eq 2)) then $
  widget_control, self.form.ypos, set_value=f2a(self.data.p2pa[0,self.cpt2-1])

; self.plot.show_zoombox = 0
self->plot_data

return
end

pro scanviewer::init_plot

self.ppt = -1

mots = self.es->get_param('motors')
spv  = self.es->get_scan_param(0,'scanpv')
x    = ca_get(spv +'.P1PV', pvn)
for i = 0,  n_elements(mots.name)-1 do begin
    if (strtrim(mots.pv[i],2) eq pvn) then begin
        self.plot.xlab   = mots.name[i]
        self.plot.xunits = mots.units[i]
    endif
endfor

self->update_detector_lists
return
end

pro scanviewer::plot_data

;
; get data from crate and plot it 
npts = self.cpt1

self.ppt = self.ppt + 1
ppt = self.ppt

if ppt gt npts then begin
    ppt = npts
    self.ppt =ppt
endif

s = caget(self.scanpv1+'.R1CV', x1)
s = caget(self.scanpv1+'.P1DV', x2)

; print, 'this is plot_data ', npts, ppt

if (ppt le 0) then return

if (ppt le 2) then begin ; unzoom at beginning of scan
 self.plot.xr[0] = 0.
 self.plot.xr[1] = 0. 
 self.plot.yr[0] = 0.
 self.plot.yr[1] = 0.
 self.form.boxx1 = 0.
 self.form.boxy1 = 0.
 self.plot.title =  self.es->get_param('datafile')
endif


if (self.plot.yr[0] ne 0 and self.plot.yr[1] ne 0 ) then begin
    py0 = self.plot.yr[0] <  self.plot.yr[1]
endif
x   = 0.
if (self.is_scanning) then begin
    ; print, 'mdets = ', self.plot.mdets, npts
    for i = 0, self.plot.mdets - 1 do begin
        d = string(i+1,format='(i2.2)') 
        s = ca_get(self.scanpv1+'.D'+d+'CV', x)
        self.data.da[i,ppt-1] = x
    endfor
    for i = 0, 3 do begin
        d = string(i+1,format='(i1.1)')
        s = ca_get(self.scanpv1+'.R'+d+'CV', x)
        self.data.p1pa[i,ppt-1]  = x
    endfor
endif else begin
    for i = 0, 3 do begin
        d =  string(i+1,format='(i1.1)')
        s = ca_get(self.scanpv1+'.P'+d+'RA', x)
        self.data.p1pa[i,*]  = x
    endfor
    for i = 0, self.plot.mdets - 1 do begin
        d = string(i+1,format='(i2.2)') 
        s = ca_get(self.scanpv1+'.D'+d+'DA', x)
        self.data.da[i,*] = x
    endfor
    npts = self.mpts1
    ppt  = npts

    ; print,' plot_data: scan done :  ', npts
endelse



;
; trace 1
j_op  = Widget_Info(self.form.yop[0],  /droplist_select)
j_num = Widget_Info(self.form.ynum[0], /droplist_select)
j_den = Widget_Info(self.form.yden[0], /droplist_select)
j_col = Widget_Info(self.form.ycol[0], /droplist_select)
j_sym = Widget_Info(self.form.ysym[0], /droplist_select)


;  get sign and operation
asign = 1
xop  = (*self.plot.operas)[j_op]

if (strmid(xop,0,1) eq '-') then begin
    xop = strmid(xop,1,strlen(xop))
    asign = -1
endif

num1 = fltarr(self.plot.mpts) + 1
den1 = fltarr(self.plot.mpts) + 1

MAX_DET         =   70
if (j_num ne 0) then  begin
    if ((j_num gt 0) and (j_num le MAX_DET)) then num1 = self.data.da[j_num-1,0:ppt-1]
endif
if (j_den ne 0) then  begin
    if ((j_den gt 0) and (j_den le MAX_DET)) then den1 = self.data.da[j_den-1,0:ppt-1]
endif
    
y1 =  num1/(den1> 1.e-8)

case xop of
    'log':         y1 =  alog(y1 > 1.e-8)
    'derivative':  begin
        if (ppt ge 3) then   y1 =  deriv(y1)
    end
    'log-derivative':   begin
        if (ppt ge 3) then   y1 =  deriv(alog(y1 > 1.e-8))
    end
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


px0 = min(self.data.p1pa[0,0:ppt-1])
px1 = max(self.data.p1pa[0,0:ppt-1])
py0 = min(asign*y1)
py1 = max(asign*y1)

if (self.plot.xr[0] ne 0 and self.plot.xr[1] ne 0 ) then begin
    px0 = self.plot.xr[0] <  self.plot.xr[1]
    px1 = self.plot.xr[0] >  self.plot.xr[1]
endif

if (self.plot.yr[0] ne 0 and self.plot.yr[1] ne 0 ) then begin
    py0 = self.plot.yr[0] <  self.plot.yr[1]
    py1 = self.plot.yr[0] >  self.plot.yr[1]
endif

; print, ' color: ', (*self.plot.colors)[j_col] ,' ', set_color( (*self.plot.colors)[j_col] )

; print, ' plot_data ', npts, px0, px1, py0, py1

if (ppt ge 1) then begin
    l =  self.plot.xlab + ' [' + self.plot.xunits + ']'
    plot,  self.data.p1pa[0,0:ppt-1], asign*y1, ystyle=17,  xtickformat='(g12.6)', $
      charsize=self.plot.charsize, title=self.plot.title, $
      xtitle = l, /nodata, xr=[px0,px1], yr=[py0,py1]

    oplot, self.data.p1pa[0,0:ppt-1], asign*y1, psym=psym1, $
      color=set_color( (*self.plot.colors)[j_col] )

    if (do_plot2) then begin
        oplot, self.data.p1pa[0,0:ppt-1], y2, psym=psym2, $
          color=set_color( (*self.plot.colors)[jcol2] )
    endif

    if (self.plot.show_zoombox eq 1) then begin
       ; print, ' show zoom ', self.plot.zoom_x, self.plot.zoom_y

        x0 = self.plot.zoom_x[0]
        x1 = self.plot.zoom_x[1]
        y0 = self.plot.zoom_y[0]
        y1 = self.plot.zoom_y[1]

        oplot, [x0,x0], [y0,y1], color=set_color('red')
        oplot, [x0,x1], [y0,y0], color=set_color('red')
        oplot, [x0,x1], [y1,y1], color=set_color('red')
        oplot, [x1,x1], [y0,y1], color=set_color('red')

     endif
endif
return
end

pro  scanviewer::abort
; print, 'ScanViewer aborting scan'
; abort scan

widget_control, self.form.progress,  set_value='Aborting Scan'
self.ask_abort   = 1
self->pause, force = 0

self.is_scanning = 0
self.is_paused   = 0
self.auto_paused = 0
self.cpt1        = 0
self.cpt2        = 0

self.es->abort
self->pause, force = 0

; 
if (self.dimension eq 1) then x = self.es->write_scan_data()
x = self.es->close_scanfile()

wait, 1.0

self.datafile  = increment_scanname ( self.datafile , /newfile)
x  = self.es->set_param('datafile', self.datafile )
widget_control, self.form.datafile, set_value=self.datafile


widget_control, self.form.start_btn, set_value='Start Scan'
widget_control, self.form.progress,  set_value='Scan Aborted'
widget_control, self.form.iscan ,    set_value= f2a(self.data.iscan)
widget_control, self.form.time_rem,  set_value= ' '

self.scan_master = 0
self.es->abort

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

; if ((self.scan_master) and (self.is_scanning eq 1)) then begin
if ((forced eq 1) or (self.is_scanning eq 1)) then begin
    p = 0
    if (self.is_paused eq 0) then p = 1
    if (forced) then p = val
    self.is_paused = p
    ;print, ' scanviewer pause ', p
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
   print, 'onto the next 2d row...'
   if (self.data.save_med eq 1) then begin
       s1 = ca_get(self.monitors.cpt, s1x)
       if (self.cpt2 gt 1)  then begin
           x = self.es->save_med_spectra(row=self.cpt2-1)
       endif
   endif

  widget_control, self.form.progress,  set_value='Moving to Next Row ...'
  for i = 0, 3 do begin
      if (self.data.p2pv[i] ne '') then $
          x   = caput(self.data.p2pv[i], self.data.p2pa[i,self.cpt2-1])
  endfor

  wait, self.data.wait2dscan
  ; now, really wait for motor to be done
  for i = 0, 3 do begin
      if (self.data.p2pv[i] ne '') then $
          x   = caput(self.data.p2pv[i], self.data.p2pa[i,self.cpt2-1],/wait)
  endfor

  for i = 0, 3 do begin
      if (self.data.p2pv[i] ne '') then begin
          ; print, ' pos ', i, self.data.p2pv[i]
          x   = ca_get(self.data.p2pv[i], cpv)
          self.data.p2pa[i,self.cpt2-1] = cpv
          str = ';2D ' + self.data.p2pv[i] + ': ' +  f2a(cpv)
          x   = self.es->write_to_scanfile(str)
      endif
  endfor

  widget_control, self.form.progress,  set_value='Starting ...'
  ; print, ' starting 2D scan cpt1 = ',  self.cpt1       
  self.is_scanning = 1
return
end

pro scanviewer::become_scan_master
   self.es->set_clientid
   self.scan_master    = 1
return
end


pro scanviewer::start_scan, no_header=no_header
;
; does 'scan1' for scan_viewer

print,'start scan!!'
write_header = 1
if (keyword_set(no_header)) then  write_header= 0

self->become_scan_master 

self.is_scanning    = 1
self.is_paused      = 0
self.auto_paused    = 0


self.dimension = self.es->get_param('dimension')


Widget_Control, self.form.curs_move, sensitive=0
Widget_Control, self.form.datafile, get_value=t
self.datafile = strtrim(t,2)
x  = self.es->set_param('datafile', self.datafile )

self.mpts1    = self.es->npts(dim=1)

lun =  self.es->open_scanfile(/append)
if ((self.dimension eq 1) or (self.cpt2 le 0)) then $
  str =  '; Epics Scan ' + f2a( self.dimension) +  ' dimensional scan'
x   = self.es->write_to_scanfile(str)                
self.cpt1  = 0


widget_control, self.form.progress,  set_value=' Waiting ...'
widget_control, self.form.iscan ,    set_value=  f2a(self.data.iscan)

mots = self.es->get_param('motors')

px  = fltarr(self.mpts1+2)
spv = self.es->get_scan_param(0,'scanpv')

print ,' start_scan:  ', self.dimension, self.npts_total, spv

for i = 0, 3 do begin
    x = string(i+1,format='(i1.1)')
    s = ca_get(spv+'.P'+x+'PA', px)
    self.data.p1pa[i,*]  = px
endfor


x  = ca_get(spv +'.P1PV', pvn)
self.motor1pv = pvn

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



pro scanviewer::plotwin_event, event
;
;  event handler for plotwindow
;
; 

t = convert_coord( event.x, event.y, /device, /to_data)
if (event.type eq 0) then begin   ; mouse down
    self.form.zoom_mode = 1
    self.form.boxx0 = f2a(t[0])
    self.form.boxy0 = f2a(t[1])
    self.form.boxx1 = event.x
    self.form.boxy1 = event.y

endif else if (event.type eq 1) then begin ; mouse up
    widget_control, self.form.cursx, set_value=f2a(t[0])
    widget_control, self.form.cursy, set_value=f2a(t[1])
    
    if (self.is_scanning ne 1) then begin
        widget_control, self.form.curs_move, sensitive = 1
    endif

    self.form.zoom_mode = 0
    self.plot.show_zoombox = 0
; test that zoom box is at least 2 pixels wide...
    if ( (abs(event.x -self.form.boxx1) gt 2) and $
         (abs(event.y -self.form.boxy1) gt 2) ) then begin

        self.plot.xr[0] = self.form.boxx0
        self.plot.yr[0] = self.form.boxy0
        self.plot.xr[1] = f2a(t[0])
        self.plot.yr[1] = f2a(t[1])
        self->plot_data
        widget_control, self.form.curs_zoom, sensitive = 1
    endif
    
endif else if (event.type eq 2 and self.form.zoom_mode eq 1) then begin ; motion
    ; draw zoom box
    if ( (abs(event.x -self.form.boxx1) gt 2) and $
         (abs(event.y -self.form.boxy1) gt 2) ) then begin

        self.plot.show_zoombox=1
        self.plot.zoom_x = [self.form.boxx0, f2a(t[0])]
        self.plot.zoom_y = [self.form.boxy0, f2a(t[1])]
        self->plot_data
    endif
endif


; if ((self.cpt2 ge 1) and (self.dimension eq 2)) then $
;   widget_control, self.form.ypos, set_value=f2a(self.data.p2pa[0,self.cpt2-1])

                                ; help, event
; endelse



return
end


pro scanviewer::event, event
;
; the real event handler
;
MAX_POS         =    4
MAX_DET         =   70
ETOK            =  0.2624682917


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
    s         = caget(self.monitors.cpt, cpt)
    ; print, 'scanviewer event ' , mon_cpt, mon_exec, self.is_scanning

    if (s lt 0) then begin
        s    = caget(self.monitors.cpt, cpt)
        if (s lt 0) then  cpt = self.cpt1
    endif

;
    if (mon_exec) then begin
        s = caget(self.monitors.exec,exec)
        self.scan_master  =  self.es->check_clientid()
    ; print, 'V Event ', mon_exec, mon_pause, mon_cpt, s

        if (self.is_scanning and (exec eq 0)) then   begin
            wait, 0.1
            self->scan_finished
            self.cpt1    = 0
            x = caget(self.monitors.npts,xnpts)
            self.mpts1 = xnpts
        endif
        self.is_scanning = exec
        ; print, ' mon exec event : points: ' , self.cpt1, self.mpts1
        ; print, ' exec, is_scanning, master', exec, self.is_scanning, self.scan_master
        if (exec eq 1) then begin
            self->init_plot
            if (self.dimension eq 1) then self.data.start_time = systime(1)
        endif

    endif
;
    if (mon_pause) then begin
        paused = self.is_paused
        s      = caget(self.monitors.pause,paused)
        if (paused ne self.is_paused) then  self->pause
    endif


;
; check feedback lock and shutter
; if scanning (and if this is the scan master) then 
    if ((self.wait_for_beam eq 1) and (self.is_scanning eq 1)) then begin
        ok_x   = self.es->beam_ok()
        ;  print, 'beam_ok = ', ok_x
        ; if (self.scan_master eq 1) then begin
        if ((self.auto_paused eq 0) and (ok_x eq 0)) then begin
            self.auto_paused   = 1
            self->pause, force = 1
        endif else if ((self.auto_paused eq 1) and (ok_x eq 1)) then begin
            self.auto_paused   = 0
            self->pause, force = 0
        endif
        ; endif
        if (ok_x eq 0) then begin
            widget_control, self.form.progress,  set_value='Scan Paused: No Beam'
        endif
    endif
    
    if (mon_cpt) then begin
        s         = caget(self.monitors.cpt, cpt)
        if (s lt 0) then begin
            s    = caget(self.monitors.cpt, cpt)
            if (s lt 0) then  cpt = self.cpt1
        endif
        self.cpt1      = cpt
        self.cpt_total = self.cpt_total + 1
        ; print, 'point ( ', self.cpt1, cpt, ' )'
        if (self.is_scanning)  then self->update_point
    endif

    if (self.data.save_med eq 1) then begin
        ; print, 'MN saving med spectra ', self.cpt1, self.med_point
        sready_to_read = self.es->check_scan_wait()
        if (sready_to_read eq 1) then  begin
            ; print, 'MN write med spectra ', s1x, self.cpt2
            x = self.es->save_med_spectra(row=self.cpt2)
            x = self.es->clear_scan_wait()
        endif
    endif

    msg = ''

    if (self.is_scanning and (cpt  eq self.mpts1) and self.scan_master eq 1) then begin
        print, 'scan appears done: ', cpt, self.cpt2, self.data.donecount
        self.data.donecount = self.data.donecount + 1
        wait, 0.1
        cpt = 0
        if (self.data.donecount gt 5) then  begin
            print,' forcing scan to finished '
            self->scan_finished
            self.cpt1           = 0
            self.data.donecount = 0
            self.is_scanning    = 1
        endif
        self.is_scanning = 0
    endif

    widget_control, event.id, timer=0.25

endif else begin
    widget_control, event.id,  get_uvalue=uval
    if (strpos(uval,'trace_') ge 0) then  begin
        ; print, ' trace event: ', event.top
        self->update_detector_lists
        self->plot_data
    endif
    x  = self.es->get_param('total_time')
    widget_control, self.form.time_est,  set_value= sec2hms( x )
    case uval of
        'exit':         Widget_Control, event.top, /destroy
        'pause_scan':   self->pause
        'wait_lock':    self.wait_for_beam =event.select
        'start_scan': begin
            self.dimension = self.es->get_param('dimension')
            ; print, 'uval=start scan  ', self.is_scanning, self.dimension, self.is_scanning

            self->become_scan_master
            self->init_plot
            if (self.dimension eq 1) then self.data.start_time = systime(1)

            if (self.is_scanning eq 0)  then begin
                Widget_Control, self.form.datafile, get_value=t
                self.datafile = self.es->guarantee_new_datafile(t)
                Widget_Control, self.form.datafile, set_value=self.datafile
                ; print, 'datafile: was ', t, ' now ', self.datafile

                self->update_detector_lists
                self.data.save_med  = self.es->get_param('save_med')
                ; print, 'MN will save_med = ',                 self.data.save_med
                self.scan_master = 1
                self.data.iscan     = 1
                self.data.donecount = 0
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
                        s  = ca_get(s2pv+'.P'+x+'PA', px)
                        for jj = 0, n_elements(px)-1 do self.data.p2pa[i,jj]  = px[jj]
                        s  = ca_get(s2pv+'.P'+x+'PV', pvn)
                        self.data.p2pv[i]   = pvn
                    endfor
                endif
                self.data.start_time = dxtime()
                self->start_scan
                ; self.plot.show_zoombox = 0
                mon_exec = cacheckmonitor(self.monitors.exec)
                s        = ca_get(self.monitors.exec,exec)
            endif else begin
                self->abort
            endelse
        end
        'datafile': begin
            Widget_Control, self.form.datafile, get_value=t
            ;# x  = self.es->set_param('datafile', self.datafile )
            self.datafile = self.es->guarantee_new_datafile(t)
            Widget_Control, self.form.datafile, set_value=self.datafile
            self->update_detector_lists
        end
        'nscans': begin
            Widget_Control, self.form.nscans, get_value=t
            old = self.data.nscans
            self.data.nscans = fix(strtrim(t,2))>1
            if (self.is_scanning) then $
                self.npts_total = self.npts_total * self.data.nscans  / (old>1)
        end
        'force_update': begin
            self.is_scanning = 1
            if (self.force_me eq 1) then  self.force_me = 0 else self.force_me = 1
            self->update_point
        end
        'moveto': begin
            x  = ca_get(self.scanpv1 +'.P1PV', pvn)
            self.motor1pv = pvn
            if (self.motor1pv ne '') then begin
                widget_control, self.form.cursx, get_value=x
                x = caput(self.motor1pv, x)
            endif
        end

        'zoomout': begin
            self.plot.xr[0] = 0
            self.plot.xr[1] = 0 
            self.plot.yr[0] = 0
            self.plot.yr[1] = 0 
            self.plot.show_zoombox = 0
            self->plot_data
            widget_control, self.form.curs_zoom, sensitive = 0
        end
        else: x=1
    endcase
endelse

return
end

function scanviewer::init, escan=escan, scan_file=scan_file, prefix=prefix, $
                   plot_size=plot_size
;
; gui for viewing and running epics scans:
; uses Epics Scan object, which can be supplied or created
; arguments: (give one 
;    escan       Epics Scan object 
;    scan_file   name of valid scan file to use for Epics Scan creation
;    prefix      Epics prefix PV  ('13IDA:') for Epics Scan creation
;
print, ' This is ScanViewer version 2.10'
;
MAX_POS         =    4
MAX_DET         =   70
ETOK            =  0.2624682917

plotsize = 750.0
if (keyword_set(plot_size) ne 0)  then plotsize = plot_size

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
self.msgpv   = self.scanpv1 + '.SMSG'

self.mpts1   = self.es->npts(dim=1)
self.mpts2   = self.es->npts(dim=2)
self.datafile= self.es->get_param('datafile')
self.wait_for_beam = 0
self.dimension      = cur_dim
self.data.nscans    = 1
self.data.iscan     = 1
self.data.wait2dscan= 1.0

self.force_me       = 0
self.is_scanning    = 0
self.is_paused      = 0
self.auto_paused    = 0

self.monitors.exec  = self.scanpv1 + '.EXSC'
self.monitors.cpt   = self.scanpv1 + '.CPT'
self.monitors.npts  = self.scanpv1 + '.NPTS'
self.monitors.pause = prefix + 'scanPause.VAL'

self->become_scan_master

tags = tag_names(self.monitors)
u = ''
for i = 0, n_tags(self.monitors)-1 do begin
    x = casetmonitor(self.monitors.(i))
    x = ca_get(self.monitors.(i), u)
endfor

device, /decomposed
!p.background = set_color('white')
!p.color      = set_color('black')

self.plot.charsize  = 1.5
self.plot.xlab      = ''
self.plot.xunits    = ''

self.plot.xsize   = fix(plotsize)
self.plot.ysize   = fix(plotsize * (0.63))
self.plot.syms    = ptr_new(['Solid', '-+-', '-*-', ' + ', ' * '])
self.plot.colors  = ptr_new(['blue',   'black', 'red',      'darkgreen', $
                            'magenta', 'cyan', 'goldenrod', 'purple'])

self.plot.operas   = ptr_new(['   ','log','-log','derivative','-derivative','log-derivative','-log-derivative'])
self.plot.det_list = ptr_new(['1.0', det_desc])
self.plot.mpts     = max_scanpts(self.scanpv1)

main = Widget_Base(title = 'Scan Viewer', /col, app_mbar = mbar)
menu = Widget_Button(mbar, value = 'File')
x    = Widget_Button(menu, value = 'Exit',             uval = 'exit', /separ)

top  = widget_base(main,/row)
tx   = widget_base(top,/col)

uv_  = ['op','num','den', 'sym','col']
; ttls = ['Trace 1:', 'Trace 2:']
ttls = ['Plot: ', 'Trace 2:']

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
self.form.draw  = widget_draw(main, xsize=self.plot.xsize, ysize=self.plot.ysize, $
                              /button_events, /motion_events, $
                              event_pro='plotwin_eh')

m0     = widget_base(main, /row)

self.form.start_btn  = widget_button(m0, val=' Start Scan ',  ysize=35, uval = 'start_scan')
self.form.pause_btn  = widget_button(m0, val=' Pause Scan ',  uval = 'pause_scan')

x     = Widget_Label(m0,   value = 'Scan # ')
self.form.iscan   = Widget_Label(m0,   value = strtrim(string(self.data.iscan),2) )
x     = Widget_Label(m0,   value = ' of Total Scans = ')

ns  = strtrim(string(self.data.nscans),2) 
self.form.nscans = Widget_Text(m0, xsize=5,  ysize=1,  /editable, $
                               uval = 'nscans',   value = ns)


; x  = Widget_Label(m0,  value = '  Automatically Pause Scan when beam is lost?')
; b  = Widget_Base(m0,  /nonexclusive)
; self.form.wait_lock = Widget_Button(b, xsize=60, ysize=35, value = '   ', $
;                                     uvalue= 'wait_lock')


midrow = widget_base(main, /row)
col01  = widget_base(midrow, /col)
col02  = widget_base(midrow, /col , /frame)

m1   = widget_base(col01,/row)
x     = Widget_Label(m1, xsize=65, value = 'File Name:')
self.form.datafile = Widget_Text(m1, xsize=65,ysize=1,  $
                                 uval='datafile', /editable,  value=self.datafile)

m2    = widget_base(col01,/row)
x     = Widget_Label(m2, xsize=65, value = 'Titles:')
self.form.usertext = Widget_Text(m2, xsize=65,ysize=3,  $
                                 /editable,  value="", $
                                 uval='usertext')


self.form.cursor_info  = col02
m3 = widget_base(col02,/row)

x     = Widget_Label(m3,   value = '  Cursor Position: ')

m3    = widget_base(col02,/row)
x     = Widget_Label(m3,   value = '  X ')
self.form.cursx  = Widget_Label(m3, xsize = 100, value = ' ')
x     = Widget_Label(m3, value = ' Y: ')
self.form.cursy  = Widget_Label(m3, xsize = 100, value = ' ')

m4    = widget_base(col02,/row)

self.form.curs_move = Widget_Button(m4,  uvalue = 'moveto', $
                                   value= ' Move to Cursor Position ')

self.form.curs_zoom = Widget_Button(m4,  uvalue = 'zoomout', $
                                   value= ' Zoom Out ')


widget_control, self.form.curs_move, sensitive = 0
widget_control, self.form.curs_zoom, sensitive = 0
; x     = Widget_Label(m,   value = 'Delay Between Scans'
; timx  = 5.0
; self.form.wait2dscan = CW_Field(m, value= timx,  uval= 'wait2dscan', $
;                                title = '', xsize=5,  /return_events, /floating)


m   = widget_base(main,/row,/frame)
x     = Widget_Label(m, value = 'X Position: ')
self.form.xpos     = Widget_Label(m, xsize = 120, value = ' ')
x     = Widget_Label(m, value = 'Y Position: ')
self.form.ypos     = Widget_Label(m, xsize = 120, value = ' ')

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

widget_control, self.form.timer,     time = 0.25
widget_control, main, set_uvalue=self
xmanager, 'scanviewer', main,  event='main_eh', /no_block

return, 1
end

pro scanviewer__define
;
;
MAX_POS         =    4
MAX_DET         =   70
ETOK            =  0.2624682917
; MAX_SCAN_POINTS = 1000
MAX_SCAN_POINTS = 2000

p1pa  = fltarr( 4, MAX_SCAN_POINTS)
p2pa  = fltarr( 4, MAX_SCAN_POINTS)
p2pv  = strarr( 4)
da    = fltarr(MAX_DET, MAX_SCAN_POINTS)
i2    = [0L,0L]
f2    = [0.0,0.0]
p     = ptr_new()
o     = obj_new()


data  = {data, da:da, p1pa:p1pa, p2pa:p2pa, $
         x_cur:0., y1_cur:0., y2_cur:0,  $
         nscans:1, iscan:1, donecount:0, $
         start_time:0.d00, save_med:0L, med_hung:0L, $ 
         p2pv:p2pv, wait2dscan:1.00 }


form  = {form, xpos:0L, ypos:0L, datafile:0L, $
         ynum:i2,  yden:i2, yop:i2, yval:i2, ycol:i2, ysym:i2, $
         iscan:0L, nscans:0L,    usertext:0L, $
         pause_btn:0L, start_btn:0L, progress:0L, $
         wait2dscan:0L,  wait_lock:0L, $
         scan_dim:0L, time_est:0L, time_rem:0L,$
         time:0L, timer:0L, draw:0L, draw_id:0L,$
         cursor_info:0L, cursx:0L, cursy:0L, curs_move:0L, curs_zoom:0L, $
         zoom_mode:0L, boxx0:0.,boxx1:0.,boxy0:0.,boxy1:0. }


plot = {plot, det_num:i2, det_den:i2, det_op:i2, color:i2, psym:i2, $
        xlab:'', ylab:'', xunits:'', title:'', mdets:0L, $
        xsize:600, ysize:400,  charsize:1.3, npts:0, mpts:0, $
        syms:p, colors:p, operas:p, det_list:p, $
        xr:f2,yr:f2,show_zoombox:0L, zoom_x:f2, zoom_y:f2}


monitors   = {monitors, exec:'', cpt:'', pause:'' ,npts:''}
scanviewer = {scanviewer, $ 
              es:      o, $
              form: form, $
              data: data, $
              plot: plot, $
              monitors: monitors, $
              datafile:'', $
              scanpv1:'', $
              scanpv2:'', $
              motor1pv:'', $
              msgpv:'', $
              force_me:0,$
              dimension:1, $
              ask_abort:0, ask_start:0, ask_pause:0, $
              wait_for_beam:0, $
              scan_master:0, is_paused:0, is_scanning:0,auto_paused:0, $
              npts_total:0,  cpt_total:0, $
              med_point:-1L,$
              mpts1:0, mpts2:0,   cpt1:0, cpt2:0 , ppt:-1 }


return
end
