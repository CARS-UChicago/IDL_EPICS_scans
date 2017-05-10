; This program builds a trajectory and executes it.

; The trajectory definition is absolute mode
; definined in absolute coordinates rather than displacements from on
; element to the next. However, the motors do not move to the absolute
; position of the first element before executing the trajectory.

 nelements = 100
 npulses = 200

; We will move the first 2 motors (Phi and Kappa)
 naxes=2

; Define array of positions
positions = dblarr(nelements, naxes)

; The Phi trajectory is a sin wave with two complete periods and an
; amplitude of +-8 degrees
positions[*,0] = 8.*sin(findgen(nelements)/(nelements-1.)*4.*!pi)

; The Kappa trajectory is a sin wave with one complete period and an
; amplitude of +-20 degrees
positions[*,1] = 20.*sin(findgen(nelements)/(nelements-1.)*2.*!pi)

delta_pos = positions - shift(positions, -1, 0)
delta_pos = delta_pos[0:nelements-2, *]

; Simple linear trajectory test
;positions = [0,10.]

trajectory = '13BMC:traj1'

; Total time for trajectory
time = 30.
time_per_point = time / npulses
exptime = time_per_point - 0.004  ; 4msec readout time for Pilatus

pil = 'GSE-PILATUS2:'
t=caput(pil+'AcquireMode','3')  ; Multiple trigger mode
t=caput(pil+'ExposureTime',exptime)
t=caput(pil+'NImages',npulses)

t=caput(pil+'Acquire','1')

;status = trajectory_scan(trajectory, positions, /build, /execute, /read, $
;                         time=time, npulses=npulses, actual=actual, errors=errors)
status = trajectory_scan(trajectory,delta_pos, /relative, /build, /execute, /read, $
                         time=time, npulses=npulses, actual=actual, errors=errors)

end
