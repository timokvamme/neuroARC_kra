#!/bin/bash

# NeurArchCon Diffusion Script - note that this picks up from the CFIN pipeline

SUBJECT=$1  # 0001 for example
root_dir=$2  # /projects/2022_MR-SensCogGlobal/scratch

# stand in the folder
# cd /projects/MINDLAB2016_MR-SensCogFromNeural/scratch/timo/mi/analyses/aim1/kra_struct_connectome_tractography
# you might need to run:
# chmod +x mrtrix_pipeline_step_1.sh

# ./mrtrix_pipeline_step_1.sh 0001 /projects/2022_MR-SensCogGlobal/scratch

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

# Script for processing CFIN pipeline output with MRtrix3 for tractography


mkdir -p ${OUTPUT_DIR}

mrcat ${CFIN_DIR}/datakurtosis2024/${SUBJECT}/*/MR/KURTOSIS1_DIRS/NATSPACE/*nii ${OUTPUT_DIR}/temp.mif

mrconvert \
	${OUTPUT_DIR}/temp.mif \
	-fslgrad \
	${CFIN_DIR}/infokurtosis2024/${SUBJECT}/*/MR/KURTOSIS/diffusion.bvec \
	${CFIN_DIR}/infokurtosis2024/${SUBJECT}/*/MR/KURTOSIS/diffusion.bval \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_DWI.mif
	
rm ${OUTPUT_DIR}/temp.mif

# Create 5tt image for ACT 
5ttgen hsvs ${FREESURFER_DIR} ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt.mif -scratch ${SCRATCH}/sub-${SUBJECT} -nocleanup

# Co-register T1w to B0
dwiextract ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_DWI.mif - -bzero | \
	mrmath - mean ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0.nii.gz -axis 3

bet ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0.nii.gz ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0_brain.nii.gz
# mrconvert -strides -1,2,3 ${FREESURFER_DIR}/mri/norm.mgz ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz

mri_vol2vol --mov ${FREESURFER_DIR}/mri/brain.mgz --targ ${FREESURFER_DIR}/mri/rawavg.mgz --regheader --o ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.mgz --no-save-reg
mri_vol2vol --mov ${FREESURFER_DIR}/mri/T1.mgz --targ ${FREESURFER_DIR}/mri/rawavg.mgz --regheader --o ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w.mgz --no-save-reg
# mri_label2vol --seg ${FREESURFER_DIR}/mri/wm.seg.mgz --temp ${FREESURFER_DIR}/mri/rawavg.mgz --o ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg.mgz --regheader ${FREESURFER_DIR}/mri/wm.seg.mgz
 
mri_convert -it mgz -ot nii ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.mgz ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz
mri_convert -it mgz -ot nii ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w.mgz ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w.nii.gz
# mri_convert -it mgz -ot nii ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg.mgz ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg.nii.gz

rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.mgz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w.mgz
# rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg.mgz

fast ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz
mv ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pve_2.nii.gz ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg.nii.gz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pve_0.nii.gz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pve_1.nii.gz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_mixeltype.nii.gz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pveseg.nii.gz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_seg.nii.gz


flirt -in ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0_brain.nii.gz \
	-ref ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz \
	-dof 6 \
	-omat ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_fsl_initial.mat

flirt -in ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0_brain.nii.gz \
	-ref ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz \
	-dof 6 \
	-cost bbr \
	-wmseg ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg.nii.gz \
	-init ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_fsl_initial.mat \
	-omat ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_fsl_bbr.mat \
	-schedule $FSLDIR/etc/flirtsch/bbr.sch
	
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
5tt2vis ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt.mif ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt_vis.mif	
5tt2vis ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt_coreg.mif ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt_vis_coreg.mif

dwi2response dhollander \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_DWI.mif \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_RF_WM.txt \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_RF_GM.txt \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_RF_CSF.txt \
	-voxels ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_RF_voxels.mif
