; This program builds a trajectory and executes it.

; The trajectory definition is hybid mode, meaning the positions are
; definined in absolute coordinates rather than displacements from on
; element to the next. However, the motors do not move to the absolute
; position of the first element before executing the trajectory.

; 101 elements in the trajectory. We use 4N+1 since we are defining the
; trajectory in Hybrid mode
 nelements = 1000
 
; We will move the first 2 motors (Phi and Kappa)
 naxes=2
        
; Define array of positions
positions = dblarr(nelements, naxes)

; The Phi trajectory is a sin wave with two complete periods and an
; amplitude of +-8 degrees
positions[*,0] = 1.*sin(findgen(nelements)/(nelements-1.)*4.*!pi)
        
; The Kappa trajectory is a sin wave with one complete period and an
; amplitude of +-20 degrees
positions[*,1] = 1.*sin(findgen(nelements)/(nelements-1.)*2.*!pi)

trajectory = '13IDC:traj1'

; Total time for trajectory
time = 10.

status = trajectory_scan(trajectory, positions, /hybrid, /build, /execute, /read, $
                         time=time, npulses=1000, actual=actual, errors=errors)

end
