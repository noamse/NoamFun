#!/bin/bash
#
FieldNum=$1

# Check if an argument was provided
if [ -z "$FieldNum" ]; then
  echo "Usage: $0 <FieldNum>"
  exit 1
fi

# Run MATLAB with the argument and capture output
LogFile=$(matlab -batch "out = ml.kmt.processKMTEvent($FieldNum); disp(out);" | grep -v '^\s*$' | tail -n 1) 
echo "Log file for reduction: $LogFile"

AstroFile=$(matlab -batch "FilePath = ml.scripts.runAstrometryField($FieldNum); disp(FilePath);" | grep -v '^\s*$' | tail -n 1)
echo "Astrometry results file : $AstroFile" 
