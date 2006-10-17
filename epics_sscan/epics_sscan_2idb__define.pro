pro epics_sscan_2idb::read_mda, filename
   ; Call the base class method
   self->epics_sscan::read_mda, filename
   ; Is this a 2idb fly scan where the first detector in the innermost scan is an MCA, and there is 
   ; no positioner
   sh = (*self.fileHeader.pScanHeader)[self.fileHeader.rank-1]
   if (sh.numPositioners ne 0) then return
   d = *sh.pDetectors[0]
   if (strpos(d.name, 'mca') eq -1) then return
   ; Get the energy calibration coefficients.  For now we hard-code what extra PVs hold this, but we
   ; could easily search through all of the extraPVs for the .CALO, .CALS and .CALQ fields for this
   ; MCA.
   offset = *(*self.fileHeader.pExtraPVs)[68].pValue
   slope = *(*self.fileHeader.pExtraPVs)[69].pValue
   quad = *(*self.fileHeader.pExtraPVs)[70].pValue
   energy = findgen(sh.npts)
   energy = offset + slope*energy + quad*energy^2
   p = {epics_sscanPositioner}
   p.description = 'Energy'
   p.units = 'keV'
   p.pData = ptr_new(energy)
   (*self.fileHeader.pScanHeader)[self.fileHeader.rank-1].numPositioners=1
   (*self.fileHeader.pScanHeader)[self.fileHeader.rank-1].pPositioners[0] = ptr_new(p)
end
   

pro epics_sscan_2idb__define
   c = {epics_sscan_2idb, inherits epics_sscan}
end

