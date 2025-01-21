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


transformconvert ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_fsl_bbr.mat \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0_brain.nii.gz \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz \
	flirt_import ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_mrtrix_bbr.txt

#old:  ${T1_DIR}/sub-${SUBJECT}_run-01_T1w.nii.gz \
mrtransform ${T1_DIR}/T1.mgz \
	-linear ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_mrtrix_bbr.txt \
	-inverse ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_coreg.mif

mrtransform ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt.mif \
	-linear ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_mrtrix_bbr.txt \
	-inverse ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt_coreg.mif

rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w*.nii.gz

# Create 5tt visualisations for QC
5tt2vis ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt.mif ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt_vis.mif -force
5tt2vis ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt_coreg.mif ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt_vis_coreg.mif -force

dwi2response dhollander \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_DWI.mif \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_RF_WM.txt \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_RF_GM.txt \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_RF_CSF.txt \
	-voxels ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_RF_voxels.mif
