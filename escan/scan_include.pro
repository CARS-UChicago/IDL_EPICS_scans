
MAX_POS         =    4
MAX_DET         =   70
ETOK            =  0.2624682917

Widget_Control, event.top, get_uval = p
ErrorNo = 0
Catch, ErrorNo
if (ErrorNo ne 0) then begin
    Catch, /CANCEL
    ErrA = ['Error!', 'Number' + strtrim(!error, 2), !Err_String]
    a = Dialog_Message(ErrA, /ERROR)
    return
endif
current_scan = (*p).es->get_param('current_scan')
_scan        = 'scan' + string(strtrim(current_scan, 2))
sc           = (*p).es->get_param(_scan)
imotor       = sc.drives[0]
motor        = (*p).es->get_motor(imotor)
