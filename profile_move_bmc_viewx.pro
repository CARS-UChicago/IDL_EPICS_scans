; This program builds a profile and executes it.

; 2 elements in the profile.
nelements = 6

; 1 pulses in the profile.
npulses = 50
 
; We will move only 1 motor
naxes=1
useAxes = [0]
        
; Define array of positions
positions = dblarr(nelements)

pulseRange = [3,3]

; The M3 profile is linear from -1 to 1
positions = [1., 2., 3., 4., 5., 6.]

profile = '13BMC:Prof2:'
group = 'VIEW_X'

; Fixed time per profile point
time = 2.

status = profile_move(profile, positions, group=group, maxAxes=1, useAxes=useAxes, build=1, execute=1, readback=1, $
                      time=time, npulses=npulses, actual=actual, errors=errors)

end
