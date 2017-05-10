
pro set_i0_sensitivity, sens, unit
bmd_macros
    set_srs570_gain, '13BMD:A3', sens, unit
return
end

pro set_i1_sensitivity, sens, unit
bmd_macros
    set_srs570_gain, '13BMD:A2', sens, unit
return
end

pro Hslit , pos
   x = caput('13BMD:BMDHsize.VAL', pos)
return
end

pro move_to_mo
bmd_macros
set_i0_sensitivity, 5, 'nA/V'
move_to_energy, 20200, i0=45
return
end

pro move_to_zn
bmd_macros
set_i0_sensitivity, 10, 'nA/V'
move_to_energy, 9800, i0=80
return
end

pro move_to_fe
bmd_macros
set_i0_sensitivity, 5, 'nA/V'
move_to_energy, 7200, i0=80
return
end

pro move_to_as
bmd_macros
set_i0_sensitivity, 10, 'nA/V'
move_to_energy, 11950, i0=70
return
end

pro macro
;; very important: keep the next line!!

bmd_macros
;;
;; start editing here -->.

;;--------------- JUNK  -------------------------------
;;move_to_map
;;map_at, pos='stem_thick_L4', scan='mapL4'
;;move_to_fe
;;scan_at, pos='L1-P1-XANE', scan='fe_xafs', number=3
;; move_to_xrd
;;expose_at, pos='Pb2BR2_spot1a', t=300
;;move_to_xrd
;;expose_at, pos='glass', t=100
;;-------------------------------------------------------





;scan_at, pos='Jackie_Goethite', scan='fe_xafs', number=1
;scan_at, pos='Jackie_Ferrihydrite', scan='fe_xafs', number=1




set_i1_sensitivity, 1, 'nA/V'


scan_at, pos='Jackie_B_Ox_2', scan='fe_xafs', number=1
scan_at, pos='Beth_ATE_Ox2', scan='fe_xafs', number=3


set_i1_sensitivity, 2, 'nA/V'

scan_at, pos='Beth_ATE_24R2', scan='fe_xafs', number=2

set_i1_sensitivity, 200, 'pA/V'

scan_at, pos='Beth_ATE_48R2', scan='fe_xafs', number=3
scan_at, pos='Jackie_L_Ox_4', scan='fe_xafs', number=1
scan_at, pos='Beth_ATE_24R2', scan='fe_xafs', number=2


return
end
