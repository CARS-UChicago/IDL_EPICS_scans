function get_choice, prompt, choices, current

;+
; NAME:
;       GET_CHOICE.PRO
; PURPOSE:
;       To input a character string from a list of possible choices
;       with prompting, a default value, and error handling.
; CALLING SEQUENCE:
;       selection = GET_CHOICE(prompt, choices, default)
; INPUTS:
;   PROMPT
;       A prompt string, typically informing the user what value is required.
;   CHOICES
;       A character array, containing the list of possible choices for the user
;       to select from
;   DEFAULT
;       The default choice. The is a number from 0 to n_elements(CHOICES)-1,
;       i.e. it is the index in the CHOICES array of the default choice.
;       If the user only types <RETURN> then this value will be returned.
; OPTIONAL INPUT PARAMETERS:
;       None
; KEYWORD PARAMETERS:
;       None
; OUTPUTS:
;   SELECTION
;       The function returns the index number of the selected choice in the 
;       CHOICES array, or the the default choice if the user did not enter 
;       a choice.
; OPTIONAL OUTPUT PARAMETERS:
;       None
; COMMON BLOCKS:
;       None
; SIDE EFFECTS:
;       None
; RESTRICTIONS:
;       The procedure does not detect ambiguous responses. For example, 
;       if CHOICES=["ORANGE", "APPLE", "ASPARAGUS"] and the user types
;       "A" then APPLE will be selected and GET_CHOICE will return 1.
; PROCEDURE:
;       Prints out the prompt string followed by the default choice
;       in square brackets. Reads an input string from the user. If the
;       input string is null then the default choice index is returned. 
;       If the string is not null it is checked to see if it matches one of the
;       choices. The matching is case insensitive and only checks up to the
;       number of characters which the user typed, so abbreviation is allowed.
;       If a match is found the index number of that choice is returned. 
;       If the input is not a valid choice the list of valid choices is 
;       printed and the user is prompted again.
; MODIFICATION HISTORY:
;       Created November, 1990 by Mark Rivers
;       Added error checking October 23, 1991 - Mark Rivers
;-

on_ioerror, try_again
try_again:
print, prompt+' ['+choices(current)+']', format="(a,$)"
string = ' '
read, format='(q,a)', nc, string
if nc eq 0 then return, current
; The user entered a value, see if it is a valid option
n_choice = n_elements(choices)
for i=0, n_choice-1 do begin
  if (strupcase(string) eq strupcase(strmid(choices(i),0,nc))) then return, i
endfor
print, 'Valid choices are:'
for i=0, n_choice-1 do print, choices(i)
goto, try_again
end


