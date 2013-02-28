;*****************************************************************************
pro epics_scaler::wait, start=start, stop=stop
;+
; NAME:
;       EPICS_SCALER::WAIT
;
; PURPOSE:
;       This function waits for counting on the scaler to complete.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       scaler->WAIT
;
; INPUTS:
;       None
;
; KEYWORD_PARAMETERS:
;       START:
;           Set this flag to wait for counting to start.
;       STOP:
;           Set this flag to wait for counting to stop.  This is the default.
;
;       If both the START and STOP keywords are given then the routine will wait
;       first for acquisition to start and then for acquistion to stop.  If only
;       /START is given then it will not wait for acquisition to stop.
;
; OUTPUTS:
;       None
;
; PROCEDURE:
;	This routine simply tests whether the scaler is done counting. If
;       it is then the routine returns.  If it is not it waits for 1% of the
;       counting time or 0.1 second (whichever is less) and tries again.
;
; EXAMPLE:
;       scaler = obj_new('epics_scaler', '13IDC:scaler1')
;       scaler->start, 10.  ; Start counting for 10 seconds.
;       scaler->wait        ; Wait for counting to complete
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;       4-Mar-2002  MLR Added START and STOP keywords.  Previously it would
;                       only wait for stop.  Eliminated unused "dwell_time" input.
;                       Changed logic to eliminate initial wait if already done.
;                       Changed dwell from 10% to 1% of counting time
;-

t = caget(self.record_name + '.TP', preset)  ; Preset time

if ((n_elements(start) eq 0) and (n_elements(stop) eq 0)) then stop=1
dwell_time = (preset/100.) < 0.1 ; Wait for 1% of count time or 0.1 second,
                                   ; whichever is less
cnt = self.record_name + '.CNT'
val = self.record_name + '.VAL'
; Clear both monitors
t = caget(cnt, busy)
t = caget(val, time)

; If /START was specified than wait until we receive a monitor
if (keyword_set(start)) then begin
   while(1) do begin
      t = cacheckmonitor(cnt)
      if (t eq 1) then goto, transition1
      wait, dwell_time
   endwhile
endif

transition1:
; If /STOP was specified wait for a monitor on VAL.
if (keyword_set(stop)) then begin
    while (1) do begin
        t = cacheckmonitor(val)
        if (t eq 1) then goto, done
        wait, dwell_time
    endwhile
endif

done:
end


;*****************************************************************************
function epics_scaler::read, scaler
;+
; NAME:
;       EPICS_SCALER::READ
;
; PURPOSE:
;       This function returns the counts on the scaler.  It can either return
;       the counts on a single scaler channel or on all of the scaler channels.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       Result = scaler->READ(Channel)
;
; OPTIONAL INPUTS:
;       Channel:  If a channel is specified then only the counts on this
;                 scaler channel are returned.  By default the counts on all
;                 scaler channels are returned.  On the Joerger scaler this is
;                 either 8 or 16 channels, depending upon the model.
;
; OUTPUTS:
;       Returns the counts.  This can be a single number if the optional
;       Channel input was specified, or an array of counts if Channel was not
;       specified.
;
; EXAMPLE:
;       scaler = obj_new('epics_scaler', '13IDC:scaler1')
;       scaler->START, 10.          ; Start counting for 10 seconds.
;       scaler->WAIT                ; Wait for counting to complete
;       counts = scaler->READ()     ; Read the counts on all of the channels
;       counts = scaler->READ(0)    ; Read the counts on the first channel,
;                                   ; which is the preset clock.
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;-
; This function reads the counts on one of the scalers or all of them
if (n_elements(scaler) ne 0) then begin
    field = '.S' + strtrim(scaler+1,2)
    t = caget(self.record_name + field, counts)
endif else begin
    counts = lonarr(self.nchans)
    for i=1,self.nchans do begin
        field = '.S' + strtrim(i,2)
        t = caget(self.record_name + field, temp)
        counts[i-1]=temp
    endfor
endelse
return, counts
end

;*****************************************************************************
pro epics_scaler::start, dwell_time
;+
; NAME:
;       EPICS_SCALER::START
;
; PURPOSE:
;       This function starts the scaler counting.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       scaler->START, Time
;
; OPTIONAL INPUTS:
;       Time:  The preset counting time in seconds.  If this input parameter
;              is not specified then the preset time of the scaler is not
;              changed.
;
; OUTPUTS:
;       None
;
; SIDE EFFECTS:
;       Before starting the scaler the counts on all of the channels are set
;       to 0.  This is how the Joerger scaler works.
;
; RESTRICTIONS:
;       This routine assumes that the first channel of the scaler is used for
;       for a clock.  It thus assumes that there is a wire from the clock
;       output of the module to the first input channel.  It assumes that this
;       channel has been configured to gate (perhaps EPICS_SCALER::INIT
;       should do this?)
;       This routine reads but does not alter the clock frequency.  It assumes
;       that the scaler has been set up with a reasonable clock frequency, i.e.
;       one which is faster than the preset time!
;
; EXAMPLE:
;       scaler = obj_new('epics_scaler', '13IDC:scaler1')
;       scaler->START, 10.          ; Start counting for 10 seconds.
;       scaler->WAIT                ; Wait for counting to complete
;       counts = scaler->READ()     ; Read the counts on all of the channels
;                                   ; which is the preset clock.
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;       18-SEP-1998 MLR  Added /WAIT to caput calls, since this is not the
;                        default in ezcaIDL any more, and it is required
;                        for the scaler wait to work correctly.
;       05-MAR-2001 MLR  Removed /WAIT to caput call when actually starting the
;                        scaler, or else it waits for the scaler to complete. This
;                        is because the scaler record does not fire its forward link
;                        now until the count is complete.
;-

if (n_elements(dwell_time) ne 0) then begin
    t = caput(self.record_name +'.CNT', 0, /WAIT)            ; Stop counting
    t = caput(self.record_name +'.CONT', 0, /WAIT)           ; Oneshot
    t = caput(self.record_name +'.TP', dwell_time, /WAIT) ; Preset time
    t = caput(self.record_name +'.CNT', 1)            ; Start counting
endif else begin
    t = caput(self.record_name +'.CNT', 0, /WAIT)      ; Stop counting
    t = caput(self.record_name +'.CNT', 1)      ; Start counting
endelse
end


;*****************************************************************************
pro epics_scaler::scaler_stop

;+
; NAME:
;       EPICS_SCALER::SCALER_STOP
;
; PURPOSE:
;       This function stops the scaler immediately from counting.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       scaler->SCALER_STOP
;
; INPUTS:
;       None
;
; OUTPUTS:
;       None
;
; RESTRICTIONS:
;       This routine should really be named EPICS_SCALER::STOP.  However, there
;       is a bug in IDL 5.0 such that class procedures can have name conflicts
;       with IDL procedures of the same name.  This is the case with the IDL
;       STOP procedure.  This routine may be renamed if this problem is fixed.
;
; EXAMPLE:
;       scaler = obj_new('epics_scaler', '13IDC:scaler1')
;       scaler->START               ; Start counting
;       scaler->STOP                ; Stop immediately
;       counts = scaler->READ()     ; Read the counts on all of the channels
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;       18-SEP-1998 MLR  Added /WAIT to caput call, since this is not the
;                        default in ezcaIDL any more, and it is required
;                        for the scaler wait to work correctly.
;-

; This immediately stops scaler
t = caput(self.record_name +'.CNT', 0, /WAIT) ; Stop counting
end



;*****************************************************************************
function epics_scaler::get_title, channel
;+
; NAME:
;       EPICS_SCALER::GET_TITLE
;
; PURPOSE:
;       This function returns the .NMx field of the EPICS scaler record. This
;       is typically a short description of the scaler input.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       Result = scaler->GET_TITLE(Channel)
;
; INPUTS:
;       None:
;
; OPTIONAL INPUTS:
;       Channel:  If a channel is specified then only the title of this
;                 scaler channel is returned.  By default the titles of all
;                 scaler channels are returned.  On the Joerger scaler this is
;                 either 8 or 16 channels, depending upon the model.
;
; OUTPUTS:
;       This function returns the titles of the scaler channels.
;
; EXAMPLE:
;       scaler = obj_new('epics_scaler', '13IDC:scaler1')
;       print, scaler->get_title(1)
;       Photodiode
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;-
if (n_elements(channel) ne 0) then begin
    field = '.NM' + strtrim(channel+1,2)
    t = caget(self.record_name + field, title)
endif else begin
    title = strarr(self.nchans)
    for i=1,self.nchans do begin
        field = '.NM' + strtrim(i,2)
        temp = 'Unknown'
        t = caget(self.record_name + field, temp)
        title[i-1]=temp
    endfor
endelse
return, title
end

;*****************************************************************************
pro epics_scaler::set_title, channel, title
;+
; NAME:
;       EPICS_SCALER::SET_TITLE
;
; PURPOSE:
;       This procedure sets the .NMx field of the EPICS scaler record. This
;       is typically a short description of the scaler input.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;
;       scaler->SET_TITLE, Channel, Title
;
; INPUTS:
;       Channel:  The scaler channel whose title is to be set.  This is a
;                 number in the range 0-7 or 0-15 depending upon the model.
;       Title:    The title string.
;
; OUTPUTS:
;       None
;
; EXAMPLE:
;       scaler = obj_new('epics_scaler', '13IDC:scaler1')
;       scaler->set_title, 1, 'Photodiode'
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;-
field = '.NM' + strtrim(channel+1,2)
t = caput(self.record_name + field, title)
end


;*****************************************************************************
function epics_scaler::init, record_name
;+
; NAME:
;       EPICS_SCALER::INIT
;
; PURPOSE:
;       This is the initialization code which is invoked when a new object of
;       type EPICS_SCALER is created.  It cannot be called directly, but only
;       indirectly by the IDL OBJ_NEW() function.
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;       Result = OBJ_NEW('epics_scaler', Record_Name)
;
; INPUTS:
;       Record_Name:  The name of the EPICS scaler record for the scaler object
;                     being created.  This record name can include a field
;                     name which will be stripped off.  For example,
;                     '13IDC:scaler1' and '13IDC:scaler1.S2' are both
;                     valid.  This makes it convenient when dragging process
;                     variable names from MEDM windows to IDL windows.
;
; OUTPUTS:
;       This function returns a status to indicate whether it was able to
;       establish channel access communication with the specified EPICS scaler
;       record.  This status is 1 for success, 0 for failure.  This status is
;       passed back indirectly to the routine which calls OBJ_NEW().  OBJ_NEW
;       will return a valid object pointer if this routine succeeds, and will
;       return a NULL object pointer if this routine fails.  The user should
;       test the return value of OBJ_NEW() with the IDL function OBJ_VALID().
;
; SIDE EFFECTS:
;       The routine establishes channel access monitors on all of the fields
;       in the scaler record which the methods in this class will read.  This
;       greatly improves the speed and efficiency.
;
; RESTRICTIONS:
;       This routine cannot be called directly.  It is called indirectly when
;       creating a new object of class EPICS_SCALER by the IDL OBJ_NEW()
;       function.
;
; EXAMPLE:
;       scaler = obj_new('epics_scaler', '13IDC:scaler1')
;       if (OBJ_VALID(scaler)) then print, 'It worked!'
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;-
    parse_record_name, record_name, record_name
    self.record_name = record_name
    status = caget( self.record_name+'.NCH', nchans)  ; see if it exists
    if status ne 0 then return, 0       ; it does not exist
    self.nchans = nchans
    ; Set channel access monitors on all fields we will be reading
    caStartGroup
    t = casetmonitor(self.record_name + '.TP')
    t = casetmonitor(self.record_name + '.CNT')
    t = casetmonitor(self.record_name + '.VAL')
    for i=1,self.nchans do begin
        num = strtrim(string(i), 2)
        t = casetmonitor(self.record_name + '.PR' + num)
        t = casetmonitor(self.record_name + '.S' + num)
        t = casetmonitor(self.record_name + '.NM' + num)
    endfor
    t = caEndGroup()
    return, 1
end

;*****************************************************************************
pro epics_scaler__define
;+
; NAME:
;       EPICS_SCALER__DEFINE
;
; PURPOSE:
;       This is the definition code which is invoked when a new object of
;       type EPICS_SCALER is created.  It cannot be called directly, but only
;       indirectly by the IDL OBJ_NEW() function,
;
; CATEGORY:
;       EPICS device class library.
;
; CALLING SEQUENCE:
;       Result = OBJ_NEW('epics_scaler', Record_Name)
;
; INPUTS:
;       Record_Name:  The name of the EPICS scaler record for the scaler object
;                     being created.  This record name can include a field
;                     name which will be stripped off.  For example,
;                     '13IDC:scaler1' and '13IDC:scaler1.S2' are both
;                     valid.  This makes it convenient when dragging process
;                     variable names from MEDM windows to IDL windows.  This
;                     name is passed to EPICS_SCALER::INIT().
;
; OUTPUTS:
;       None (but see EPICS_SCALER::INIT)
;
; RESTRICTIONS:
;       This routine cannot be called directly.  It is called indirectly when
;       creating a new object of class EPICS_SCALER by the IDL OBJ_NEW()
;       function.
;
; EXAMPLE:
;       scaler = obj_new('epics_scaler', '13IDC:scaler1')
;       if (OBJ_VALID(scaler)) then print, 'It worked!'
;
; MODIFICATION HISTORY:
;       Written by:     Mark Rivers, October 1, 1997
;-
    epics_scaler = { epics_scaler, record_name: '', nchans: 0}
end
