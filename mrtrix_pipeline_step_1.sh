#!/bin/bash

echo "running mrtrix_pipeline_step_1.sh"

# Load environment setup
source /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/setup_env.sh

# stand in the folder
# cd /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra
# you might need to run:
# chmod +x mrtrix_pipeline_step_1.sh

# and for the freesurfer
# chmod -R u+r /projects/MINDLAB2016_MR-SensCogFromNeural/scratch/timo/krakow_rsfmri_raw/freesurfer/

# ./mrtrix_pipeline_step_1.sh 0002 /projects/2022_MR-SensCogGlobal/scratch


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
  echo "Error: Freesurfer directory does not exist: $FREESURFER_DIR"
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

### **Step 1: Prepare directories and process DWI data**
echo "Step 1: Preparing directories and processing DWI data..."
mkdir -p ${OUTPUT_DIR}

# Concatenate all DWI images
mrcat ${CFIN_DIR}/datakurtosis2024/${SUBJECT}/*/MR/KURTOSIS_DIRS/NATSPACE/*nii ${OUTPUT_DIR}/temp.mif

# Convert to MRtrix format with FSL gradients
mrconvert \
	${OUTPUT_DIR}/temp.mif \
	-fslgrad \
	${CFIN_DIR}/infokurtosis2024/${SUBJECT}/*/MR/KURTOSIS/diffusion.bvec \
	${CFIN_DIR}/infokurtosis2024/${SUBJECT}/*/MR/KURTOSIS/diffusion.bval \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_DWI.mif

rm ${OUTPUT_DIR}/temp.mif

### **Step 2: Generate 5tt image for Anatomically-Constrained Tractography (ACT)**
echo "Step 2: Creating 5tt image for ACT..."
5ttgen hsvs ${FREESURFER_DIR} ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt.mif -scratch ${SCRATCH}/sub-${SUBJECT} -nocleanup

### **Step 3: Extract mean b0 image and preprocess**
echo "Step 3: Extracting mean b0 image..."
dwiextract ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_DWI.mif - -bzero | \
	mrmath - mean ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0.nii.gz -axis 3

bet ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0.nii.gz ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0_brain.nii.gz

### **Step 4: FAST segmentation for white matter**
echo "Step 4: Running FAST segmentation..."

# this is where things are different from https://github.com/MassimoLumaca/neuroARC/tree/main
# we are using the -p flag to output the pve_2.nii.gz file
# which we then binarize with fslmaths, and use that for input in flirt bbr as suggested by Claude.

fast -p ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz

# Check if FAST produced the expected pve_2 output
if [[ ! -f ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pve_2.nii.gz ]]; then
  echo "Error: FAST segmentation failed for SUBJECT=$SUBJECT."
  exit 1
fi

# Step 5: Binarize the white matter segmentation for FLIRT BBR
echo "Step 5: Binarizing white matter segmentation..."
fslmaths ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pve_2.nii.gz \
         -thr 0.5 -bin \
         ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg_bin.nii.gz

# Cleanup unnecessary FAST outputs but keep original wm_seg intact
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pve_0.nii.gz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pve_1.nii.gz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_mixeltype.nii.gz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pveseg.nii.gz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_seg.nii.gz

### **Step 6: Initial FLIRT affine registration**
echo "Step 6: Running initial FLIRT registration..."
flirt -in ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0_brain.nii.gz \
      -ref ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz \
      -dof 6 \
      -omat ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_fsl_initial.mat

### **Step 7: FLIRT with Boundary-Based Registration (BBR)**
echo "Step 7: Running FLIRT with BBR..."
flirt -in ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0_brain.nii.gz \
      -ref ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz \
      -dof 6 \
      -cost bbr \
      -wmseg ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg_bin.nii.gz \
      -init ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_fsl_initial.mat \
      -omat ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_fsl_bbr.mat \
      -schedule $FSLDIR/etc/flirtsch/bbr.sch

### **Step 8: Post-registration processing**
echo "Step 8: Post-registration transformations..."
transformconvert ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_fsl_bbr.mat \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0_brain.nii.gz \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz \
	flirt_import ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_mrtrix_bbr.txt

mrtransform ${T1_DIR}/T1.mgz \
	-linear ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_mrtrix_bbr.txt \
	-inverse ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_coreg.mif

echo "Pipeline completed successfully for SUBJECT=$SUBJECT."