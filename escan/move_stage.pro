pro jog_xzstages
   rz = caget('13XRM:pm1.VAL', z)
   rz = caput('13XRM:pm1.VAL', z+0.001)
   rz = caget('13XRM:pm2.VAL', x)
   rz = caput('13XRM:pm2.VAL', x+0.001)
   wait, 0.25
   rz = caput('13XRM:pm1.VAL', z)
   rz = caput('13XRM:pm2.VAL', x)
return
end

pro move_stage, position=position, stage_file=stage_file, wait=wait 

; move to a named position in an SampleStage.ini file

file  = 'SampleStage_autosave.ini'
pos   = ''
if (keyword_set(stage_file)  ne 0 ) then  file = stage_file
if (keyword_set(position)  ne 0 )   then  pos  = position

pos  = strlowcase(strtrim(pos,2))
mdat = read_stageini(stage_file=file)

; jog_xzstages

if strlen(pos) ge 1 then  begin
   move_to_stage_position, mdat, pos, wait=wait 
endif

return
end
