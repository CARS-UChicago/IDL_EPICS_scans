; This program uses trajectory_scan.pro to build and execute a trajectory.

nelements = 11
; nelements output pulses during the trajectory
npulses = nelements
naxes = 2
trajRecord = 'IOC:traj1'

element_time = 1.0
;  seconds total time to execute the trajectory
time = element_time * nelements

; 1 second acceleration time
accel = 1.

; The M1 trajectory is linear from 0.5 to 1.0
t1 = 0.5 + findgen(nelements)/(nelements-1) * 0.5

; The M2 trajectory is linear from 52 to 51

t2 = 53 - findgen(nelements)/(nelements-1) * 1.0

traj = dblarr(nelements, naxes)
traj[0,0] = t1
traj[0,1] = t2

status = trajectory_scan(trajRecord, traj, accel=accel, time=time, /read, actual=actual, errors=errors)

end

