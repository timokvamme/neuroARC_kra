#!/bin/bash

# NeurArchCon Diffusion Script (this is the script for the desikan connectome)

SUBJECT=$1
root_dir=$2
FREESURFER_DIR=$root_dir/BIDS/derivatives/freesurfer/sub-${SUBJECT}
MRTRIX3_DIR=$root_dir/BIDS/derivatives/mrtrix3
OUTPUT_DIR=$MRTRIX3_DIR/sub-${SUBJECT}
CFIN_DIR=${root_dir}/BIDS/derivatives/CFINpipeline
MASK_DIR="${CFIN_DIR}/masksCA18106_DWI_CFINpipeline/${SUBJECT}/*/MR/KURTOSIS1/NATSPACE"
RESPONSE_DIR=$root_dir/BIDS/derivatives/mrtrix3/average_response
T1_DIR=$root_dir/BIDS/sub-${SUBJECT}/anat
SCRATCH=$root_dir/BIDS/derivatives/5tt

labelconvert \
	${FREESURFER_DIR}/mri/aparc+aseg.mgz \
	${root_dir}/FreeSurferColorLUT.txt \
	${root_dir}/fs_default.txt ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_nodes.mif \
	-nthreads 0

${root_dir}/costlabelsgmfix/costlabelsgmfix \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_nodes.mif \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz \
	${root_dir}/fs_default.txt \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_nodes_fixed.mif -premasked \
	${root_dir}/BIDS/derivatives/5tt/sub-${SUBJECT} \
	-nthreads 0

mrtransform \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_nodes_fixed.mif \
	-linear ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_mrtrix_bbr.txt \
	-inverse ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_nodes_fixed_coreg.mif \
	-nthreads 0

tck2connectome \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_10M_prob.tck \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_nodes_fixed_coreg.mif ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_connectome.csv \
	-tck_weights_in ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_10M_prob.sift \
	-out_assignments ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_assignments.txt \
	-nthreads 0
