function get_int, prompt, value, min = min, max = max

;+
; NAME:
;       GET_INT.PRO
; PURPOSE:
;       To input a short integer value number, with prompting, a default value,
;       optional bounds checking, and error handling.
; CALLING SEQUENCE:
;       result = GET_INT(prompt, default, min = min, max = max)
; INPUTS:
;   PROMPT
;       A prompt string, typically informing the user what value is required.
;   DEFAULT
;       The default value of the number to be input. If the user just types
;       <RETURN> then this value will be returned.
; OPTIONAL INPUT PARAMETERS:
;       None
; KEYWORD PARAMETERS:
;       min and max are the smallest and largest allowed values.  If either
;       keyword is present and the user tries to enter a value outside the
;       range, the default is changed to min or max and the user is presented
;       with the prompt string and new default again.
; OUTPUTS:
;   RESULT
;       The function returns the short integer number which the user entered,
;       or the default value if the user did not enter a value.
; OPTIONAL OUTPUT PARAMETERS:
;       None
; COMMON BLOCKS:
;       None
; SIDE EFFECTS:
;       None
; RESTRICTIONS:
;       None
; PROCEDURE:
;       Prints out the prompt string followed by the default value for the
;       number in square brackets. Reads an input string from the user. If the
;       input string is null then the default value is returned. If the string
;       is not null it is converted to an integer and that is returned. If an
;       invalid number is entered the user is prompted again.
; MODIFICATION HISTORY:
;       Created November, 1990 by Mark Rivers
;       Added error checking October 23, 1991 - Mark Rivers
;       Added min and max check September 4, 1992 - Harvey Rarback
;-

deflt = fix(value)
on_ioerror, try_again
ok = 1
try_again:
if not ok then print, string( 7B)
print, prompt + ' [', deflt, ']', format='(a,i0,a,$)'
ok = 0
string = ' '
read, format='(q,a)', nc, string
if nc gt 0 then begin
  temp = fix(string)
  if n_elements( min) ne 0 then begin
    if temp lt min then begin
      deflt = min
      goto, try_again 
    endif
  endif
  if n_elements( max) ne 0 then begin
    if temp gt max then begin
      deflt = max
      goto, try_again
    endif
  endif
  return, temp
endif else begin
  return, deflt
endelse
end

