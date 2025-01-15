#!/bin/bash

# NeurArchCon Diffusion Script

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

# Create still frame of 5tt image
mrview -load ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt_vis.mif \
	-config MRViewOrthoAsRow 1 \
	-config MRViewDockFloating 1 \
	-mode 2 \
	-noannotations \
	-orientationlabel 1 \
	-intensity_range 0,2 \
	-colourbar 1 \
	-size 900,300 \
	-capture.folder ${MRTRIX3_DIR}/QC \
	-capture.prefix sub-${SUBJECT}_run-01_5tt_vis_ \
	-capture.grab \
	-exit

# Create gif of registrations
mrview -load ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_coreg.mif \
	-config MRViewOrthoAsRow 1 \
	-config MRViewDockFloating 1 \
	-mode 2 \
	-noannotations \
	-orientationlabel 1 \
	-size 900,300 \
	-overlay.load ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0.nii.gz \
	-capture.folder ${MRTRIX3_DIR}/QC/temp \
	-capture.prefix sub-${SUBJECT}_temp_ \
	$(for x in `seq 0 0.05 1`; do echo -n "-overlay.opacity $x -capture.grab "; done) \
	-exit
	
convert -delay 5 ${MRTRIX3_DIR}/QC/temp/sub-${SUBJECT}_temp_*.png -loop 0 ${MRTRIX3_DIR}/QC/sub-${SUBJECT}_run-01_T1toB0.gif
rm ${MRTRIX3_DIR}/QC/temp/sub-${SUBJECT}_temp_*.png

