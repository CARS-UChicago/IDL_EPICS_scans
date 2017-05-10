; Procedure to test the scaler object

pro test_scaler1, scaler=scaler, dwell_time=dwell_time, n_scalers=n_scalers

  if (n_elements(scaler) eq 0) then scaler = '13LAB:scaler1'
  scaler = obj_new('epics_scaler', scaler)
  if (n_elements(dwell_time) eq 0) then dwell_time = 0.1
  if (n_elements(n_scalers) eq 0) then n_scalers = 8

  while (1) do begin

    scaler->start, dwell_time

    ; Wait for scaler to start then to complete.
    scaler->wait, /start, /stop

    ; Save scaler counts
    counts = scaler->read()
    ; The counter in scaler 0 and 7 should be the same
    if (counts[0] ne counts[n_scalers-1]) then status = 'Error' else status = 'OK'
    print, status + ' Channel 1 = ' + strtrim(counts[0],2) + ' channel' + $
            strtrim(n_scalers,2) + ' = ' + strtrim(counts[n_scalers-1],2)
  endwhile
end
