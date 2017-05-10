function max_scanpts, s
;
m = 0
s = ca_get(s + '.MPTS', m)
if s ne 0 then m = 2000
return, m
end

