; Procedure to test the scaler object

pro test_ scaler2, scaler=scaler, dwell_time=dwell_time, $
                  first_channel=first_channel, last_channel=last_channel

  if (n_elements(scaler) eq 0) then scaler = '13LAB:scaler1'
  scaler = obj_new('epics_scaler', scaler)
  if (n_elements(dwell_time) eq 0) then dwell_time = 0.1
  if (n_elements(first_channel) eq 0) then first_channel = 0
  if (n_elements(last_channel) eq 0) then last_channel = 7

  while (1) do begin

    scaler->start, dwell_time

    ; Wait for scaler to start then to complete.
    scaler->wait, /start, /stop

    ; Save scaler counts
    counts = scaler->read()
    ; The counter in scaler 3 and 4 should be the same
    if (counts[first_channel] ne counts[last_channel]) then begin
      print, 'Error first channel = ' + strtrim(counts[first_channel],2) + $
            ' last_channel = ' + strtrim(counts[last_channel],2)
    endif
  endwhile
end
