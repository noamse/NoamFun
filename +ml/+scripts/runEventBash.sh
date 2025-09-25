#!/bin/bash

# ========= INPUT ARGUMENTS =========
FieldNum=$1
Site=${2:-CTIO}
FieldToAvoid=${3:-''}

if [ -z "$FieldNum" ]; then
  echo "[ERROR] Missing required argument <FieldNum>"
  echo "Usage: $0 <FieldNum> [Site=CTIO] [FieldToAvoid='']"
  exit 1
fi

echo "=========================================="
echo "🔧 KMT Event Processing Launcher"
echo "------------------------------------------"
echo "  📌 Event number     : $FieldNum"
echo "  🛰️  Site             : $Site"
echo "  ❌ Field to avoid    : $FieldToAvoid"
echo "  ⏱️  Start time        : $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

# ========= RUN FIELD PROCESSING IN MATLAB =========
echo "🚀 Running MATLAB: processKMTEvent..."
TargetLogPath=$(matlab -batch "out = ml.scripts.processKMTEventField($FieldNum,'Site','$Site','FieldToAvoid','$FieldToAvoid'); disp(out);" \
            | grep -v '^\s*$' | tail -n 1)

echo "✅ MATLAB finished. Top-level log path:"
echo "   $TargetLogPath"

# ========= IDENTIFY RESULT DIRECTORIES =========
#ResultBaseDir="/home/noamse/KMT/data/Results/kmt${FieldNum}/${Site}"

ResultBaseDir="/home/noamse/KMT/data/Results/kmt${FieldNum}/${Site}/"

if [ ! -d "$ResultBaseDir" ]; then
  echo "[ERROR] Result directory does not exist: $ResultBaseDir"
  exit 1
fi

# Count fields
#FieldDirs=("$ResultBaseDir"BLG*/)
FieldDirs=( $(find $ResultBaseDir -mindepth 1 -maxdepth 1 -type d) )

NumFields=${#FieldDirs[@]}

echo "=========================================="
echo "📂 Results path       : $ResultBaseDir"
echo "🔍 Found $NumFields fields to process:"
for dir in "${FieldDirs[@]}"; do
    echo "   └─ $(basename "$dir")"
done
echo "=========================================="

# ========= LOOP OVER FIELDS & RUN ASTROMETRY =========
for fieldDir in "${FieldDirs[@]}"; do
  [ -d "$fieldDir" ] || continue
  #fieldName=$(basename "$fieldDir")

  echo "------------------------------------------"
  #echo "🧭 Running astrometry for field: $fieldName"
  echo " Running astrometry for field: $fieldDir"
  echo "   ➤ Directory: '$fieldDir/'"

  AstroFile=$(matlab -batch "FilePath = ml.scripts.runAstrometryField($FieldNum,'Field','$fieldName','TargetPath','$fieldDir/'); disp(FilePath);" \
              | grep -v '^\s*$' | tail -n 1)

  echo "   ✅ Astrometry result file: $AstroFile"
done

echo "=========================================="
echo "✅ All fields completed."
echo "📅 Done at: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

