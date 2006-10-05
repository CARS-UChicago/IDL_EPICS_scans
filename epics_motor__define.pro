;*****************************************************************************
function epics_motor::get_scale
;+
; NAME:
;       EPICS_MOTOR::GET_SCALE
;
; PURPOSE:
;       This function returns the scale factor for the motor.  The scale
;       factor is the number of steps per unit motion in the user coordinate
;       system.  It is 1/.MRES, where .MRES is the motor resolution field of
;       the EPICS motor record.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       Result = motor->GET_SCALE()
;
; INPUTS:
;       None:
;
; OUTPUTS:
;       This function returns the scale factor for the motor.
;
; EXAMPLE:
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos')
;       scale = motor->GET_SCALE()
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;-
t = caget(self.record_name + '.MRES', resolution)
return, 1./resolution
end


;*****************************************************************************
function epics_motor::get_name
;+
; NAME:
;       EPICS_MOTOR::GET_NAME
;
; PURPOSE:
;       This function returns the EPICS record name for the motor.  The record
;       name does not include any trailing period or field name.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       Result = motor->GET_NAME()
;
; INPUTS:
;       None:
;
; OUTPUTS:
;       This function returns the name of the motor.
;
; EXAMPLE:
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos.DESC')
;       print, motor->GET_NAME()
;       13IDA_Slit1_Pos
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;-
return, self.record_name
end


;*****************************************************************************
function epics_motor::get_description
;+
; NAME:
;       EPICS_MOTOR::GET_DESCRIPTION
;
; PURPOSE:
;       This function returns the .DESC field of the EPICS motor record. This
;       is typically a short description of the function of the motor.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       Result = motor->GET_DESCRIPTION()
;
; INPUTS:
;       None:
;
; OUTPUTS:
;       This function returns the description of the motor.
;
; EXAMPLE:
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos')
;       print, motor->GET_DESCRIPTION()
;       Horizontal slit position
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;-
t = caget(self.record_name + '.DESC', description)
return, description
end


;*****************************************************************************
pro epics_motor::set_description, description
;+
; NAME:
;       EPICS_MOTOR::SET_DESCRIPTION
;
; PURPOSE:
;       This procedure sets the .DESC field of the EPICS motor record. This
;       is typically a short description of the function of the motor.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       motor->SET_DESCRIPTION, Description
;
; INPUTS:
;       Description:  A string which describes the motor
;
; OUTPUTS:
;       None
;
; EXAMPLE:
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos')
;       motor->SET_DESCRIPTION, 'Vertical slit position'
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;-
t = caput(self.record_name + '.DESC', description)
end


;*****************************************************************************
function epics_motor::get_offset
;+
; NAME:
;       EPICS_MOTOR::GET_OFFSET
;
; PURPOSE:
;       This function returns the .OFF field of the EPICS motor record. This
;       is the offset between user and dial coordinates.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       Result = motor->GET_OFFSET()
;
; INPUTS:
;       None:
;
; OUTPUTS:
;       This function returns the offset of the motor.
;
; EXAMPLE:
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos')
;       print, motor->GET_OFFSET()
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, January 7, 2002
;-
t = caget(self.record_name + '.OFF', offset)
return, offset
end


;*****************************************************************************
pro epics_motor::set_offset, offset
;+
; NAME:
;       EPICS_MOTOR::SET_OFFSET
;
; PURPOSE:
;       This function sets the .OFF field of the EPICS motor record. This
;       is the offset between user and dial coordinates.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       motor->SET_OFFSET, offset
;
; INPUTS:
;       offset:  The motor offset
;
; OUTPUTS:
;       None
;
; EXAMPLE:
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos')
;       motor->SET_OFFSET, 1.5
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, January 7, 2002
;-
t = caput(self.record_name + '.OFF', offset)
end


;*****************************************************************************
function epics_motor::get_high_limit, dial=dial
;+
; NAME:
;       EPICS_MOTOR::GET_HIGH_LIMIT
;
; PURPOSE:
;       This function returns the software high limit for the motor.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       Result = motor->GET_HIGH_LIMIT()
;
; INPUTS:
;       None:
;
; KEYWORD PARAMETERS:
;       DIAL:   Set this keyword to return the high limit in dial coordinates.
;               The default is to return the high limit in user coordinates.
;
; OUTPUTS:
;       This function returns the software high limit of the motor.
;
; EXAMPLE:
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos')
;       limit = motor->GET_HIGH_LIMIT()
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;-
if keyword_set(dial) then begin
    t = caget(self.record_name + '.DHLM', high_limit)
endif else begin
    t = caget(self.record_name + '.HLM', high_limit)
endelse
return, high_limit
end


;*****************************************************************************
pro epics_motor::set_high_limit, dial=dial, high_limit
;+
; NAME:
;       EPICS_MOTOR::SET_HIGH_LIMIT
;
; PURPOSE:
;       This procedure sets the software high limit for the motor.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       motor->SET_HIGH_LIMIT, Limit
;
; INPUTS:
;       Limit:  The new software high limit for the motor.
;
; KEYWORD PARAMETERS:
;       DIAL:   Set this keyword to set the high limit in dial coordinates.
;               The default is to set the high limit in user coordinates.
;
; OUTPUTS:
;       None.
;
; EXAMPLE:
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos')
;       motor->SET_HIGH_LIMIT, 50.
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;-
if keyword_set(dial) then begin
    t = caput(self.record_name + '.DHLM', high_limit)
endif else begin
    t = caput(self.record_name + '.HLM', high_limit)
endelse
end


;*****************************************************************************
function epics_motor::get_low_limit, dial=dial
;+
; NAME:
;       EPICS_MOTOR::GET_LOW_LIMIT
;
; PURPOSE:
;       This function returns the software low limit for the motor.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       Result = motor->GET_LOW_LIMIT()
;
; INPUTS:
;       None:
;
; KEYWORD PARAMETERS:
;       DIAL:   Set this keyword to return the low limit in dial coordinates.
;               The default is to return the low limit in user coordinates.
;
; OUTPUTS:
;       This function returns the software low limit of the motor.
;
; EXAMPLE:
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos')
;       limit = motor->GET_LOW_LIMIT()
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;-
if keyword_set(dial) then begin
    t = caget(self.record_name + '.DLLM', low_limit)
endif else begin
    t = caget(self.record_name + '.LLM', low_limit)
endelse
return, low_limit
end


;*****************************************************************************
pro epics_motor::set_low_limit, dial=dial, low_limit
;+
; NAME:
;       EPICS_MOTOR::SET_LOW_LIMIT
;
; PURPOSE:
;       This procedure sets the software low limit for the motor.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       motor->SET_LOW_LIMIT, Limit
;
; INPUTS:
;       Limit:  The new software low limit for the motor.
;
; KEYWORD PARAMETERS:
;       DIAL:   Set this keyword to set the low limit in dial coordinates.
;               The default is to set the low limit in user coordinates.
;
; OUTPUTS:
;       None.
;
; EXAMPLE:
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos')
;       motor->SET_LOW_LIMIT, 50.
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;-
if keyword_set(dial) then begin
    t = caput(self.record_name + '.DLLM', low_limit)
endif else begin
    t = caput(self.record_name + '.LLM', low_limit)
endelse
end


;*****************************************************************************
function epics_motor::get_calibration, status, $
            negative=negative, positive=positive, home=home, $
            offset=offset
;+
; NAME:
;       EPICS_MOTOR::GET_CALIBRATION
;
; PURPOSE:
;       This function returns one of four possible calibration settings
;       for the motor.  The settings are negative limit, positive limit,
;       home, and offset.  The returned value is in dial coordinates.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;       cal = motor->GET_CALIBRATION(Status)
;
; KEYWORD PARAMETERS:
;       NEGATIVE:  Set this keyword to return the calibration value at the
;                  negative limit switch.  This is the default.
;
;       POSITIVE:  Set this keyword to return the calibration value at the
;                  positive limit switch.
;
;       HOME:      Set this keyword to return the calibration value at the
;                  home position.
;
;       OFFSET:    Set this keyword to return the offset (the difference
;                  between the user and dial coordinates)
;
; OUTPUTS:
;       This function returns the requested calibration value in dial
;       coordinates.
;
;       Status:  0 if the calibration information was contained in the file,
;                -1 if it was not.  For HOME and OFFSET Status=-1 is really
;                an error, for NEGATIVE and POSITIVE it is a warning that the
;                DHLM or DLLM values, rather than values from the file are
;                being returned.
;
; PROCEDURE:
;       There are two possible sources of the calibration information.  The
;       first is a file of motor calibrations.  In order to use this file the
;       enivronment variable MOTOR_CALIBRATION must be set to the full path
;       name of this file.  Each line of this file must be of the format:
;       MOTOR_NAME LIMIT POSITION OPTIONAL_COMMENT
;       for example:
;       13IDC:m1 NEGATIVE -5.667  ; Calibrated by MLR 4/5/2000
;       13IDA:m2 HOME 10.500      ; Calibrated by PJE 12/7/1999
;       13IDA:m2 OFFSET -1.5      ; Calibrated by PJE 12/7/1999
;
;       If the appropriate calibration cannot be found in this file then this
;       function returns the following values:
;       NEGATIVE motor.DLLM (Dial low limit)
;       POSITIVE motor.DHLM (Dial high limit)
;       HOME     0.0
;       OFFSET   0.0
;       In all of these cases the Status output will be -1.
;
; EXAMPLE:
;       ; Get the motor calibration value at the positive limit switch
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos')
;       cal = motor->GET_CALIBRATION(/POSITIVE, Status)
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, April 8, 2000
;       7-JAN-2002  MLR  Added OFFSET keyword and Status output
;                       Replaced STR_SEP with STRSPLIT
;-
if keyword_set(positive) then limit='POSITIVE' $
else if keyword_set(home) then limit='HOME' $
else if keyword_set(offset) then limit='OFFSET' $
else limit='NEGATIVE'

file = getenv('MOTOR_CALIBRATION')
if (file eq '') then goto, nofile
on_ioerror, nofile
openr, lun, /get, file
line = ''
while not eof(lun) do begin
    readf, lun, line
    line = strtrim(line,2)
    if ((strlen(line) gt 1) and  $
        (strmid(line,0,1) ne ';') ) then begin
       tokens = strsplit(line, /extract)
       if ((tokens[0] eq self.record_name) and $
           (strupcase(tokens[1]) eq limit)) then begin
           cal = float(tokens[2])
           free_lun, lun
           status = 0
           return, cal
       endif 
    endif
endwhile

nofile:
; Could have been an error reading the file, make sure it is closed
if (n_elements(lun) ne 0) then free_lun, lun
status = -1
if (limit eq 'NEGATIVE') then return, self->get_low_limit(/DIAL)
if (limit eq 'POSITIVE') then return, self->get_high_limit(/DIAL)
; Must be HOME or OFFSET
return, 0.0
end


;*****************************************************************************
pro epics_motor::calibrate, $
            negative=negative, positive=positive, home=home, offset=offset, $
            noconfirm=noconfirm
;+
; NAME:
;       EPICS_MOTOR::CALIBRATE
;
; PURPOSE:
;       This procedure calibrates a motor.  It moves the motor to either the
;       negative limit, positive limit or home position and then sets the dial
;       position to the value returned by <A HREF="#EPICS_MOTOR::GET_CALIBRATION">EPICS_MOTOR::GET_CALIBRATION()</A>.
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;       motor->CALIBRATE
;
; KEYWORD PARAMETERS:
;       NEGATIVE:  Set this keyword to do the calibration at the negative 
;                  limit switch.
;
;       POSITIVE:  Set this keyword to do the calibration at the positive 
;                  limit switch.
;
;       HOME:      Set this keyword to do the calibration at the home position.
;
;       OFFSET:    Set this keyword to calibrate the motor offset
;
;       NOCONFIRM: Set this keyword to suppress the confirmation dialog box
;                  before setting the new dial position.
;
;       Note that only one of (NEGATIVE, POSITIVE or HOME) can be specified, but
;       OFFSET can be used either alone or together with any of the above.
;
; PROCEDURE:
;       This procedure first determines the appropriate calibration value using
;       <A HREF="#EPICS_MOTOR::GET_CALIBRATION">EPICS_MOTOR::GET_CALIBRATION()</A>.
;       It then does the following:
;           - If the calibration is done with /NEGATIVE or /POSITIVE
;               - Saves the motor soft limit
;               - Saves the motor slew speed
;               - Changes the soft limit to a very large value, so that the 
;                 hard limit can be reached.
;               - Hits appropriate limit at the slew speed
;               - Backs off 2000 steps
;               - Hits appropriate limit at slew speed/100
;           - If calibration is done with /HOME
;               - Does a motor home
;           - If the calibration is done with /NEGATIVE, /POSITIVE or /HOME    
;              - Confirms if user wants to change calibration if /NOCONFIRM not 
;                set
;              - Puts motor in SET mode
;              - Sets dial value to calibration 
;              - Puts motor in USE mode
;              - Restores slew speed
;              - Restores soft limit
;           - If /OFFSET is specified
;             Sets offset to the offset calibration
;
; EXAMPLE:
;       ; Get the motor calibration value at the positive limit switch
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos')
;       motor->CALIBRATE(/POSITIVE, /NOCONFIRM)
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, April 8, 2000
;       7-JAN-2000  MLR   Added OFFSET keyword, changed logic so that
;                         user value is not written to.  Changed so NEGATIVE
;                         is no longer a default keyword.
;-
limit = keyword_set(positive) or keyword_set(negative)

if (keyword_set(home) or limit) then begin
    cal = self->get_calibration(negative=negative, positive=positive, home=home, status)
    if (status ne 0) then begin
        response = dialog_message(/question, 'Calibration not in file, continue?')
        if (strupcase(response) eq 'NO') then return
    endif
    if (keyword_set(home)) then begin
        self->go_home, home_direction=home_direction
        self->wait
    endif else begin  ; (positive or negative)
        huge = 1.e9/abs(self->get_scale())
        prev_speed = self->get_slew_speed()
        if (keyword_set(negative)) then begin
            sign = -1.
            prev_limit = self->get_low_limit(/dial)
            self->set_low_limit, -2.*huge, /dial
        endif else begin
            sign = 1.
            prev_limit = self->get_high_limit(/dial)
            self->set_high_limit, 2.*huge, /dial
        endelse
        self->move, sign*huge, /dial, /ignore_limits
        self->wait, /ignore_limits
        target = self->get_position(/dial) -sign*2000./abs(self->get_scale())
        self->move, target, /dial, /ignore_limits
        self->wait, /ignore_limits
        ; There is a bug in the motor record, sometimes need to move twice if we
        ; are at a hard limit
        self->move, target, /dial, /ignore_limits
        self->wait, /ignore_limits
        wait, .2
        self->set_slew_speed, ((prev_speed/100.) > self->get_base_speed())
        wait, .2
        self->move, sign*huge, /dial, /ignore_limits
        self->wait, /ignore_limits
    endelse

    ; Get the current positions
    current_dial = self->get_position(/dial, /readback)
    current_user = self->get_position(/readback)

    if (not keyword_set(NOCONFIRM)) then begin
        response = dialog_message(/question, 'Reset dial value from ' + $
                        strtrim(current_dial,2) + ' to ' + strtrim(cal,2) + '?')
        if (strupcase(response) eq 'NO') then goto, restore_settings
    endif else begin
        print, self.record_name + ': reset dial value from ' + $
                strtrim(current_dial,2) + ' to ' +  strtrim(cal,2)
    endelse

    ; Set the dial position to the calibration value  
    self->set_position, cal, /dial

    restore_settings:
    if (keyword_set(negative)) then begin
        self->set_slew_speed, prev_speed
        self->set_low_limit, prev_limit, /dial
    endif
    if (keyword_set(positive)) then begin
        self->set_slew_speed, prev_speed
        self->set_high_limit, prev_limit, /dial
    endif
endif

if (keyword_set(offset)) then begin
    off = self->get_calibration(/OFFSET, status)
    if (status ne 0) then begin
        response = dialog_message('Offset not defined', /error)
        return
    endif
    if (not keyword_set(NOCONFIRM)) then begin
        response = dialog_message(/question, 'Reset offset to' + strtrim(off,2) + '?')
        if (strupcase(response) eq 'NO') then return
    endif else begin
        print, self.record_name + ': reset offset value to ' + strtrim(off,2)
    endelse

    ; Set the offset to the calibration value  
    self->set_offset, off
endif
end

;*****************************************************************************
function epics_motor::get_slew_speed
;+
; NAME:
;       EPICS_MOTOR::GET_SLEW_SPEED
;
; PURPOSE:
;       This function returns the slew speed for the motor.  The slew speed
;       is the speed which the motor will use after finishing its acceleration.
;       The slew speed is specified in user units per second.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       Result = motor->GET_SLEW_SPEED()
;
; INPUTS:
;       None:
;
; OUTPUTS:
;       This function returns the slew speed for the motor.
;
; EXAMPLE:
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos')
;       speed = motor->GET_SLEW_SPEED()
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;-
t = caget(self.record_name + '.VELO', slew)
return, slew
end


;*****************************************************************************
pro epics_motor::set_slew_speed, slew
;+
; NAME:
;       EPICS_MOTOR::SET_SLEW_SPEED
;
; PURPOSE:
;       This procedure sets the slew speed for the motor.  The slew speed
;       is the speed which the motor will use after finishing its acceleration.
;       The slew speed is specified in user units per second.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       motor->SET_SLEW_SPEED, Slew_speed
;
; INPUTS:
;       Slew_speed:  The desired slew speed in user units per second.
;
; OUTPUTS:
;       None
;
; EXAMPLE:
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos')
;       motor->SET_SLEW_SPEED, .1
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;-
t = caput(self.record_name + '.VELO', slew)
end


;*****************************************************************************
function epics_motor::get_base_speed
;+
; NAME:
;       EPICS_MOTOR::GET_BASE_SPEED
;
; PURPOSE:
;       This function returns the base speed for the motor.  The base speed
;       is the initial speed which the motor will use before starting to
;       accelerate to the slew speed.  The base speed is specified in user
;       units per second.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       Result = motor->GET_BASE_SPEED()
;
; INPUTS:
;       None:
;
; OUTPUTS:
;       This function returns the base speed for the motor.
;
; EXAMPLE:
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos')
;       speed = motor->GET_BASE_SPEED()
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;-
t = caget(self.record_name + '.VBAS', base)
return, base
end


;*****************************************************************************
pro epics_motor::set_base_speed, base
;+
; NAME:
;       EPICS_MOTOR::SET_BASE_SPEED
;
; PURPOSE:
;       This procedure sets the base speed for the motor.  The base speed
;       is the initial speed which the motor will use before starting to
;       accelerate to the slew speed.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       motor->SET_BASE_SPEED, Base_speed
;
; INPUTS:
;       Base_speed:  The desired base speed in user units per second.
;
; OUTPUTS:
;       None
;
; EXAMPLE:
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos')
;       motor->SET_BASE_SPEED, .01
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;-
t = caput(self.record_name + '.VBAS', base)
end


;*****************************************************************************
function epics_motor::get_acceleration
;+
; NAME:
;       EPICS_MOTOR::GET_ACCELERATION
;
; PURPOSE:
;       This function returns the acceleration for the motor.  The acceleration
;       is the time in seconds which the motor takes to go from the base speed
;       to the slew speed.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       Result = motor->GET_ACCELERATION()
;
; INPUTS:
;       None:
;
; OUTPUTS:
;       This function returns the acceleration for the motor.
;
; EXAMPLE:
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos')
;       accel = motor->GET_ACCELERATION()
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;-
t = caget(self.record_name + '.ACCL', accel)
return, accel
end


;*****************************************************************************
pro epics_motor::set_acceleration, accel
;+
; NAME:
;       EPICS_MOTOR::SET_ACCELERATION
;
; PURPOSE:
;       This procedure sets the acceleration for the motor.  The acceleration
;       is the time in seconds which the motor takes to go from the base speed
;       to the slew speed.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       motor->SET_ACCELERATION, Acceleration
;
; INPUTS:
;       Acceleration:  The desired acceleration time in seconds.
;
; OUTPUTS:
;       None
;
; EXAMPLE:
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos')
;       motor->SET_ACCELERATION, .01
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;-
t = caput(self.record_name + '.ACCL', accel)
end


;*****************************************************************************
function epics_motor::get_backlash
;+
; NAME:
;       EPICS_MOTOR::GET_BACKLASH
;
; PURPOSE:
;       This function returns the backlash correction distance for the motor.
;       This distance is specified in user coordinate system units.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       Result = motor->GET_BACKLASH()
;
; INPUTS:
;       None:
;
; OUTPUTS:
;       This function returns the backlash correction distance for the motor.
;
; EXAMPLE:
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos')
;       backlash = motor->GET_BACKLASH()
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;-
t = caget(self.record_name + '.BDST', backlash)
return, backlash
end


;*****************************************************************************
pro epics_motor::set_backlash, backlash
;+
; NAME:
;       EPICS_MOTOR::SET_BACKLASH
;
; PURPOSE:
;       This procedure sets the backlash correction distance for the motor.
;       This distance is specified in user coordinate system units.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       motor->SET_BACKLASH, Backlash
;
; INPUTS:
;       Backlash:  The desired backlash correction distance in user
;                  coordinates.
;
; OUTPUTS:
;       None
;
; EXAMPLE:
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos')
;       motor->SET_BACKLASH, .1
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;-
t = caput(self.record_name + '.BDST', backlash)
end


;*****************************************************************************
pro epics_motor::move, relative=relative, dial=dial, steps=steps, value, $
                       ignore_limits=ignore_limits
;+
; NAME:
;       EPICS_MOTOR::MOVE
;
; PURPOSE:
;       This procedure moves the motor.  The move can be specified in either
;       user coordinates, dial coordinates or steps, and the position can be 
;       specified in either absolute or relative coordinates.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       motor->MOVE, Position
;
; INPUTS:
;       Position:  The desired position to move to.  By default this is
;                  specified as an absolute position in the user coordinate
;                  system.  The /DIAL and /STEPS keywords can be used to
;                  specify positions in dial coordinates or steps.  The
;                  /RELATIVE keyword can be used to specify positions relative
;                  to the current position, rather than absolute positions.
;
; KEYWORD PARAMETERS:
;       DIAL:   Set this keyword to indicate that the position is specified
;               in dial coordinates. The default is to specify the position in
;               user coordinates.
;
;       STEPS:  Set this keyword to indicate that the position is specified
;               in motor steps.  The default is to specify the position in
;               user coordinates.
;
;       RELATIVE:  Set this keyword to indicate that the position is specified
;               relative to the current position.  The default is to specify
;               the absolute position.
;
;       IGNORE_LIMITS:  Set this keyword to prevent error signalling if a limit
;               is hit.
;
; OUTPUTS:
;       None
;
; SIDE EFFECTS:
;       The routine checks whether the move caused soft limit or hard limit
;       errors.  If it did then the routine signals the error with the IDL
;       MESSAGE procedure unless the IGNORE_LIMITS keyword is set.  This will 
;       cause execution to halt within this routine unless an error handler 
;       has been established with the IDL CATCH procedure.
;
; EXAMPLE:
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos')
;       motor->MOVE, 2.             ; Move to absolute position 2. in user
;                                   ; coordinates
;       motor->MOVE, 5., /DIAL      ; Move to absolute position 5. in dial
;                                   ; coordinates
;       motor->MOVE, .1, /RELATIVE  ; Relative move 0.1 unit in user
;                                   ; coordinates
;       motor->MOVE, 1000, /STEP, /RELATIVE  ; Move 1000 steps relative to
;                                            ; current position
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;       08-APR-2000     MLR  Added IGNORE_LIMITS keyword
;-

signal_limits = not keyword_set(ignore_limits)

if (keyword_set(dial)) then begin
    ; Position in dial coordinates
    if (keyword_set(relative)) then begin
        current = self->get_position(/dial)
        t = caput(self.record_name + '.DVAL', current+value)
    endif else begin
        t = caput(self.record_name + '.DVAL', value)
    endelse
endif else if (keyword_set(steps)) then begin
    ; Position in steps
    if (keyword_set(relative)) then begin
        t = caget(self.record_name + '.RVAL', current)
        scale = self->get_scale()
        t = caput(self.record_name + '.RVAL', current + value)
    endif else begin
        t = caput(self.record_name + '.RVAL', value)
    endelse
endif else begin
    ; Position in user coordinates
    if keyword_set(relative) then begin
        t = caput(self.record_name + '.RLV', value)
    endif else begin
        t = caput(self.record_name + '.VAL', value)
    endelse
endelse
; Check for limit violations
t = caget(self.record_name + '.LVIO', limit)
if (signal_limits and (limit ne 0)) then $
        message, 'Soft limit violation on ' + self.record_name
t = caget(self.record_name + '.LLS', limit)
if (signal_limits and (limit ne 0)) then $
        message, 'Low limit switch on ' + self.record_name
t = caget(self.record_name + '.HLS', limit)
if (signal_limits and (limit ne 0)) then $
        message, 'High limit switch on ' + self.record_name
end


;*****************************************************************************
function epics_motor::done, ignore_limits=ignore_limits
;+
; NAME:
;       EPICS_MOTOR::DONE
;
; PURPOSE:
;       This function returns 1 if the motor is done moving and 0 if the motor
;       is still moving.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       Result = motor->DONE()
;
; INPUTS:
;       None
;
; KEYWORD PARAMETERS:
;       IGNORE_LIMITS: Set this keyword to prevent the routine from signalling
;                      an error when a limit is hit.
;
; OUTPUTS:
;       None
;
; SIDE EFFECTS:
;       The routine checks whether the motor stopped due to a soft limit or
;       hard limit error.  If it did then the routine signals the error with
;       the IDL MESSAGE procedure, unless the IGNORE_LIMITS keyowrd is set.
;       This will cause execution to halt within this routine unless an error 
;       handler has been established with the IDL CATCH procedure.
;
; EXAMPLE:
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos')
;       motor->MOVE, .1, /RELATIVE  ; Relative move 0.1 unit
;       if (motor->DONE()) then print, 'Done moving'
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;       08-Apr-2000     MLR  Added IGNORE_LIMITS keyword
;-

signal_limits = not keyword_set(IGNORE_LIMITS)

t = caget(self.record_name + '.DMOV', done)
if (done eq 0) then return, 0  ; Motor not done moving

; Motor done moving, check for limit violations
if (signal_limits) then begin
    t = caget(self.record_name + '.LVIO', limit)
    if (limit ne 0) then message, 'Soft limit violation on ' + $
                                    self.record_name
    t = caget(self.record_name + '.LLS', limit)
    if (limit ne 0) then message, 'Low limit switch on ' + $
                                    self.record_name
    t = caget(self.record_name + '.HLS', limit)
    if (limit ne 0) then message, 'High limit switch on ' + $
                                    self.record_name
endif
return, 1
end


;*****************************************************************************
pro epics_motor::wait, delay, ignore_limits=ignore_limits
;+
; NAME:
;       EPICS_MOTOR::WAIT
;
; PURPOSE:
;       This procedure waits for the motor to finish moving.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;       motor->WAIT
;
; OPTIONAL INPUTS:
;       Delay   The delay time between checking when the motor is done
;               Default is 0.1 second
;
; KEYWORD PARAMETERS:
;       IGNORE_LIMITS: This keyword is passed to EPICS_MOTOR::DONE if present.
;
; OUTPUTS:
;       None
;
; SIDE EFFECTS:
;       This routine calls EPICS_MOTOR::DONE every 0.1 second to check whether
;       the move is complete.  That routine checks whether the move terminated
;       due to soft or hard limit errors. If it did then it signals the
;       error with the IDL MESSAGE procedure.  This will cause execution to
;       halt unless an error handler has been established with the IDL
;       CATCH procedure.
;
; PROCEDURE:
;       Simply polls whether the motor is done moving with the
;       EPICS_MOTOR::DONE function and waits 0.1 second if it is not.
;
; EXAMPLE:
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos')
;       motor->MOVE, .1, /RELATIVE  ; Relative move 0.1 unit
;       motor->WAIT                 ; Wait for it to get there
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;       18-Sep-1998  MLR  Added Delay parameter.  Made it wait one delay period
;                         before checking, because motor moves no longer
;                         use channel access callbacks, so the motor may
;                         not have started to move when this routine is called
;       08-Apr-2000  MLR  Added IGNORE_LIMITS keyword.
;-

if (n_elements(delay) eq 0) then delay=.1
repeat wait, delay until (self->done(ignore_limits=ignore_limits) ne 0)
end


;*****************************************************************************
function epics_motor::get_position, dial=dial, steps=steps, readback=readback
;+
; NAME:
;       EPICS_MOTOR::GET_POSITION
;
; PURPOSE:
;       This function returns the current position of the motor.  It can return
;       the position in user coordinates, dial coordinates or steps.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       Result = motor->GET_POSITION()
;
; INPUTS:
;       None:
;
; KEYWORD PARAMETERS:
;       DIAL:   Set this keyword to return the position in dial coordinates.
;               The default is to return the position in user coordinates.
;       STEPS:  Set this keyword to return the position in steps.
;       READBACK:  Set this keyword to return the readback position (RBV, DRBV
;               or RRBV) rather than the drive position (VAL, DVAL, RVAL)
;
; OUTPUTS:
;       This function returns the current position of the motor.
;
; EXAMPLE:
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos')
;       position = motor->GET_POSITION()
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;-
if (keyword_set(readback)) then begin
    if keyword_set(dial) then begin
        t = caget(self.record_name + '.DRBV', position)
    endif else if keyword_set(steps) then begin
        t = caget(self.record_name + '.RRBV', position)
    endif else begin
        t = caget(self.record_name + '.RBV', position)
    endelse
endif else begin
    if keyword_set(dial) then begin
        t = caget(self.record_name + '.DVAL', position)
    endif else if keyword_set(steps) then begin
        t = caget(self.record_name + '.RVAL', position)
    endif else begin
        t = caget(self.record_name + '.VAL', position)
    endelse
endelse
return, position
end


;*****************************************************************************
pro epics_motor::set_position, position, dial=dial, steps=steps
;+
; NAME:
;       EPICS_MOTOR::SET_POSITION
;
; PURPOSE:
;       This function sets the current position of the motor without moving it.
;       It can set the position in user coordinates, dial coordinates or steps.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;       motor->SET_POSITION, Position
;
; INPUTS:
;       Position:   The new motor position.
;
; KEYWORD PARAMETERS:
;       DIAL:   Set this keyword to set the position in dial coordinates.
;               The default is to set the position in user coordinates.
;       STEPS:  Set this keyword to set the position in steps.
;
; OUTPUTS:
;       None.
;
; EXAMPLE:
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos')
;       motor->SET_POSITION, 0.
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, April 8, 2000
;-

; Put the motor in "SET" mode
t = caput(self.record_name + '.SET', 'Set')

if keyword_set(dial) then begin
    t = caput(self.record_name + '.DVAL', position)
endif else if keyword_set(steps) then begin
    t = caput(self.record_name + '.RVAL', position)
endif else begin
    t = caput(self.record_name + '.VAL', position)
endelse

; Put the motor back in "Use" mode
t = caput(self.record_name + '.SET', 'Use')
end


;*****************************************************************************
function epics_motor::init, record_name
;+
; NAME:
;       EPICS_MOTOR::INIT
;
; PURPOSE:
;       This is the initialization code which is invoked when a new object of
;       type EPICS_MOTOR is created.  It cannot be called directly, but only
;       indirectly by the IDL OBJ_NEW() function.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;       Result = OBJ_NEW('epics_motor', Record_Name)
;
; INPUTS:
;       Record_Name:  The name of the EPICS motor record for the motor object
;                     being created.  This record name can include a field
;                     name which will be stripped off.  For example,
;                     '13IDA:Slit_Pos' and '13IDA:Slit_Pos.DESC' are both
;                     valid.  This makes it convenient when dragging process
;                     variable names from MEDM windows to IDL windows.
;
; OUTPUTS:
;       This function returns a status to indicate whether it was able to
;       establish channel access communication with the specified EPICS motor
;       record.  This status is 1 for success, 0 for failure.  This status is
;       passed back indirectly to the routine which calls OBJ_NEW().  OBJ_NEW
;       will return a valid object pointer if this routine succeeds, and will
;       return a NULL object pointer if this routine fails.  The user should
;       test the return value of OBJ_NEW() with the IDL function OBJ_VALID().
;
; SIDE EFFECTS:
;       The routine establishes channel access monitors on all of the fields
;       in the motor record which the methods in this class will read.  This
;       greatly improves the speed and efficiency.
;
; RESTRICTIONS:
;       This routine cannot be called directly.  It is called indirectly when
;       creating a new object of class EPICS_MOTOR by the IDL OBJ_NEW()
;       function.
;
; EXAMPLE:
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos')
;       if (OBJ_VALID(motor)) then print, 'It worked!'
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;-
    parse_record_name, record_name, rec
    self.record_name = rec
    status = caget( self.record_name, temp)  ; see if it exists
    if status ne 0 then return, 0   ; it does not exist

    ; Set channel access monitors on all fields we will be reading
    caStartGroup
    t = casetmonitor(self.record_name + '.VAL')
    t = casetmonitor(self.record_name + '.DVAL')
    t = casetmonitor(self.record_name + '.RVAL')
    t = casetmonitor(self.record_name + '.DMOV')
    t = casetmonitor(self.record_name + '.MRES')
    t = casetmonitor(self.record_name + '.HLM')
    t = casetmonitor(self.record_name + '.DHLM')
    t = casetmonitor(self.record_name + '.LLM')
    t = casetmonitor(self.record_name + '.DLLM')
    t = casetmonitor(self.record_name + '.BDST')
    t = casetmonitor(self.record_name + '.VELO')
    t = casetmonitor(self.record_name + '.VBAS')
    t = casetmonitor(self.record_name + '.ACCL')
    t = casetmonitor(self.record_name + '.DESC')
    t = casetmonitor(self.record_name + '.LVIO')
    t = casetmonitor(self.record_name + '.LLS')
    t = casetmonitor(self.record_name + '.HLS')
    t = caEndGroup()
    return, 1
end

;*****************************************************************************
pro epics_motor__define
;+
; NAME:
;       EPICS_MOTOR__DEFINE
;
; PURPOSE:
;       This is the definition code which is invoked when a new object of
;       type EPICS_MOTOR is created.  It cannot be called directly, but only
;       indirectly by the IDL OBJ_NEW() function,
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;       Result = OBJ_NEW('epics_motor', Record_Name)
;
; INPUTS:
;       Record_Name:  The name of the EPICS motor record for the motor object
;                     being created.  This record name can include a field
;                     name which will be stripped off.  For example,
;                     '13IDA:Slit_Pos' and '13IDA:Slit_Pos.DESC' are both
;                     valid.  This makes it convenient when dragging process
;                     variable names from MEDM windows to IDL windows.  This
;                     name is passed to EPICS_MOTOR::INIT().
;
; OUTPUTS:
;       None (but see EPICS_MOTOR::INIT)
;
; RESTRICTIONS:
;       This routine cannot be called directly.  It is called indirectly when
;       creating a new object of class EPICS_MOTOR by the IDL OBJ_NEW()
;       function.
;
; EXAMPLE:
;       motor = obj_new('epics_motor', '13IDA:Slit1_Pos')
;       if (OBJ_VALID(motor)) then print, 'It worked!'
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;-
    epics_motor = { epics_motor, record_name: ''}
end
