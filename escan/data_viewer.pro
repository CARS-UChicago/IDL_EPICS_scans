pro data_viewer_event, event
@scan_dims

Widget_Control, event.top, get_uval = p
widget_control, event.id,  get_uval = uval
ErrorNo = 0
Catch, ErrorNo
if (ErrorNo ne 0) then begin
    Catch, /CANCEL
    ErrA = ['Error!', 'Number' + strtrim(!error, 2), !Err_String]
    a = Dialog_Message(ErrA, /ERROR)
    return
endif

print, 'data viewer event, uval = ', uval, event.id
case uval of
    'exit':   Widget_Control, event.top, /destroy
    'proc': begin
    end
    'read_file': begin
        s_file = dialog_pickfile(filter='*.*', get_path=path, $
                                 /must_exist, /read, file = s_file)
        if (s_file ne '') then begin
            tmp_o  = read_scan(s_file)
            help, tmp_o
        endif
    end 
    'datafile': begin
        Widget_Control, (*p).form.datafile, get_value=t
        print, ' data file : ', t
    end
    'usertext': begin
    end
    'colors': begin
    end
    'linestyles': begin
    end
    else: print, ' unknown event ', uval
endcase

return
end

pro      data_viewer, file=file, use_dialog=use_dialog
;
; gui for selecting detectors
;
@scan_dims
print, 'Data Viewer version 1.0'
;
if (keyword_set (use_dialog)) then begin
    file = dialog_pickfile(filter='*.*', get_path=path, $
                           /write, file = init_file)
endif

; print, ' scanPV = ', sc.scanPV, cur_dim
; print, 'mpts: ' , mpts1d, mpts2d, ' current dimension = ', cur_dim

da    = fltarr(5,4)
xsize = 800
ysize = 495
cpt2d =   0
cpt1d =   0
;
datafile=''
px    = ptr_new()
data  = {files:px,da:da}
form  = {xpos:0L, ypos:0L, imon:0L, ppos:0L, datafile:0L, $
         ysel:0L,  mon_sel:0L, iscan:0L, usertext:0L, psym:0L,  $
         pause_btn:0L, start_btn:0L, progress:0L, wait2dscan:0L, $
         user_text:0L, n_scans:0L, scan_dim:0L, time_est:0L, time_rem:0L,$
         det_choice:0L, time:0L, timer:0L, draw:0L, draw_id:0L}

plot_syms   = ['Solid', '-+-', '-*-', ' + ', ' * ']

plot_colors = ['white',   'black',   $
               'yellow',  'red',  'cyan', 'blue']


!p.background = set_color('white')
!p.color      = set_color('black')

plot  = {det:0, monitor:0L, color:0L, psym:0, xlab:'',$
         ylab:'', title:'', charsize:1.3}

info = {data:data, form:form, plot:plot}

main = Widget_Base(title = 'Data Viewer', /col, app_mbar = mbar)
menu = Widget_Button(mbar, value = 'File')
x    = Widget_Button(menu, value = 'Read Scan File ...', uval = 'read_file')
x    = Widget_Button(menu, value = 'Export to ASCII ',   uval = 'ascii_export')
x    = Widget_Button(menu, value = 'Print',              uval = 'print')
x    = Widget_Button(menu, value = 'Exit',               uval = 'exit', /sep)


menu = Widget_Button(mbar, value = 'Options')
x    = Widget_Button(menu, value = 'Colors ...',       uval = 'colors')
x    = Widget_Button(menu, value = 'Line Styles ...',  uval = 'styles')

top  = Widget_Base(main,/row)
tl   = widget_base(top,/row,/frame)
X    = Widget_Label(tl, value = 'Detector to Plot: ')

X    = Widget_Label(tl, value = 'Symbol: ')
info.form.psym = Widget_DROPLIST(tl, value = plot_syms,  title=' ', $
                                 uvalue = 'psym', /dynamic_resize)
Widget_Control, info.form.psym, set_droplist_SELECT = 0

tl             = widget_base(top,/row,/frame)

mid   = widget_base(main,/row)
scs   = widget_base(mid,/row, /frame)
info.form.datafile = CW_Field(scs,   title = 'File Name', $
                              xsize = 35, uval = 'datafile', $
                              value = strtrim(datafile,2), $
                              /return_events)

info.form.timer = widget_base(main,/row)

scs    = widget_base(mid,/row, /frame)

mid   = widget_base(main,/row)
x     = widget_label(mid, value='title lines:')
info.form.usertext = Widget_Text(mid, xsize=60,ysize=3, uval='usertext',$
                                 /editable,  value="")


; Widget_Control, info.form.draw,  get_value=d
; info.form.draw_id = d
; wset, info.form.draw_id
; device, retain=2

Widget_Control, main, /realize
p_info = ptr_new(info,/no_copy)
Widget_Control, main, set_uvalue=p_info
xmanager, 'data_viewer', main, /no_block

return
end
