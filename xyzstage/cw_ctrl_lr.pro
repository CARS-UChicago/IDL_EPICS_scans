;+
; NAME:
;       CW_CTRL_LR
;
; PURPOSE:
;       This procedure creates a control pad widget with eight
;       bitmap buttons pointing in the north, south, east, west,
;       northeast, northwest, southeast, and southwest directions
;
;       When a button is on the control pad and event structure
;       is passed that indicates the direction of the button
;       that was pressed
;
; CATEGORY:
;       Compound Widgets
;
; CALLING SEQUENCE:
;       Id = CW_CTRLPAD(parent)
;
; INPUTS:
;       parent: The widget ID of the parent base for the compound
;               widget
;
; KEYWORD PARAMETERS:
;       VALUE: Set this keyword to a string that will contain a
;              label for the control pad
;       PAD_FRAME: Set this keyword to a non-zero value to cause
;              a frame to be drawn around the control pad
;       COLUMN: Set this keyword to a non-zero value to align
;               the label on top of the control pad
;       ROW: Set this keyword to a non-zero value to align
;               the label to the right of the control pad
; MODIFICATION HISTORY:
;       Written by:     BL, June 1997.
;-

FUNCTION CTRL_LR_EH, event

; The ID of the control pad is the base that the handler is attached
; to set up a variable to hold this value for use in the return
; structure

base = event.handler

; create the return structure that will pass through as the event
; structure for this compound widget. Start everything off as 0

ret = {CW_CTRL_LR_EVENT, ID:base, TOP:event.top, HANDLER:0L, $
        NORTH:0, SOUTH:0, WEST:0, EAST:0, NEast:0, SEast:0, $
        NWest:0, SWest:0, Reset:0, LEFT:0, RIGHT:0, MIDDLE:0}

; get the user value of the button that caused the event

WIDGET_CONTROL, event.id, GET_UVALUE = uval

; set the field of the structure corresponding to the button pressed
; to 1. The event structure should have all zeros except the field that
; corresponds to the button that was pressed

case uval of
    'toLeft':   ret.LEFT   = 1
    'toRight':  ret.RIGHT  = 1
    'toMiddle': ret.MIDDLE = 1
    else: x = 1
endcase
return, ret
end

FUNCTION CW_CTRL_LR, parent, VALUE = value, PAD_FRAME = pad_frame, $
    _EXTRA = extra

; define the bitmaps for the buttons

westBM =   [        $
    [192B, 003B],      $
    [224B, 001B],      $
    [240B, 000B],      $
    [120B, 000B],      $
    [060B, 000B],      $
    [030B, 000B],      $
    [255B, 255B],      $
    [255B, 255B],      $
    [255B, 255B],      $
    [255B, 255B],      $
    [030B, 000B],      $
    [060B, 000B],      $
    [120B, 000B],      $
    [240B, 000B],      $
    [224B, 001B],      $
    [192B, 003B]      $
    ]

eastBM =   [        $
    [192B, 003B],      $
    [128B, 007B],      $
    [000B, 015B],      $
    [000B, 030B],      $
    [000B, 060B],      $
    [000B, 120B],      $
    [255B, 255B],      $
    [255B, 255B],      $
    [255B, 255B],      $
    [255B, 255B],      $
    [000B, 120B],      $
    [000B, 060B],      $
    [000B, 030B],      $
    [000B, 015B],      $
    [128B, 007B],      $
    [192B, 003B]      $
    ]

                                ;blank bitmap
                                ;definition
blankBM =   [ [000B, 000B],  [000B, 000B], $
              [000B, 000B],  [000B, 000B], $
              [000B, 000B],  [000B, 000B], $
              [000B, 000B],  [000B, 000B], $
              [000B, 000B],  [000B, 000B], $
              [000B, 000B],  [000B, 000B], $
              [000B, 000B],  [000B, 000B], $
              [000B, 000B],  [000B, 000B]  $
            ]

; create the main base widget

mainBase = WIDGET_BASE(parent, $
    EVENT_FUNC = 'ctrl_lr_eh', SPACE = 10, _EXTRA = extra)

; if the user passes in the value keyword then use to set up a label
; for control pad. The positioning of the label will be determined
; by the type alignment of the control pad. If the /ROW is passed in,
; the label will be on the left. If /COLUMN, the label will be
; on the right of the control pad

if (keyword_set(VALUE)) then begin
    padLabel = WIDGET_LABEL(mainBase, VALUE = value)
endif

; allow the user to draw a frame around the control pad with the /PAD_FRAME
; keyword. This frame will be around the control pad only, not the label. If
; a frame around the label and control pad is desired, the /FRAME keyword
; should be used.

if (keyword_set(PAD_FRAME)) then begin
   ctrlPadBase = WIDGET_BASE(mainBase, /COLUMN, SPACE = 0, YPAD = 4, $
   /BASE_ALIGN_CENTER, /ALIGN_CENTER, /FRAME)
endif else begin
   ctrlPadBase = WIDGET_BASE(mainBase, /COLUMN, SPACE = 0, YPAD = 1, $
   /BASE_ALIGN_CENTER, /ALIGN_CENTER)
endelse

; set up the actual buttons that make up the control pad. Three row bases
; each with three tightly packed buttons

; East-West Base - hold the East-West and reset buttons

ctrlEWBase = WIDGET_BASE(ctrlPadBase, /ROW, SPACE = 0, YPAD = 1, $
                         /BASE_ALIGN_CENTER)
westBut = WIDGET_BUTTON(ctrlEWBase, /ALIGN_LEFT, $
                        VALUE = westBM, UVALUE = 'toLeft')
resetBut = WIDGET_BUTTON(ctrlEWBase, /ALIGN_CENTER, $
                         VALUE = blankBM, UVALUE = 'toMiddle' )
Widget_Control, resetBut,  SENSITIVE = 0
eastBut = WIDGET_BUTTON(ctrlEWBase, /ALIGN_RIGHT, $
                        VALUE = eastBM, UVALUE = 'toRight')


return, ctrlPadBase
end



