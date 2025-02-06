#!/bin/bash

echo "running mrtrix_pipeline_step_1_test_fast_p_fsl_math_flirt.sh"

# Load environment setup
source /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/setup_env.sh


# stand in the folder
# cd /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra
# Ensure the script has execution permissions
# chmod +x mrtrix_pipeline_step_1_test_fast_p_fsl_math_flirt.sh

# Set FreeSurfer permissions if needed
# chmod -R u+r /projects/MINDLAB2016_MR-SensCogFromNeural/scratch/timo/krakow_rsfmri_raw/freesurfer/

# ./mrtrix_pipeline_step_1_test_fast_p_fsl_math_flirt.sh 0004 /projects/2022_MR-SensCogGlobal/scratch

SUBJECT=$1  # e.g., 0002
root_dir=$2  # e.g., /projects/2022_MR-SensCogGlobal/scratch

# Ensure both arguments are provided
if [[ -z $SUBJECT || -z $root_dir ]]; then
  echo "Usage: $0 <SUBJECT> <root_dir>"
  exit 1
fi

# Lookup FREESURFER_SUBJECT
SCRIPT_DIR="/projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra"
csv_file="${SCRIPT_DIR}/krakow_id_correspondance_clean.csv"

FREESURFER_SUBJECT=$(awk -F',' -v subject="$SUBJECT" '
NR > 1 && $2 ~ subject {
    gsub(/"/, "", $3);
    print $3;
}' "$csv_file")

if [[ -z $FREESURFER_SUBJECT ]]; then
  echo "Error: Could not find FREESURFER_SUBJECT for SUBJECT=$SUBJECT in $csv_file"
  exit 1
fi

FREESURFER_SUBJECT=$(echo "$FREESURFER_SUBJECT" | tr -d '\r' | tr -d '[:space:]')

echo "Processing SUBJECT=$SUBJECT with FREESURFER_SUBJECT=$FREESURFER_SUBJECT"

# Set FreeSurfer subject directory
export SUBJECTS_DIR="/projects/MINDLAB2016_MR-SensCogFromNeural/scratch/timo/krakow_rsfmri_raw/freesurfer"
FREESURFER_DIR="${SUBJECTS_DIR}/sub-${FREESURFER_SUBJECT}"

# Verify if FreeSurfer directory exists
if [[ ! -d $FREESURFER_DIR ]]; then
  echo "Error: FreeSurfer directory does not exist: $FREESURFER_DIR"
  exit 1
fi

# Define subject-specific directories
MRTRIX3_DIR=$root_dir/results/mrtrix3
OUTPUT_DIR=$MRTRIX3_DIR/sub-${SUBJECT}
CFIN_DIR=${root_dir}
MASK_DIR="${CFIN_DIR}/maskskurtosis2024/${SUBJECT}/*/MR/KURTOSIS/NATSPACE"
RESPONSE_DIR=$MRTRIX3_DIR/average_response
T1_DIR=$FREESURFER_DIR/mri
SCRATCH=$MRTRIX3_DIR/5tt

# Print paths for verification
echo "Directories setup:"
echo "OUTPUT_DIR=$OUTPUT_DIR"
echo "MASK_DIR=$MASK_DIR"
echo "T1_DIR=$T1_DIR"
echo "SCRATCH=$SCRATCH"

echo "Script starting successfully for $SUBJECT."

# Step 1: Running FAST segmentation
echo "Step 1: Running FAST segmentation..."
fast -p ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz

# Check if FAST produced the expected output
if [[ ! -f ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pve_2.nii.gz ]]; then
  echo "Error: FAST segmentation failed for SUBJECT=$SUBJECT."
  exit 1
fi

# Step 2: Directly binarize pve_2.nii.gz (white matter probability) into wm_seg_bin.nii.gz
echo "Step 2: Binarizing white matter segmentation (pve_2.nii.gz) into wm_seg_bin.nii.gz..."
fslmaths ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pve_2.nii.gz \
         -thr 0.5 -bin \
         ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg_bin.nii.gz

# Verify if binarization worked
if [[ ! -f ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg_bin.nii.gz ]]; then
  echo "Error: WM segmentation binarization failed for SUBJECT=$SUBJECT."
  exit 1
fi

# Cleanup unnecessary outputs from FAST (but KEEP wm_seg.nii.gz intact!)
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pve_0.nii.gz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pve_1.nii.gz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_mixeltype.nii.gz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pveseg.nii.gz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_seg.nii.gz

# Step 3: Initial FLIRT Registration
echo "Step 3: Running initial FLIRT registration..."
flirt -in ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0_brain.nii.gz \
      -ref ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz \
      -dof 6 \
      -omat ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_fsl_initial.mat

# Verify if FLIRT produced the initial transformation matrix
if [[ ! -f ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_fsl_initial.mat ]]; then
  echo "Error: Initial FLIRT registration failed for SUBJECT=$SUBJECT."
  exit 1
fi

# Step 4: FLIRT with BBR using the binarized WM segmentation
echo "Step 4: Running FLIRT with BBR..."
flirt -in ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0_brain.nii.gz \
      -ref ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz \
      -dof 6 \
      -cost bbr \
      -wmseg ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg_bin.nii.gz \
      -init ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_fsl_initial.mat \
      -omat ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_fsl_bbr.mat \
      -schedule $FSLDIR/etc/flirtsch/bbr.sch

# Verify if BBR completed successfully
if [[ ! -f ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_fsl_bbr.mat ]]; then
  echo "Error: BBR registration failed for SUBJECT=$SUBJECT."
  exit 1
fi

echo "Pipeline completed successfully for SUBJECT=$SUBJECT."
