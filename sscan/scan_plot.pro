pro scan_plot_event, event

Widget_Control, event.top, get_uval = p
Widget_Control, event.id,  get_uval = uval

print, ' scan_exec_event: ', uval

return
end

function scan_plot, p
;
; gui for selecting detectors
;
print, 'scan and plot'

ret = (*p).es->lookup_detectors()
det = (*p).es->get_param('detectors')

info = {es:(*p).es, draw_id:0L } 


main   = Widget_Base(title = 'Scan Plotter', /col, app_mbar = mbar)
menu   = Widget_Button(mbar, value = 'File')
x      = Widget_Button(menu, value = 'Print ',           uval = 'print')
x      = Widget_Button(menu, value = 'Set Preferences',  uval = 'set_pref')
x      = Widget_Button(menu, value = 'Exit',             uval = 'exit', /separator)

menu   = Widget_Button(mbar, value = 'Detectors')
x      = Widget_Button(menu, value = 'Select  ...',      uval = 'det_select') 
x      = Widget_Button(menu, value = 'Advanced ...',     uval = 'advanced') 

menu   = Widget_Button(mbar, value = 'Options')
x      = Widget_Button(menu, value = 'Colors ...',       uval = 'colors') 
x      = Widget_Button(menu, value = 'Line Styles ...',  uval = 'styles') 

base  = widget_base(main,/row)
draw  = widget_draw(base, graphics_level=2, xsize=700, ysize=500)

bot   = widget_base(main,/row)
but   = widget_base(bot, /row)
x     = widget_button(but, val='Quit',                   uval = 'exit')
x     = widget_button(but, val='Zoom',                   uval = 'zoom')
x     = widget_button(but, val='Show Cursor',            uval = 'curs')
x     = widget_button(but, val='Pause Scan',             uval = 'pause_scan')


Widget_Control, draw, timer=0.25
Widget_Control, main, /realize
widget_control, id,   get_val=draw_id
info.draw_id  =draw_id
p_info = ptr_new(info,/no_copy)
Widget_Control, main, set_uvalue=p_info

xmanager, 'scan_plot', main, /no_block

x = fltarr(100)
y = fltarr(100)
wset, draw_id
for i = 0, 20 do begin
    x[i] = i * 1.0
    y[i] = sin(x[i])
    plot, x(0:i), y(0:i), psym=-1
    wait, 0.5
endfor
print, 'done '
return, 0
end
