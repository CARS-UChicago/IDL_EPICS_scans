pro display_point, row, col, rescale=rescale

;+
; NAME:
;       DISPLAY_POINT
; PURPOSE:
;       To display (print and/or plot) data in real-time during a scan. This
;       routine is called after each data point is collected during a scan.
;       A generic version of this routine is provided in 
;       IDL_DIR:[USER.REAL_TIME].
;       Users who want to do more specialized display at each point should
;       simply create another version of DISPLAY_POINT in some other directory 
;       and compile it before calling routine SCAN. More specialized versions 
;       might plot ratios of data values, or display 2-D scans as pseudo-color 
;       images, etc.
; CALLING SEQUENCE:
;       DISPLAY_POINT, row, col
; INPUTS:
;   ROW
;       The current row being collected.
;   COL 
;       The current column being collected.
; OUTPUTS:
;       None
; COMMON BLOCKS:
;       Values in SCAN_COMMON and BSIF_COMMON are used. Specifically:
;       in BSIF_COMMON:
;           N_COLS = number of columns (fast scan direction)
;           N_ROWS = number of rows (slow scan direction, =1 for a 1-D scan)
;           N_DATA = number of data values (scalers, ROIs, etc.) at each point
;           X_DIST(N_COLS) = calibrated units in the fast scan direction
;           Y_DIST(N_ROWS) = calibrated units in the slow scan direction
;               (for 2-D scans only)
;           IMAGE_DATA(N_COLS, N_ROWS, N_DATA) = scan data. 
;       in SCAN_COMMON:
;           SD = structure which contains all the parameters defining the scan.
;           Some useful fields include:
;
; PROCEDURE:
;       The generic version of this routine does the following:
;        - Prints the current column and row, and the
;           counts for each data value at each point
;        - Plots the data according to the values of SD.PLOT. SD.PLOT is an
;           array which lists the indices of all data values which should be
;           plotted by this routine. For example, if SD.PLOT=[0,2,-1,-1,...]
;           then IMAGE_DATA(*,ROW,0) and IMAGE_DATA(*,ROW,2) will be plotted.
;           If all values of SD.PLOT are -1 then no data is plotted.
;           The plots autoscale to the maximum value to be plotted. The first
;           plots uses PSYM=-1, the second PSYM=-2, etc. so both symbols and
;           connecting lines are plotted.
;           The plotting is optimized so that if this point can be plotted
;           without increasing the Y axis range then it uses only OPLOT.
;        - Checks whether the user has typed ^P on the terminal. If so, then
;           this routine stops to let the user print out or plot data. The scan
;           can be aborted at this point by typing RETALL or continued by
;           typing .CON.
;           
; MODIFICATION HISTORY:
;       Created Dec. 1991 by Mark Rivers.
;       Fixed bug in display update algorithm Jan. 9, 1993
;       Added ABORT_SCAN for widget scanning, modified ^P code.
;           Mark Rivers, November 1997
;-

@bsif_common
@scan_common

; Anything to plot?
k = where(sd.plot gt 0, nplot)
if (nplot eq 0) then goto, skip_plot
big = max(image_data(0:col, row, k))
small = min(image_data(0:col, row, k))
if (col eq 0) or (small lt !y.range(0)) or (big gt !y.range(1)) or $
      keyword_set(rescale) then begin
    ; Must rescale plot axes, redraw all data so far
    !y.range = [small - 0.2*abs(small), big + 0.2*abs(big)]
    plot, x_dist, image_data(0:col,row,k(0)), psym=-1, $
        xtitle = x_title, $
        ytitle = y_title, $
        title = image_title
    for i=1, n_elements(k)-1 do begin
        oplot, x_dist, image_data(0:col,row,k(i)), psym=-(i+1)
    endfor
endif else begin
; No need to replot axes. Just draw previous point and current one.
    for i=0, n_elements(k)-1 do begin
        oplot, x_dist(col-1:col), image_data(col-1:col,row,k(i)), psym=-(i+1)
    endfor
endelse

skip_plot:
; Print out counts on terminal
print, 'Column, row = [',col, row,'], total=[',sd.dims(0)-1,sd.dims(1)-1,']',$
        format='(a,i4,i4,a,i4,i4,a)'
if (sd.scan_type eq ROI_SCAN) then begin
  print, 'Rois (net): ', image_data(col, row, 0:sd.n_rois-1), $
          format='(a,10i8)'
  print, 'Scalers:    ', $ 
        image_data(col, row, sd.n_rois:sd.n_rois+sd.n_scalers-1), $
        format='(a, 10i8)'
endif
if (sd.scan_type eq SCALER_SCAN) then begin
  print, 'Scalers:    ', $ 
        image_data(col, row, 0:sd.n_scalers-1), $
        format='(a, 10i8)'
endif
print

; See if the user has typed ^P on the keyboard. If so, pause. Empty typeahead
; buffer checking each character for ^P.
while 1 do begin
  c = get_kbrd(0)
  if c eq '' then goto, done
  if (c eq string(16B)) then begin
    print, "Scanning interrupted by keyboard input"
    print, " To plot data:"
    print, "    PLOT, IMAGE_DATA()"
    print, " To look at numbers:"
    print, "    PRINT, IMAGE_DATA()"
    print, " To abort scan:"
    print, "    ABORT_SCAN"
    print, "    .CON"
    print, " To continue scan"
    print, "    .CON "
    stop
  endif
endwhile

done:
  ; See if an ABORT_SCAN widget event has happened
  if (widget_info(sd.abort_scan_widget, /VALID_ID)) then $
        event = widget_event(/NOWAIT, sd.abort_scan_widget)
end
