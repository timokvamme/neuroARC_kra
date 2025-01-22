#!/bin/bash
# NeurArchCon Diffusion Script - Processes Freesurfer data for a given subject

conda activate mrtrix

SUBJECT=$1  # e.g., 0002
root_dir=$2  # e.g., /projects/2022_MR-SensCogGlobal/scratch

# stand in the folder
# cd /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra
# you might need to run:
# chmod +x mrtrix_pipeline_step_1.sh

# and for the freesurfer
# chmod -R u+r /projects/MINDLAB2016_MR-SensCogFromNeural/scratch/timo/krakow_rsfmri_raw/freesurfer/

# ./mrtrix_pipeline_step_1_test.sh 0002 /projects/2022_MR-SensCogGlobal/scratch

# Ensure both arguments are provided
if [[ -z $SUBJECT || -z $root_dir ]]; then
  echo "Usage: $0 <SUBJECT> <root_dir>"
  exit 1
fi

# Paths
SCRIPT_DIR="/projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra"
csv_file="${SCRIPT_DIR}/krakow_id_correspondance_clean.csv"

# Lookup FREESURFER_SUBJECT
FREESURFER_SUBJECT=$(awk -F',' -v subject="$SUBJECT" '
NR > 1 && $2 ~ subject {
    gsub(/"/, "", $3);
    print $3;
}' "$csv_file")

# Remove any trailing carriage return characters
FREESURFER_SUBJECT=$(echo "$FREESURFER_SUBJECT" | tr -d '\r')

# Error handling if FREESURFER_SUBJECT is empty
if [[ -z $FREESURFER_SUBJECT ]]; then
  echo "Error: Could not find FREESURFER_SUBJECT (krakow_id) for SUBJECT=$SUBJECT in $csv_file"
  exit 1
fi

echo "Processing SUBJECT=$SUBJECT with FREESURFER_SUBJECT=$FREESURFER_SUBJECT"

# Freesurfer paths
export SUBJECTS_DIR="/projects/MINDLAB2016_MR-SensCogFromNeural/scratch/timo/krakow_rsfmri_raw/freesurfer"
FREESURFER_DIR="${SUBJECTS_DIR}/sub-${FREESURFER_SUBJECT}"

# Debugging output
echo "DEBUG: SUBJECTS_DIR=$SUBJECTS_DIR"
echo "DEBUG: FREESURFER_DIR=$FREESURFER_DIR"

# Verify the Freesurfer directory exists
if [[ ! -d $FREESURFER_DIR ]]; then
  echo "Error: Freesurfer directory does not exist: $FREESURFER_DIR"
  exit 1
fi

# List the contents of the Freesurfer directory
echo "Listing contents of Freesurfer directory:"
ls "$FREESURFER_DIR"




MRTRIX3_DIR=$root_dir/results/mrtrix3
OUTPUT_DIR=$MRTRIX3_DIR/sub-${SUBJECT}
CFIN_DIR=${root_dir}
MASK_DIR="${CFIN_DIR}/maskskurtosis2024/${SUBJECT}/*/MR/KURTOSIS/NATSPACE"
RESPONSE_DIR=$MRTRIX3_DIR/average_response
T1_DIR=$FREESURFER_DIR/mri
SCRATCH=$MRTRIX3_DIR/5tt

# Script for processing CFIN pipeline output with MRtrix3 for tractography


mkdir -p ${OUTPUT_DIR}

mrcat ${CFIN_DIR}/datakurtosis2024/${SUBJECT}/*/MR/KURTOSIS_DIRS/NATSPACE/*nii ${OUTPUT_DIR}/temp.mif

mrconvert \
	${OUTPUT_DIR}/temp.mif \
	-fslgrad \
	${CFIN_DIR}/infokurtosis2024/${SUBJECT}/*/MR/KURTOSIS/diffusion.bvec \
	${CFIN_DIR}/infokurtosis2024/${SUBJECT}/*/MR/KURTOSIS/diffusion.bval \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_DWI.mif

rm ${OUTPUT_DIR}/temp.mif