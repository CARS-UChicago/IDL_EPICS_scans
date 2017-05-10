; This program uses trajectory_scan.pro to build and execute a trajectory.

nelements = 101
; 300 output pulses during the trajectory
npulses = 300
naxes = 2
trajRecord = 'IOC:traj1'

; 0.5 second per element
elementTime = 0.5

; Total time to execute the trajectory
time = elementTime * nelements

; 1 second acceleration time
accel = 1.

; The M1 trajectory is a sin wave with and offset of 0.5, two complete periods and an
; amplitude of +- 0.2
t1 = 0.5 + 0.2*sin(findgen(nelements)/(nelements-1.)*4.*!pi)

; The M2 trajectory is a sin wave with on offset of 51, one complete period and an
; amplitude of +-0.3
t2 = 51. + 0.3*sin(findgen(nelements)/(nelements-1.)*2.*!pi)

traj = dblarr(nelements, naxes)
traj[0,0] = t1
traj[0,1] = t2

status = trajectory_scan(trajRecord, traj, accel=accel, time=time, /read, actual=actual, errors=errors)

end

