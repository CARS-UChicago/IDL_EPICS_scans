;+
; NAME:
;       CW_CTRLPAD
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

FUNCTION CTRLPAD_EH, event

; The ID of the control pad is the base that the handler is attached
; to set up a variable to hold this value for use in the return
; structure

base = event.handler

; create the return structure that will pass through as the event
; structure for this compound widget. Start everything off as 0

retstruct = {CW_CTRLPAD_EVENT, ID:base, TOP:event.top, HANDLER:0L, $
			 NORTH:0, SOUTH:0, WEST:0, EAST:0, NEast:0, SEast:0, $
			 NWest:0, SWest:0, Reset:0}

; get the user value of the button that caused the event

WIDGET_CONTROL, event.id, GET_UVALUE = uval

; set the field of the structure corresponding to the button pressed
; to 1. The event structure should have all zeros except the field that
; corresponds to the button that was pressed

case uval of
'moveNW': retstruct.NWest = 1
'moveNorth': retstruct.North = 1
'moveNE': retstruct.NEast = 1
'moveWest': retstruct.West = 1
'moveEast': retstruct.East = 1
'moveSW': retstruct.SWest = 1
'moveSouth': retstruct.South = 1
'moveSE':retstruct.SEast = 1
'moveReset':retstruct.Reset = 1
endcase

return, retstruct
end

FUNCTION CW_CTRLPAD, parent, VALUE = value, PAD_FRAME = pad_frame, $
    _EXTRA = extra

; define the bitmaps for the buttons

southBM = 	[				$
		[192B, 003B],			$
		[192B, 003B],			$
		[192B, 003B],			$
		[192B, 003B],			$
		[192B, 003B],			$
		[192B, 003B],			$
		[193B, 131B],			$
		[195B, 195B],			$
		[199B, 227B],			$
		[207B, 243B],			$
		[222B, 123B],			$
		[252B, 063B],			$
		[248B, 031B],			$
		[240B, 015B],			$
		[224B, 007B],			$
		[192B, 003B]			$
		]

westBM = 	[				$
		[192B, 003B],			$
		[224B, 001B],			$
		[240B, 000B],			$
		[120B, 000B],			$
		[060B, 000B],			$
		[030B, 000B],			$
		[255B, 255B],			$
		[255B, 255B],			$
		[255B, 255B],			$
		[255B, 255B],			$
		[030B, 000B],			$
		[060B, 000B],			$
		[120B, 000B],			$
		[240B, 000B],			$
		[224B, 001B],			$
		[192B, 003B]			$
		]

eastBM = 	[				$
		[192B, 003B],			$
		[128B, 007B],			$
		[000B, 015B],			$
		[000B, 030B],			$
		[000B, 060B],			$
		[000B, 120B],			$
		[255B, 255B],			$
		[255B, 255B],			$
		[255B, 255B],			$
		[255B, 255B],			$
		[000B, 120B],			$
		[000B, 060B],			$
		[000B, 030B],			$
		[000B, 015B],			$
		[128B, 007B],			$
		[192B, 003B]			$
		]

northBM = 	[				$
		[192B, 003B],			$
		[224B, 007B],			$
		[240B, 015B],			$
		[248B, 031B],			$
		[252B, 063B],			$
		[222B, 123B],			$
		[207B, 243B],			$
		[199B, 227B],			$
		[195B, 195B],			$
		[192B, 003B],			$
		[192B, 003B],			$
		[192B, 003B],			$
		[192B, 003B],			$
		[192B, 003B],			$
		[192B, 003B],			$
		[192B, 003B]			$
		]

							;nw bitmap
							;definition
nwBM = 	[				$
		[255B, 000B],			$
		[127B, 000B],			$
		[063B, 000B],			$
		[063B, 000B],			$
		[127B, 000B],			$
		[255B, 000B],			$
		[243B, 001B],			$
		[225B, 003B],			$
		[192B, 007B],			$
		[128B, 015B],			$
		[000B, 031B],			$
		[000B, 062B],			$
		[000B, 124B],			$
		[000B, 248B],			$
		[000B, 240B],			$
		[000B, 224B]			$
		]

							;ne bitmap
							;definition
neBM = 	[				$
		[000B, 255B],			$
		[000B, 254B],			$
		[000B, 248B],			$
		[000B, 252B],			$
		[000B, 254B],			$
		[000B, 223B],			$
		[128B, 207B],			$
		[192B, 135B],			$
		[224B, 003B],			$
		[240B, 001B],			$
		[248B, 000B],			$
		[124B, 000B],			$
		[062B, 000B],			$
		[031B, 000B],			$
		[015B, 000B],			$
		[007B, 000B]			$
		]

							;se bitmap
							;definition
seBM = 	[				$
		[007B, 000B],			$
		[015B, 000B],			$
		[031B, 000B],			$
		[062B, 000B],			$
		[124B, 000B],			$
		[248B, 000B],			$
		[240B, 001B],			$
		[224B, 003B],			$
		[192B, 135B],			$
		[128B, 207B],			$
		[000B, 255B],			$
		[000B, 254B],			$
		[000B, 252B],			$
		[000B, 252B],			$
		[000B, 254B],			$
		[000B, 255B]			$
		]

							;sw bitmap
							;definition
swBM = 	[				$
		[000B, 224B],			$
		[000B, 240B],			$
		[000B, 248B],			$
		[000B, 124B],			$
		[000B, 062B],			$
		[000B, 031B],			$
		[128B, 015B],			$
		[192B, 007B],			$
		[225B, 003B],			$
		[243B, 001B],			$
		[255B, 000B],			$
		[127B, 000B],			$
		[063B, 000B],			$
		[063B, 000B],			$
		[127B, 000B],			$
		[255B, 000B]			$
		]
							;blank bitmap
							;definition
blankBM = 	[				$
		[000B, 000B],			$
		[000B, 000B],			$
		[000B, 000B],			$
		[000B, 000B],			$
		[000B, 000B],			$
		[000B, 000B],			$
		[000B, 000B],			$
		[000B, 000B],			$
		[000B, 000B],			$
		[000B, 000B],			$
		[000B, 000B],			$
		[000B, 000B],			$
		[000B, 000B],			$
		[000B, 000B],			$
		[000B, 000B],			$
		[000B, 000B]			$
		]

; create the main base widget

mainBase = WIDGET_BASE(parent, $
    EVENT_FUNC = 'ctrlpad_eh', SPACE = 10, _EXTRA = extra)

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
   ctrlPadBase = WIDGET_BASE(mainBase, /COLUMN, SPACE = 0, YPAD = 0, $
   /BASE_ALIGN_CENTER, /ALIGN_CENTER, /FRAME)
endif else begin
   ctrlPadBase = WIDGET_BASE(mainBase, /COLUMN, SPACE = 0, YPAD = 0, $
   /BASE_ALIGN_CENTER, /ALIGN_CENTER)
endelse

; set up the actual buttons that make up the control pad. Three row bases
; each with three tightly packed buttons

; North base - hold the three north buttons

 ctrlNorthBase = WIDGET_BASE(ctrlPadBase, /ROW, /BASE_ALIGN_CENTER, $
     SPACE = 0, YPAD = 0)
  nwBut = WIDGET_BUTTON(ctrlNorthBase, /ALIGN_RIGHT, $
     VALUE = nwBM, UVALUE = 'moveNW')
  northBut = WIDGET_BUTTON(ctrlNorthBase, /ALIGN_CENTER, $
     VALUE = northBM, UVALUE = 'moveNorth')
  neBut = WIDGET_BUTTON(ctrlNorthBase, /ALIGN_LEFT, $
     VALUE = neBM, UVALUE = 'moveNE')

; East-West Base - hold the East-West and reset buttons

 ctrlEWBase = WIDGET_BASE(ctrlPadBase, /ROW, SPACE = 0, YPAD = 0, $
     /BASE_ALIGN_CENTER)
  westBut = WIDGET_BUTTON(ctrlEWBase, /ALIGN_LEFT, $
     VALUE = westBM, UVALUE = 'moveWest')
  resetBut = WIDGET_BUTTON(ctrlEWBase, /ALIGN_CENTER, $
     VALUE = blankBM, UVALUE = 'moveReset')
  Widget_Control, resetBut,  SENSITIVE = 0
  eastBut = WIDGET_BUTTON(ctrlEWBase, /ALIGN_RIGHT, $
     VALUE = eastBM, UVALUE = 'moveEast')

; South base - hold the three south buttons

ctrlSouthBase = WIDGET_BASE(ctrlPadBase, /ROW, /BASE_ALIGN_CENTER, $
     SPACE = 0, YPAD = 0)
  swBut = WIDGET_BUTTON(ctrlSouthBase, /ALIGN_RIGHT, $
     VALUE = swBM, UVALUE = 'moveSW')
  southBut = WIDGET_BUTTON(ctrlSouthBase, /ALIGN_CENTER, $
     VALUE = southBM, UVALUE = 'moveSouth')
  seBut = WIDGET_BUTTON(ctrlSouthBase, /ALIGN_LEFT, $
     VALUE = seBM, UVALUE = 'moveSE')

; thats it! return the ID of the control pad base as the
; return value of the funtion and the ID of the
; compound widget

return, ctrlPadBase
end
