function trajectory_scan, traj, positions, relative=relative, hybrid=hybrid, $
                          time=time, accel=accel, npulses=npulses, $
                          build=build, execute=execute, read=read, $
                          actual=actual, errors=errors

;+
; NAME:
;   trajectory_scan
;
; PURPOSE:
;     This IDL function loads and execute a complex trajectory
;     using the EPICS trajectory scan databases and SNL programs. The EPICS
;     support current exists for the Newport MM4005 and XPS motor controllers.
;
;
; CATEGORY:
;     EPICS trajectory scanning
;
; CALLING SEQUENCE:
;     Result = TRAJECTORY_SCAN(Trajectory, Positions)
;
; INPUTS:
;     TRAJ: The EPICS record name for this trajectory, for example '13BMC:traj1'.
;
;     POSITIONS: [NELEMENTS, NMOTORS]. The positions of the motors at each element in the trajectory.
;         By default the positions are absolute motor positions.  If the RELATIVE
;         keyword is present then the positions are deltas, i.e. the difference in position
;         from the previous point.
;
;
; KEYWORD PARAMETERS:
;     RELATIVE: Set this keyword if the positions are deltas, i.e. the difference in position
;               from the previous point.  Default mode=ABSOLUTE.
;     HYBRID:   Set this keyword if the trajectory should be executed in "Hybrid" mode, i.e.
;               the positions are absolute rather than deltas, but the trajectory should be
;               executed from the current motor positions without moving to the first point
;               in the postions array.  Default mode=ABSOLUTE.
;     TIME:     If this keyword is a scaler, then it specifies the total time to execute
;               the trajectory.  If it is an array then it specifies the time per element.
;               Default=1 second per element.
;     ACCEL:    The acceleration time for the trajectory.  Only for the MM4005. Default=1 second.
;     NPULSES:  The number of output pulses during the trajectory.  Default=NELEMENTS, the number
;               of points in the input Positions array.
;     BUILD:    Set this keyword to build and verify the trajectory.  This is the default.
;
;     EXECUTE:  Set this keyword to execute the trajectory.  This is the default.
;
;     READ:     Set this keyword to read back the trajectory into ACTUAL and ERROR.
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
;       NOTE: The ACTUAL and ERROR outputs are only returned if the READ keyword it set.
;
; SIDE EFFECTS:
;       This procedure can move the motors.  Be careful!
;
; EXAMPLE:
;       positions = [[1,2,3],[.1, .2, .3], [0,3,4]]
;       status = TRAJECTORY_SCAN('13IDC:traj1', positions, /read, actual, errors)
;       plot, actual[*,0]
;       oplot, errors[*,0]
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, December 15, 2006
;-

    t = caget(traj+'NumAxes', maxAxes)

    MoveMode = 'Absolute'
    if (keyword_set(relative)) then MoveMode = 'Relative'
    if (keyword_set(hybrid)) then MoveMode = 'Hybrid'
    t = caput(traj+'MoveMode', MoveMode)

    if (n_elements(build) eq 0) then build=1
    if (n_elements(execute) eq 0) then execute=1

    if (keyword_set(build)) then begin

        dims = size(positions, /dimensions)
        nelements = dims[0]
        if (n_elements(dims) eq 1) then naxes=1 else naxes=dims[1]
        if (n_elements(npulses) eq 0) then npulses = nelements

        t = caput(traj+'Nelements', nelements)

        t = caput(traj+'Npulses', npulses)

        ; Default is 1 second per element
        if (n_elements(time) eq 0) then time = nelements * 1.0
        if (n_elements(time) eq 1) then begin
            t = caput(traj+'TimeMode', 'Total')
            t = caput(traj+'Time', time)
        endif else begin
            t = caput(traj+'TimeMode', 'Per element')
            t = caput(traj+'TimeTraj', time)
        endelse

        if (n_elements(accel) eq 0) then accel = 1.
        t = caput(traj+'Accel', accel)

        ; The first naxes motors will move.
        for i=0, maxAxes-1 do begin
            axis = traj + 'M' + strtrim(i+1,2)
            if (i lt naxes) then begin
                t = caput(axis+'Move', 1)
                pos = positions[*,i]
                t = caput(axis+'Traj', pos)
            endif else begin
                t = caput(axis+'Move', 0)
            endelse
         endfor

        ; Trajectory is now defined.  Build it.
        t = caput(traj+'Build', 1)
        ; Wait for the build to complete. Wait 0.1 second between polls.
        repeat begin
            wait, 0.1
            t = caget(traj+'Build', busy)
        endrep until (busy eq 0)

        ; Make sure the build was successful
        t = caget(traj+'BuildStatus', BuildStatus, /string)
        if (BuildStatus ne 'Success') then begin
            t = caget(traj+'BuildMessage', BuildMessage)
            print, 'Build failed, error = ', BuildMessage
            return, BuildStatus
        endif
    endif

    if (keyword_set(execute)) then begin
        t = caput(traj+'Execute', 1)
        ; Wait for the execute to complete. Wait 0.1 second between polls.
        repeat begin
            wait, 0.1
            t = caget(traj+'Execute', busy)
        endrep until (busy eq 0)

        ; Make sure the execution was successful
        t = caget(traj+'ExecStatus', ExecStatus, /string)
        if (ExecStatus ne 'Success') then begin
            t = caget(traj+'ExecMessage', ExecMessage)
            print, 'Execution failed, error = ', ExecMessage
            return, ExecStatus
        endif
    endif

    if (keyword_set(read)) then begin
        t = caput(traj+'Readback', 1)
        ; Wait for the readback to complete. Wait 0.1 second between polls.
        repeat begin
            wait, 0.1
            t = caget(traj+'Readback', busy)
        endrep until (busy eq 0)

        ; Make sure the readback was successful
        t = caget(traj+'ReadStatus', ReadStatus, /string)
        if (ReadStatus ne 'Success') then begin
            t = caget(traj+'ReadMessage', ReadMessage)
            print, 'Read failed, error = ', ReadMessage
            return, ReadStatus
        endif

        ; Read the actual and error arrays into IDL, return to
        ; caller
        t = caget(traj+'Nactual', nactual)
        actual = dblarr(nactual, maxAxes)
        errors = dblarr(nactual, maxAxes)
        for i=0, maxAxes-1 do begin
            axis = traj + 'M' + strtrim(i+1,2)
            t = caget(axis+'Actual', temp, max=nactual)
            actual[0,i] = temp
            t = caget(axis+'Error', temp, max=nactual)
            errors[0,i] = temp
        endfor
    endif

    return, 0
end

