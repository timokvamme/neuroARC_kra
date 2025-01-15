#!/bin/bash

# NeurArchCon Diffusion Script
SUBJECT=$1  # 0001 for example
root_dir=$2  # /projects/2022_MR-SensCogGlobal/scratch


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

FREESURFER_DIR=$root_dir/timo/krakow_rsfmri_raw/freesurfer/sub-${FREESURFER_SUBJECT}

MRTRIX3_DIR=$root_dir/results/mrtrix3

OUTPUT_DIR=$MRTRIX3_DIR/sub-${SUBJECT}
CFIN_DIR=${root_dir}
MASK_DIR="${CFIN_DIR}/maskskurtosis2024/${SUBJECT}/*/MR/KURTOSIS/NATSPACE"
RESPONSE_DIR=$MRTRIX3_DIR/average_response
T1_DIR=$FREESURFER_DIR/mri
SCRATCH=$MRTRIX3_DIR/5tt

tcksift2 -act $OUTPUT_DIR/sub-${SUBJECT}_run-01_5tt.mif \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_10M_prob.tck \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_WM_FOD_norm.mif \
  	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_10M_prob.sift_second_run \
  	-out_mu ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_10M_prob.mu \
  	-out_coeffs ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_10M_prob.coeff
