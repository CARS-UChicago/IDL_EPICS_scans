; This program builds a profile and executes it.

; 100 elements in the profile.
nelements = 1000

; 101 pulses in the profile. 1 at start and 1 at end
npulses = 101
 
; We will move all 3 motors
naxes=3
        
; Define array of positions
positions = dblarr(nelements, naxes)

; The M1 profile is a sin wave with two complete periods and an
; amplitude of +-10 mm
positions[*,0] = 10.*sin(findgen(nelements)/(nelements-1.)*4.*!pi) + 1
        
; The M2 profile is a sin wave with one complete period and an
; amplitude of +-15 mm
positions[*,1] = 5.*sin(findgen(nelements)/(nelements-1.)*2.*!pi) + 2

; The M3 profile is linear from -10 to 10
positions[*,2] = -10 + findgen(nelements)/(nelements-1.)*20.

profile = '13XPS:Prof1:'
group = 'Group1'

; Fixed time per profile point, 10 seconds total for trajectory
time = 10. / nelements

; Array of times per point
;time = findgen(nelements)/(nelements-1) + .4
;time = fltarr(nelements) + .1

; Erase and start the MCS
;t = caput('13BMC:SIS1:EraseStart', 1)

status = profile_move(profile, positions, group=group, maxAxes=3, build=1, execute=1, readback=1, $
                      time=time, npulses=npulses, actual=actual, errors=errors)

end
