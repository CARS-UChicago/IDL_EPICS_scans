function xtime_s
; return current time offset by a constant
x = double(systime(1))  - 9.500e8
; print, 'xtime = ', x
return, x
end

