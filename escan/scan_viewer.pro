function write_med_file, p, cpt
;
;  write med data file for full spectra
;

  med_file = (*p).data.datafile + '_xrf_'+ f2a(cpt+1) 
  if ((*p).data.scan_dim eq 2) then begin
      med_file = (*p).data.datafile + '_xrf_'+ f2a((*p).data.ipts2+1) + '_' + f2a(cpt+1) 
  endif
  (*p).med_obj->write_file, med_file
  print, ' wrote med file = ', med_file
  return, 0
end

pro check_feedback,  p
  print, ' check feedback'
return
end

pro do_scan1d, p, no_header=no_header
;
; does 'scan1' for scan_viewer
write_header = 1
if (keyword_set(no_header)) then  write_header= 0

x  = caput((*p).data.pausepv, 0)

(*p).data.scanning   = 1
(*p).data.paused     = 0

; (*p).data.start_time = xtime_s()
Widget_Control, (*p).form.usertext, get_value=titles

if (write_header) then begin
    x = (*p).es->start_scan1d(user_titles=titles)
endif else begin
    x = (*p).es->start_scan1d(/no_header)
endelse

sPV = (*p).data.scanPV

; print, ' Do_Scan started scan ', sPV

px  = fltarr(1000)
for i = 0, 3 do begin
    x =  string(i+1,format='(i1.1)')
    s = caget(sPV+'.P'+x+'PA', px)
    (*p).data.pa[i,*]  = px
endfor

x  = (*p).es->get_param('total_time')
widget_control, (*p).form.time_est,  set_value= sec2hms( x )
widget_control, (*p).form.pause_btn, set_value='Pause Scan'
widget_control, (*p).form.start_btn, set_value='Abort Scan'
widget_control, (*p).form.progress,  set_value='Scan Starting'
widget_control, (*p).form.timer,     time = 0.25

; print, ' Do_Scan Done'

return
end

pro scan_viewer_event, event
@scan_include

sPV =  (*p).data.scanPV
if (tag_names(event, /structure_name) eq 'WIDGET_TIMER') then begin
    cpt = -1
    j   = caget(sPV+'.CPT', ipt)
    if (j eq 0) then cpt = ipt
    if (cpt gt (*p).data.cpt1d) then begin
        (*p).data.cpt1d  = cpt
        print, ' Point ', cpt, ' of ', (*p).data.mpts1d
        for i = 0, MAX_DET-1 do begin
            ; det  =  string(i+1,format='(i1.1)')
            ; if (i ge 9) then  det = string(byte(i + 56))
            det =  string(i+1,format='(i2.2)') 
            s = caget(sPV+'.D'+det+'CV', x)
            (*p).data.da[i,cpt-1] = x
        endfor
        iya  = (*p).plot.det
        jmon = (*p).plot.monitor
        ; print, '  ', cpt,  (*p).data.pa[0,cpt-1],  (*p).data.da[iya,cpt-1]
        if  (cpt gt 1) then begin
            wset, (*p).form.draw_id
            plot, (*p).data.pa[0,0:cpt-1], (*p).data.da[iya,0:cpt-1], $
              psym=fix((*p).plot.psym), chars = 1.4, ystyle=16
        endif
        (*p).data.x_cur = (*p).data.pa[0,cpt-1]
        (*p).data.y_cur = (*p).data.da[iya,cpt-1]
        (*p).data.monitor = (*p).data.da[jmon,cpt-1]
        widget_control, (*p).form.xpos, set_value= f2a((*p).data.x_cur)
        widget_control, (*p).form.ypos, set_Value= f2a((*p).data.y_cur)
        widget_control, (*p).form.imon, set_Value= f2a((*p).data.monitor)
        prog_str = " Point " + f2a(cpt) + " / " + f2a( (*p).data.mpts1d )
        if ((*p).data.scan_dim eq 2) then begin
            prog_str = '2D Scan '+ f2a((*p).data.ipts2) + ' / ' + $
              f2a((*p).data.npts2) + '   ' + prog_str
        endif
        widget_control, (*p).form.progress, set_value = prog_str

        (*p).data.cpt2d = (*p).data.cpt2d + 1
        c2 = (*p).data.cpt2d 
        dt = (xtime_s() - (*p).data.start_time) 
        x  = dt * ((*p).data.mpts2d - c2) / c2
        ; print, ' time remaining = ' , dt, x, c2, (*p).data.mpts2d
        widget_control, (*p).form.time_rem, set_value = sec2hms(x)
    endif
    if ((*p).data.save_med eq 1) then begin
        am_waiting  = 0
        x  = caget((*p).data.scan_iswaiting, am_waiting)
        ; print, ' save med, scan wait: ', am_waiting
        if (am_waiting eq 1) then begin
            x = write_med_file(p,cpt)
            wait, 0.05
            x = caput((*p).data.scan_waitcount, 0)
        endif
    endif
    s = caget(sPV+'.EXSC', r)
    if (s ne 0) then begin
        wait, 0.02
        s = caget(sPV+'.EXSC', r)
    endif
    if ((s eq 0) and (r eq 0)) then begin
        print, 'scan done.  '
        cpt                = -1
        (*p).data.scanning = 0
        (*p).data.paused   = 0
        (*p).data.cpt1d    = 0
        widget_control, (*p).form.start_btn, set_value= 'Start Scan'
        widget_control, (*p).form.progress,  set_value= 'Scan Finished'
        ; final plot
        i    = (*p).plot.det
        ;det  =  string(i+1,format='(i1.1)')
        ;if (i ge 9) then  det = string(byte(i + 56))
        det  =  string(i+1,format='(i2.2)')
        s    = caget(sPV+'.D'+det+'DA', x)
        (*p).data.da[i,*] = x
        npt  = (*p).data.mpts1d
        plot, (*p).data.pa[0,0:npt-1], (*p).data.da[i,0:npt-1], $
          psym=fix((*p).plot.psym), chars = 1.4, ystyle=16

        ; 1d scan: close scanfile, increment scanfile, open next scanfile
        if ((*p).data.scan_dim eq 1) then begin
            x = (*p).es->write_scan_data()
            x = (*p).es->close_scanfile()
            (*p).data.cpt2d   = 0
            (*p).data.cpt1d   = 0
            prog_str = ' Scan Done:  wrote '+ (*p).data.datafile
            widget_control, (*p).form.progress,  set_value= prog_str
            (*p).data.datafile  = increment_scanname ( (*p).data.datafile )
            x  = (*p).es->set_param('datafile', (*p).data.datafile )
            widget_control, (*p).form.datafile, set_value=(*p).data.datafile
        ; multiple 1d scan:
            if ((*p).data.n_scans gt (*p).data.iscan) then begin
                (*p).data.iscan =  (*p).data.iscan  + 1
                widget_control, (*p).form.progress,  set_value=' Waiting ...'
                widget_control, (*p).form.iscan ,    set_value=  f2a((*p).data.iscan)

                lun = (*p).es->open_scanfile(/append)
                (*p).data.lun = lun
                printf, lun, '; Epics Scan ', (*p).data.scan_dim , ' dimensional scan'

                wait, (*p).data.wait2dscan
                prog_str = ' starting scan '+ f2a((*p).data.iscan)+ ' of '+ f2a((*p).data.n_scans)
                widget_control, (*p).form.progress,  set_value= prog_str
                (*p).data.cpt2d   = 0
                (*p).data.start_time = xtime_s()
                do_scan1d, p
            endif
        endif else if ((*p).data.scan_dim eq 2) then begin
            short_labels= 1
            if  ((*p).data.ipts2 gt 1 ) then short_labels=0
            x = (*p).es->write_scan_data(short_labels=short_labels)
            prog_str = ' 2D Scan: ' +  f2a((*p).data.ipts2) + ' / ' + f2a((*p).data.npts2) + $
              ' Done: wrote ' + (*p).data.datafile
            widget_control, (*p).form.progress,  set_value= prog_str
            if  ( ((*p).data.scanabort eq 0 ) and $
                  ((*p).data.ipts2 lt (*p).data.npts2) ) then begin
                inn  = (*p).data.ipts2
                (*p).data.ipts2 = (*p).data.ipts2 + 1
                (*p).data.lun   = (*p).es->get_param('lun')
                for i = 0, 3 do begin
                    px   = (*p).data.p2a[i,*]
                    pv_n = (*p).data.p2pv[i]
                    if (pv_n ne '') then begin
                        x = caput(pv_n, (*p).data.p2a[i,inn] )
                        printf, (*p).data.lun, ';2D ', pv_n, ': ',  f2a((*p).data.p2a[i,inn])
                    endif
                endfor
                x = wait_for_motor(motor = (*p).data.p2pv[0], maxtrys=200, wait_time=0.2)
                wait, (*p).data.wait2dscan
                widget_control, (*p).form.progress,  set_value='Starting ...'
                do_scan1d, p, /no_header
            endif else begin
                x = (*p).es->close_scanfile()
                prog_str = ' 2D Scan Done: wrote ' + (*p).data.datafile
                (*p).data.datafile  = increment_scanname ( (*p).data.datafile )
                x  = (*p).es->set_param('datafile', (*p).data.datafile )
                widget_control, (*p).form.datafile,  set_value=(*p).data.datafile
                widget_control, (*p).form.progress,  set_value= prog_str
            endelse
        endif
    endif
    
    if (((*p).data.scanning eq 1) and $
        ((*p).data.paused   eq 0) ) then  widget_control, event.id, timer=0.25
    
endif else begin
    widget_control, event.id,  get_uvalue=uval
    case uval of
        'exit':   Widget_Control, event.top, /destroy
        'proc': begin
        end
        'start_scan': begin
            (*p).data.scanabort= 0
            if ((*p).data.scanning eq 0) then begin
                widget_control, (*p).form.progress,  set_value='Waiting ...'
; update detector selection
                det      = (*p).es->get_param('detectors')
                det_desc = list_detectors(det,MAX_DET)
                Widget_Control, (*p).form.ysel, set_value=det_desc
                Widget_Control, (*p).form.ysel, set_droplist_SELECT = (*p).plot.det

;
; get data file name from form.datafile widget, open file and start writing
; to it
                Widget_Control, (*p).form.datafile, get_value=t
                (*p).data.datafile = strtrim(t,2)
                x  = (*p).es->set_param('datafile', (*p).data.datafile )
                (*p).data.iscan    = 1
                dim = (*p).data.scan_dim
                lun = (*p).es->open_scanfile(/append)
                (*p).data.lun = lun
                sc1 = (*p).es->get_param('scan1')
                (*p).data.mpts1d = sc1.npts_total
                (*p).data.mpts2d = (*p).es->get_param('npts_total')
                printf, lun, '; Epics Scan ', dim , ' dimensional scan'
                if (dim eq 2) then begin
; 2d scan:  get pvs needed for 2d scan, move to starting point
                    sc2  = (*p).es->get_param('scan2')
                    s2PV = sc2.scanPV
                    (*p).data.npts2  = sc2.npts_total
                    px   = fltarr(sc2.npts_total+2)
                    pv_n = ''
                    for i = 0, 3 do begin
                        ; print, ' i = ', i
                        x  =  string(i+1,format='(i1.1)')
                        s  = caget(s2PV+'.P'+x+'PA', px)
                        s  = caget(s2PV+'.P'+x+'PV', pv_n)
                        for jj = 0, n_elements(px)-1 do begin
                            (*p).data.p2a[i,jj]  = px[jj]
                        endfor
                        (*p).data.p2pv[i]   = pv_n
                        if (pv_n ne '') then begin
                            x = caput( pv_n , (*p).data.p2a[i,0] )
                            printf, (*p).data.lun, ';2D ',  pv_n, $
                              ': ', f2a((*p).data.p2a[i,0])
                        endif
                    endfor
                    (*p).data.ipts2  = 1
                endif
                (*p).data.start_time = xtime_s()
                do_scan1d, p
            endif else begin
; abort scan
                (*p).data.scanabort= 1
                (*p).data.scanning = 0
                (*p).data.paused   = 0
                (*p).data.cpt2d    = 0
                x = caput((*p).data.abortpv, 1)
                print ,  ' SCAN ABORTING '
                x = caput(sPV + '.EXSC', 0)
                widget_control, (*p).form.start_btn, set_value='Start Scan'
                widget_control, (*p).form.progress,  set_value='Scan Aborted'
                widget_control, (*p).form.iscan ,    set_value= f2a((*p).data.iscan)
            endelse
         end
        'pause_scan': begin
            if ((*p).data.scanning eq 1) then begin
                if ((*p).data.paused eq 0) then begin
                    (*p).data.paused = 1
                    widget_control, (*p).form.pause_btn, set_value='Resume '
                    widget_control, (*p).form.progress,  set_value='Scan Paused'
                    x = caput((*p).data.pausepv, 1)
                endif else begin
                    (*p).data.paused = 0
                    widget_control, (*p).form.pause_btn, set_value='Pause Scan'
                    x = caput((*p).data.pausepv, 0)
                    widget_control, (*p).form.timer,     time = 0.25
                endelse
            endif
        end
        'psym': begin           ; symbol to plot with
            isym = Widget_Info( (*p).form.psym, /droplist_select)            
            case isym  of
                0:  (*p).plot.psym =  0
                1:  (*p).plot.psym = -1
                2:  (*p).plot.psym = -2
                3:  (*p).plot.psym =  1
                4:  (*p).plot.psym =  2
            endcase
        end
        'pcolor': begin           ; color to plot with
            isym = Widget_Info( (*p).form.pcol, /droplist_select)            
            case isym  of
                0:  (*p).plot.psym =  0
                1:  (*p).plot.psym = -1
                2:  (*p).plot.psym = -2
                3:  (*p).plot.psym =  1
                4:  (*p).plot.psym =  2
            endcase
        end
        'ysel': begin  ;detector to plot
            iya  = Widget_Info( (*p).form.ysel, /droplist_select)
            (*p).plot.det = iya
            cpt  = -1
            st   = caget(sPV+'.CPT', ipt)
            if (st eq 0) then begin
                cpt = ipt
                wset, (*p).form.draw_id
                plot, (*p).data.pa[0,0:cpt-1], (*p).data.da[iya,0:cpt-1], $
                  psym=fix((*p).plot.psym), chars = 1.4, ystyle=16
            endif
        end
        'mon_sel': begin        ;monitor:  show value  of this detector
            j = Widget_Info( (*p).form.mon_sel, /droplist_select)
            (*p).plot.monitor = j
        end
        'wait2dscan': begin     ;time to wait to start 2d scan
            Widget_Control, (*p).form.wait2dscan, get_value=t
            (*p).data.wait2dscan = a2f(t)
        end
        'n_scans': begin
            Widget_Control, (*p).form.n_scans, get_value=t
            ; print,  ' # of scans = ', t
            (*p).data.n_scans = fix(strtrim(t,2))
        end
        'scan_dim': begin
            t = Widget_Info( (*p).form.scan_dim, /droplist_select)
                                ; print,  ' scan dimension = ', t
            (*p).data.scan_dim = t + 1
            x  = (*p).es->set_param('dimension', (*p).data.scan_dim )
        end
        'datafile': begin
            Widget_Control, (*p).form.datafile, get_value=t
            (*p).data.datafile = strtrim(t,2)
            x  = (*p).es->set_param('datafile', (*p).data.datafile )
        end
        'usertext': begin
        end
        'colors': begin
        end
        'save_med': begin
            (*p).data.save_med = event.select
            x = caput ((*p).data.scan_autowait, event.select)
        end
        'linestyles': begin
        end
        else: print, ' unknown event ', uval
    endcase
endelse

return
end

function scan_viewer, es
;
; gui for selecting detectors
;
print, 'Scan Viewer version 1.0'
;
; current scan is __always__ scan1
@scan_dims

sc       = es->get_param('scan1')
datafile = es->get_param('datafile')
mpts2d   = es->get_param('npts_total')
det      = es->get_param('detectors')
cur_dim  = es->get_param('dimension')
dgrp     = es->get_param('detgroups')
MED_PV   = dgrp.prefix[1]
prefix   = es->get_param('prefix')
pausepv  = prefix + 'scanPause.VAL'
abortpv  = prefix + 'AbortScans.PROC'
sPV      = sc.scanPV
mpts1d   = sc.npts_total

!p.background = set_color('white')
!p.color      = set_color('black')

caSetTimeout, 0.01
caSetRetryCount, 200

det_desc = list_detectors(det,MAX_DET)

pa    = fltarr( 4, MAX_SCAN_POINTS)
p2a   = fltarr( 4, MAX_SCAN_POINTS)
p2pv  = strarr( 4)
da    = fltarr(MAX_DET, MAX_SCAN_POINTS)
xsize = 800
ysize = 500
cpt2d =   0
cpt1d =   0
medx  = obj_new('EPICS_MED', MED_PV)  
scan_autowait  = sPV + '.AWCT'
scan_iswaiting = sPV + '.WTNG'
scan_waitcount = sPV + '.WAIT'
;
data  = {da:da, pa:pa, p2a:p2a,  mpts1d:mpts1d, mpts2d:mpts2d,xsize:xsize, ysize:ysize, $
         x_cur:0., y_cur:0., monitor:0., datafile:datafile, scan_dim:1, $,
         scanning:0, paused:0, n_scans:1, cpt2d:cpt2d, cpt1d:cpt1d, scanPV:sPV ,$
         pausepv:pausepv, abortpv:abortpv, iscan:1 , start_time:0.d00, save_med:0L, $
         scan_autowait:scan_autowait, scan_iswaiting:scan_iswaiting, $
         scan_waitcount:scan_waitcount, $
         npts2:0, p2pv:p2pv, ipts2:0, lun:0, wait2dscan:5.00, scanabort:0}

form  = {xpos:0L, ypos:0L, imon:0L, ppos:0L, datafile:0L, $
         ysel:0L,  mon_sel:0L, iscan:0L, usertext:0L, psym:0L,  $
         pause_btn:0L, start_btn:0L, progress:0L, wait2dscan:0L, save_med:0L, $
         user_text:0L, n_scans:0L, scan_dim:0L, time_est:0L, time_rem:0L,$
         det_choice:0L, time:0L, timer:0L, draw:0L, draw_id:0L}

plot_syms   = ['Solid', '-+-', '-*-', ' + ', ' * ']

plot_colors = ['white',   'black',   $
               'yellow',  'red',  'cyan', 'blue']


plot  = {det:0, monitor:0L, color:0L, psym:0, xlab:'',$
         ylab:'', title:'', charsize:1.3}
data.scanning  = 0
data.scanabort = 0
data.paused    = 0
info = {es:es, det:det, data:data, form:form, plot:plot, med_obj:medx}


info.data.save_med = 0
x  = caget(scan_autowait, m)
if (m ge 1) then begin
    info.data.save_med = 1
    x  = caput(scan_autowait, 1)
endif


main = Widget_Base(title = 'Scan Viewer', /col, app_mbar = mbar)
menu = Widget_Button(mbar, value = 'File')
x    = Widget_Button(menu, value = 'Print ',           uval = 'print')
x    = Widget_Button(menu, value = 'Set Preferences',  uval = 'set_pref')
x    = Widget_Button(menu, value = 'Exit',             uval = 'exit', /separator)


menu = Widget_Button(mbar, value = 'Options')
x    = Widget_Button(menu, value = 'Colors ...',       uval = 'colors')
x    = Widget_Button(menu, value = 'Line Styles ...',  uval = 'styles')


top            = widget_base(main,/row)


tl             = widget_base(top,/row,/frame)
X              = Widget_Label(tl, value = 'Detector to Plot: ')
info.form.ysel = Widget_DROPLIST(tl, value = det_desc,  title=' ', $
                                 uvalue = 'ysel', /dynamic_resize)
info.form.ypos = Widget_Label(tl, value = strtrim(string(data.y_cur),2), xsize=100 )
Widget_Control, info.form.ysel, set_droplist_SELECT = 0

X              = Widget_Label(tl, value = 'Symbol: ')
info.form.psym = Widget_DROPLIST(tl, value = plot_syms,  title=' ', $
                                 uvalue = 'psym', /dynamic_resize)
Widget_Control, info.form.psym, set_droplist_SELECT = 0

tl             = widget_base(top,/row,/frame)
X              = Widget_Label(tl, value = '  Monitor:  ')
info.form.mon_sel = Widget_DROPLIST(tl, value = det_desc,  title=' ', $
                                 uvalue = 'mon_sel', /dynamic_resize)
info.form.imon = Widget_Label(tl,  value = strtrim(string(data.monitor),2),xsize=100)
Widget_Control, info.form.mon_sel, set_droplist_SELECT = 0


info.form.timer = widget_base(main,/row)
info.form.draw  = widget_draw(info.form.timer, xsize=xsize, ysize=ysize)


mid   = widget_base(main,/row)
scs    = widget_base(mid,/row, /frame)
info.form.datafile = CW_Field(scs,   title = 'File Name', $
                              xsize = 35, uval = 'datafile', $
                              value = strtrim(datafile,2), $
                              /return_events)

scs    = widget_base(mid,/row, /frame)

x                 = Widget_Label(scs,   value = 'Scan # ')
info.form.iscan   = Widget_Label(scs,   value = strtrim(string(data.iscan),2) )

info.form.n_scans  = CW_Field(scs,   title = 'of Total # of Scans', $
                              xsize = 4, uval = 'n_scans', $
                              value = strtrim(string(data.n_scans),2), $
                              /return_events, /floating)

scan_dims    = ['1', '2', '3']
info.data.scan_dim = cur_dim
cur_dim      = cur_dim - 1

scs    = widget_base(mid,/row, /frame)
info.form.scan_dim = Widget_Droplist(scs, value= scan_dims,  uval= 'scan_dim', $
                                     title = ' Scan dimension: ')
Widget_Control, info.form.scan_dim,  set_Droplist_SELECT = cur_dim


mid   = widget_base(main,/row)
x     = widget_label(mid, value='Titles:')
info.form.usertext = Widget_Text(mid, xsize=60,ysize=3, uval='usertext',$
                                 /editable,  value="")

mright = widget_base(mid,/col)
mxx    = widget_base(mright,/row)
x      = Widget_Label(mxx,   value = 'Delay Between Scans')
timx   = 5.0
info.form.wait2dscan = CW_Field(mxx, value= timx,  uval= 'wait2dscan', $
                                title = '', xsize=5,$
                                /return_events, /floating)

mxx   = widget_base(mright,/row)
bbase = Widget_Base(mxx, /nonexclusive)
info.form.save_med = Widget_Button(bbase, xsize=60, value = '',  uvalue= 'save_med')
x      = Widget_Label(mxx,    value = 'Save full MED spectra')

Widget_Control, info.form.save_med, set_button= info.data.save_med
bot   = widget_base(main,/row)
but   = widget_base(bot, /row)
; x     = widget_button(but, val='Zoom',                   uval = 'zoom')
info.form.start_btn  = widget_button(but, val='Start Scan', $
                                     uval = 'start_scan')
info.form.pause_btn  = widget_button(but, val='Pause Scan',    uval = 'pause_scan')
x     = widget_button(but, val=' Exit ',                  uval = 'exit')
x     = widget_label(bot,  value = 'Estimated time:')


info.form.time_est = Widget_Label(bot,  xsize=190,value = '        ')
x   = es->get_param('total_time')
widget_control, info.form.time_est, set_Value= sec2hms( x )

bot  = widget_base(main,/row)
pbar = widget_base(bot,/row,/frame)

x  = Widget_Label(pbar, value = "Info:")
info.form.progress = Widget_Label(pbar,  xsize =300, value = 'Ready To Scan')

xbar  = widget_base(bot,/row,/frame)
x     = Widget_Label(xbar, value = 'X Position: ')
info.form.xpos   = Widget_Label(xbar, xsize = 110, value = ' ')

xbar  = widget_base(bot,/row,/frame)
x     = Widget_Label(xbar, value = 'Time Remaining: ')
info.form.time_rem   = Widget_Label(xbar, xsize = 120, value = ' ')


Widget_Control, main, /realize
Widget_Control, info.form.draw,  get_value=d
info.form.draw_id = d
wset, info.form.draw_id
device, retain=2

p_info = ptr_new(info,/no_copy)

Widget_Control, main, set_uvalue=p_info

xmanager, 'scan_viewer', main, /no_block

return, 0
end

