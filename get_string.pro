function get_string, prompt, value

;+
; NAME:
;       GET_STRING.PRO
; PURPOSE:
;       To input a character string with prompting, a default value,
;       and error handling.
; CALLING SEQUENCE:
;       result = GET_STRING(prompt, default)
; INPUTS:
;   PROMPT
;       A prompt string, typically informing the user what value is required.
;   DEFAULT
;       The default value of the string to be input. If the user just types
;       <RETURN> then this value will be returned.
; OPTIONAL INPUT PARAMETERS:
;       None
; KEYWORD PARAMETERS:
;       None
; OUTPUTS:
;   RESULT
;       The function returns the character string which the user entered,
;       or the default string if the user did not enter one.
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
;       input string in square brackets. Reads an input string from the user. 
;       If the input string is null then the default string is returned.
;       If an I/O error occurs the the user is prompted again.
; MODIFICATION HISTORY:
;       Created November, 1990 by Mark Rivers
;       Added error checking October 23, 1991 - Mark Rivers
;       Made input on a new line if the default string is >20 characters
;-

on_ioerror, try_again
try_again:
if strlen(value) le 20 then begin
  print, prompt+' ['+value+']', format="(a,$)"
endif else begin
  print, prompt+' ['+value+']', format="(a)"
endelse
string = ''
read, format='(q,a)', nc, string
if nc gt 0 then begin
  return, string
endif else begin
  return, value
endelse
end

