#!/bin/bash

# NeurArchCon Diffusion Script

# stand in the folder
# cd /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra
# you might need to run:
# chmod +x mrtrix_pipeline_step_3.sh

# and for the freesurfer
# chmod -R u+r /projects/MINDLAB2016_MR-SensCogFromNeural/scratch/timo/krakow_rsfmri_raw/freesurfer/

# ./mrtrix_pipeline_step_3.sh 0002 /projects/2022_MR-SensCogGlobal/scratch


SUBJECT=$1  # 0001 for example
root_dir=$2  # /projects/2022_MR-SensCogGlobal/scratch


SCRIPT_DIR="/projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra"

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

FREESURFER_DIR=$root_dir/timo/krakow_rsfmri_raw/freesurfer/sub-${FREESURFER_SUBJECT}

MRTRIX3_DIR=$root_dir/results/mrtrix3

OUTPUT_DIR=$MRTRIX3_DIR/sub-${SUBJECT}
CFIN_DIR=${root_dir}
MASK_DIR="${CFIN_DIR}/maskskurtosis2024/${SUBJECT}/*/MR/KURTOSIS/NATSPACE"
RESPONSE_DIR=$MRTRIX3_DIR/average_response
T1_DIR=$FREESURFER_DIR/mri
SCRATCH=$MRTRIX3_DIR/5tt

maskfilter ${MASK_DIR}/brainmask.nii dilate ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_brainmask.mif

dwi2fod msmt_csd \
	-nthreads 2 \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_DWI.mif \
	$RESPONSE_DIR/group_average_response_wm.txt \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_WM_FOD.mif \
	$RESPONSE_DIR/group_average_response_gm.txt \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_GM.mif \
	$RESPONSE_DIR/group_average_response_csf.txt \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_CSF.mif \
	-mask ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_brainmask.mif
	
mtnormalise \
	-nthreads 2 \
  	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_WM_FOD.mif ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_WM_FOD_norm.mif \
  	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_GM.mif ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_GM_norm.mif \
  	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_CSF.mif ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_CSF_norm.mif \
  	-mask ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_brainmask.mif

rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_WM_FOD.mif
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_GM.mif
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_CSF.mif
  	
mrconvert \
	-coord 3 0 ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_WM_FOD_norm.mif - | \
	mrcat ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_CSF_norm.mif \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_GM_norm.mif \
	- ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_vf_norm.mif

tckgen ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_WM_FOD_norm.mif ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_10M_prob.tck \
  	-algorithm iFOD2 \
  	-seed_dynamic ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_WM_FOD_norm.mif \
  	-output_seeds ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_seeds.txt \
  	-act ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt_coreg.mif \
  	-backtrack \
  	-crop_at_gmwmi \
  	-maxlength 250 \
  	-minlength 20 \
  	-select 10M \
  	-nthreads 10 \
  	-cutoff 0.06


