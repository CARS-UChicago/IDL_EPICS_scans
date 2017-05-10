; This program builds a profile and executes it.

; 100 elements in the profile.
nelements = 100

; 101 pulses in the profile. 1 at start and 1 at end
npulses = 101
 
; We will move the first 2 motors (Phi and Kappa)
naxes=2
        
; Define array of positions
positions = dblarr(nelements, naxes)

; The Phi profile is a sin wave with two complete periods and an
; amplitude of +-1 degrees
positions[*,0] = 1.*sin(findgen(nelements)/(nelements-1.)*4.*!pi) + 1
        
; The Kappa profile is a sin wave with one complete period and an
; amplitude of +-1 degrees
positions[*,1] = 1.*sin(findgen(nelements)/(nelements-1.)*2.*!pi) + 2

profile = '13BMC:Prof1:'
group = 'GROUP1'

; Fixed time per profile point
;time = 0.1

; Array of times per point
;time = findgen(nelements)/(nelements-1) + .4
time = fltarr(nelements) + .1

; Erase and start the MCS
t = caput('13BMC:SIS1:EraseStart', 1)

status = profile_move(profile, positions, group=group, maxAxes=6, build=1, execute=1, readback=1, $
                      time=time, npulses=npulses, actual=actual, errors=errors)

end
