function dxtime
; return current time offset by a constant
return, (double(systime(1))  - 1.e9)
end
