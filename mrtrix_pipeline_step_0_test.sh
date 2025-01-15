#!/bin/bash

# NeurArchCon Diffusion Script - note that this picks up from the CFIN pipeline

SUBJECT=$1
root_dir=$2

# Define the path to the CSV file

SCRIPT_DIR="/projects/MINDLAB2016_MR-SensCogFromNeural/scratch/timo/mi/analyses/aim1/kra_struct_connectome_tractography"

csv_file="${SCRIPT_DIR}/krakow_id_correspondance_clean.csv"
# Lookup FREESURFER_SUBJECT
FREESURFER_SUBJECT=$(awk -F',' -v subject="$SUBJECT" '
NR > 1 && $2 ~ subject {
    gsub(/"/, "", $3);
    print $3;
}' "$csv_file")
# Error handling
if [[ -z $FREESURFER_SUBJECT ]]; then
  echo "Error: Could not find FREESURFER_SUBJECT (krakow_id) for SUBJECT=$SUBJECT in $csv_file"
  exit 1
fi
echo "Processing SUBJECT=$SUBJECT with FREESURFER_SUBJECT=$FREESURFER_SUBJECT"




