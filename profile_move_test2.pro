; This program builds a profile and executes it.

; 2 elements in the profile.
nelements = 5

; 101 pulses in the profile. 1 at start of first element, 1 at end of last
; This makes the time between pulses = total time/(npulses-1)
npulses = 101
 
; We will move the 1 motor (Phi)
naxes=1
        
; Define array of positions
;positions = dblarr(nelements, naxes)
positions = findgen(nelements)/(nelements-1.)

; The Phi profile is a line move from 0 to 1
; amplitude of +-1 degrees
;positions[*,0] = [0., 0.5, 1.0]
        
profile = '13BMC:Prof1:'
group = 'GROUP1'

; Fixed time per profile point
time = .1

; Erase and start the MCS
t = caput('13BMC:SIS1:EraseStart', 1)

status = profile_move(profile, positions, group=group, maxAxes=6, build=1, execute=1, readback=1, $
                      time=time, npulses=npulses, actual=actual, errors=errors)

end
