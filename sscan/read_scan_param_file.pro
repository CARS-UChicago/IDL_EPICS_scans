; read scan parameter file
function read_scan_param_file,  p
   init_file = (*p).main.file
   file  = ''
   file  = dialog_pickfile(filter='*.scn', get_path=path,$
                          /must_exist, /read, file = init_file)
   file  = strtrim(file,2)
   if (file eq '') then return, -1
   openr, lun,  file, /get_lun
   print, '  Reading scan parameters from ', file
   nline = 0
   str   = ' '
   retval= -1
   mode  = 'null'
   while not (eof(lun)) do begin
       nline = nline + 1
       readf, lun,   str
       str  = strtrim(str,2)
       if (nline eq 1) then begin
           s = strmid(str, 0, 17) 
           t = strmid(str, 18, strlen(str)) 
           if (s ne ';Scan Parameters:') then begin
               print, ' File ', file,  ' is not a valid scan file'
               goto, ret
           endif
           version = t
       endif
       icol = strpos(str, ':')
       ismc = strpos(str, ';')
       if ((ismc eq 0) and (icol ge 0)) then begin
           s    = strmid(str,ismc+1, icol-1)
           mode = s
           case s of
               'Scan Parameters': mode = 'main'
               'scan 1':          mode  = 'scan1'
               'scan 2':          mode  = 'scan2'
               'scan 3':          mode  = 'scan3'
               'triggers':
               'detectors':
               else:  mode = 'null'
           endcase
       endif else begin
           key = strmid(str,0, icol)
           val = strtrim(strmid(str,icol+1, strlen(str)), 2)
           case mode of 
               'main': begin
                  case key of 
                      'prefix':    (*p).main.prefix    = val
                      'dimension': (*p).main.dimension = val
                      'detectors': (*p).main.detectors = val
                      'trigger1':  (*p).main.trigger1  = val
                      'trigger2':  (*p).main.trigger2  = val
                      'current_scan':  (*p).main.current_scan = val
                   endcase
               end
               'scan1': begin
                   case key of 
                       'type':      (*p).scan1.type      = val
                       'ScanPV':    (*p).scan1.scanPV    = val
                       'motor_name': (*p).scan1.motor_name = val
                       'pos1':      (*p).scan1.pos1      = val
                       'rbv1':      (*p).scan1.rbv1      = val
                       'units':     (*p).scan1.units     = val 
                       'time':      (*p).scan1.time      = val
                       'nregs':     (*p).scan1.nregs     = val
                       'is_rel':    (*p).scan1.is_rel    = val
                       'is_kspace': (*p).scan1.is_kspace = val
                       'r1start':   (*p).scan1.r1start   = val
                       'r1step':    (*p).scan1.r1step    = val
                       'r1stop':    (*p).scan1.r1stop    = val
                       'r2start':   (*p).scan1.r2start   = val
                       'r2step':    (*p).scan1.r2step    = val
                       'r2stop':    (*p).scan1.r2stop    = val
                       'r3start':   (*p).scan1.r3start   = val
                       'r3step':    (*p).scan1.r3step    = val
                       'r3stop':    (*p).scan1.r3stop    = val
                       'e0':        (*p).scan1.e0        = val
                       else:
                   endcase
               end
               'scan2': begin
                   case key of 
                       'type':      (*p).scan2.type      = val
                       'ScanPV':    (*p).scan2.scanPV    = val
                       'motor_name': (*p).scan2.motor_name = val
                       'pos1':      (*p).scan2.pos1      = val
                       'rbv1':      (*p).scan2.rbv1      = val
                       'units':     (*p).scan2.units     = val 
                       'time':      (*p).scan2.time      = val
                       'nregs':     (*p).scan2.nregs     = val
                       'is_rel':    (*p).scan2.is_rel    = val
                       'is_kspace': (*p).scan2.is_kspace = val
                       'r1start':   (*p).scan2.r1start   = val
                       'r1step':    (*p).scan2.r1step    = val
                       'r1stop':    (*p).scan2.r1stop    = val
                       'r2start':   (*p).scan2.r2start   = val
                       'r2step':    (*p).scan2.r2step    = val
                       'r2stop':    (*p).scan2.r2stop    = val
                       'r3start':   (*p).scan2.r3start   = val
                       'r3step':    (*p).scan2.r3step    = val
                       'r3stop':    (*p).scan2.r3stop    = val
                       'e0':        (*p).scan2.e0        = val
                       else:
                   endcase
               end
               'scan3': begin
                   case key of 
                       'type':      (*p).scan3.type      = val
                       'ScanPV':    (*p).scan3.scanPV    = val
                       'motor_name': (*p).scan3.motor_name = val
                       'pos1':      (*p).scan3.pos1      = val
                       'rbv1':      (*p).scan3.rbv1      = val
                       'units':     (*p).scan3.units     = val 
                       'time':      (*p).scan3.time      = val
                       'nregs':     (*p).scan3.nregs     = val
                       'is_rel':    (*p).scan3.is_rel    = val
                       'is_kspace': (*p).scan3.is_kspace = val
                       'r1start':   (*p).scan3.r1start   = val
                       'r1step':    (*p).scan3.r1step    = val
                       'r1stop':    (*p).scan3.r1stop    = val
                       'r2start':   (*p).scan3.r2start   = val
                       'r2step':    (*p).scan3.r2step    = val
                       'r2stop':    (*p).scan3.r2stop    = val
                       'r3start':   (*p).scan3.r3start   = val
                       'r3step':    (*p).scan3.r3step    = val
                       'r3stop':    (*p).scan3.r3stop    = val
                       'e0':        (*p).scan3.e0        = val
                       else:
                   endcase
               end
               else:
           endcase
       endelse
   endwhile
   retval = 0
ret:
   close, lun
   free_lun, lun
   return, retval
end
