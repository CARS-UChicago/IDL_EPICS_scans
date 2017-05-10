function profile_move, profile, positions, groupName=groupName, useAxes=useAxes, $
                       maxAxes=maxAxes, time=time, acceleration=acceleration, npulses=npulses, $
                       pulseRange=pulseRange, build=build, execute=execute, readback=readback, $
                       actual=actual, errors=errors

;+
; NAME:
;   profile_move
;
; PURPOSE:
;     This IDL function loads and execute a profile move
;     using the EPICS asyn motor driver and its profile move functions.
;
;
; CATEGORY:
;     EPICS profile moves
;
; CALLING SEQUENCE:
;     Result = PROFILE_MOVE(Profile, Positions)
;
; INPUTS:
;     PROFILE: The EPICS record name for thisprofile, for example '13BMC:Prof1:'.
;
;     POSITIONS: [NPOINTS, NMOTORS]. The positions of the motors at each point in the profile move
;
;
; KEYWORD PARAMETERS:
;     GROUPNAME:    If this keyword is specified it controls the group name of the XPS profile
;     USEAXES:    An with list of axes to move
;     TIME:     If this keyword is a scaler, then it specifies the fixed time per point
;               in the profile.  If it is an array then it specifies the time per point.
;               Default=1 second per point.
;     ACCELERATION:    The acceleration time for the profile.  Default=1 second.
;     NPULSES:  The number of output pulses during the profile.  Default=NPOINTS, the number
;               of points in the input Positions array.
;     PULSERANGE:  The range of points over which to output pulses.  Default=[1,NPOINTS]
;     BUILD:    Set this keyword to build and verify the profile.  This is the default.
;
;     EXECUTE:  Set this keyword to execute the profile.  This is the default.
;
;     READBACK: Set this keyword to read back the profile into ACTUAL and ERROR.
;               The default is to not read back.
;
;     NOTE: Any or all of these keywords can be set.  If none is set then the
;         function does not do anything.
;
; OUTPUTS:
;       Result:     This function returns a status indicating whether the
;                   selected operations were successful or not. 0=success,
;                   anything else is a failure.
;       ACTUAL:     An array of [Nactual, NMOTORS] containing the actual positions of
;                   each axis.
;       ERRORS:     An array of [Nactual, NMOTORS] containing the following errors of
;                   each axis.
;       NOTE: The ACTUAL and ERROR outputs are only returned if the READBACK keyword it set.
;
; SIDE EFFECTS:
;       This procedure can move the motors.  Be careful!
;
; EXAMPLE:
;       positions = [[1,2,3],[.1, .2, .3], [0,3,4]]
;       status = PROFILE_MOVE('13IDC:Prof1:', positions, /readback, actual, errors)
;       plot, actual[*,0]
;       oplot, errors[*,0]
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, April 5, 2011
;-

    if (n_elements(build) eq 0) then build=1
    if (n_elements(execute) eq 0) then execute=1
    if (n_elements(maxAxes) eq 0) then maxAxes=8
    if (n_elements(groupName) ne 0) then t = caput(profile+'GroupName', groupName, /wait)

    if (keyword_set(build)) then begin

        dims = size(positions, /dimensions)
        npoints = dims[0]
        if (n_elements(dims) eq 1) then naxes=1 else naxes=dims[1]
        if (n_elements(useAxes) eq 0) then useAxes = indgen(naxes)
        dims = size(useAxes, /dimensions)
        if (dims[0] ne naxes) then begin
            print, 'Error, useAxes must have ', naxes, ' elements'
            return, -1
        endif
        if (n_elements(npulses) eq 0) then npulses = npoints
        if (n_elements(pulseRange) eq 0) then pulseRange=[1,npoints-1]

        t = caput(profile+'NumPoints', npoints, /wait)
        t = caput(profile+'NumPulses', npulses, /wait)
        t = caput(profile+'StartPulses', pulseRange[0], /wait)
        t = caput(profile+'EndPulses',   pulseRange[1], /wait)

        ; Default is 1 second per element
        if (n_elements(time) eq 0) then time = npoints * 1.0
        if (n_elements(time) eq 1) then begin
            t = caput(profile+'TimeMode', 'Fixed', /wait)
            t = caput(profile+'FixedTime', time, /wait)
        endif else begin
            t = caput(profile+'TimeMode', 'Array', /wait)
            t = caput(profile+'Times', time, /wait)
        endelse

        if (n_elements(acceleration) eq 0) then accel = 1.
        t = caput(profile+'Acceleration', acceleration, /wait)

        for i=0, maxAxes-1 do begin
            axis = profile + 'M' + strtrim(i+1,2)
            t = caput(axis+'UseAxis', 0, /wait)
        endfor
        
        for i=0, naxes-1 do begin
            j = useAxes[i]
            axis = profile + 'M' + strtrim(j+1,2)
            t = caput(axis+'UseAxis', 1, /wait)
            pos = positions[*,i]
            t = caput(axis+'Positions', pos, /wait)
        endfor

        ; Profile is now defined.  Build it.
        t = caput(profile+'Build', 1)
        ; Wait for the build to complete. Wait 0.1 second between polls.
        repeat begin
            wait, 0.1
            t = caget(profile+'Build', busy)
        endrep until (busy eq 0)

        ; Make sure the build was successful
        t = caget(profile+'BuildStatus', BuildStatus, /string)
        if (BuildStatus ne 'Success') then begin
            t = caget(profile+'BuildMessage', BuildMessage)
            BuildMessage = string(BuildMessage)
            print, 'Build failed, error = ', BuildMessage
            return, BuildStatus
        endif
    endif

    if (keyword_set(execute)) then begin
        t = caput(profile+'Execute', 1)
        ; Wait for the execute to complete. Wait 0.1 second between polls.
        repeat begin
            wait, 0.1
            t = caget(profile+'Execute', busy)
        endrep until (busy eq 0)

        ; Make sure the execution was successful
        t = caget(profile+'ExecuteStatus', ExecuteStatus, /string)
        if (ExecuteStatus ne 'Success') then begin
            t = caget(profile+'ExecuteMessage', ExecuteMessage)
            ExecuteMessage = string(ExecuteMessage)
            print, 'Execution failed, error = ', ExecuteMessage
            return, ExecuteStatus
        endif
    endif

    if (keyword_set(readback)) then begin
        t = caput(profile+'Readback', 1)
        ; Wait for the readback to complete. Wait 0.1 second between polls.
        repeat begin
            wait, 0.1
            t = caget(profile+'Readback', busy)
        endrep until (busy eq 0)

        ; Make sure the readback was successful
        t = caget(profile+'ReadbackStatus', ReadbackStatus, /string)
        if (ReadbackStatus ne 'Success') then begin
            t = caget(profile+'ReadbackMessage', ReadbackMessage)
            ReadbackMessage = string(ReadbackMessage)
            print, 'Read failed, error = ', ReadbackMessage
            return, ReadbackStatus
        endif

        ; Read the actual and error arrays into IDL, return to
        ; caller
        t = caget(profile+'NumActualPulses', nreadback)
        actual = dblarr(nreadback, naxes)
        errors = dblarr(nreadback, naxes)
        for i=0, naxes-1 do begin
            j = useAxes[i]
            axis = profile + 'M' + strtrim(j+1,2)
            t = caget(axis+'Readbacks', temp, max=nreadback)
            actual[0,i] = temp
            t = caget(axis+'FollowingErrors', temp, max=nreadback)
            errors[0,i] = temp
        endfor
    endif

    return, 0
end

