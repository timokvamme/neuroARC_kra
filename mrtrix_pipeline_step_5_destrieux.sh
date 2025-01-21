# Copyright Claude Bajada
# claude.bajada@um.edu.mt
# modified by CHEN Hao
# modified by Timo Kvamme



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
org_file=aparc.a2009s+aseg.mgz # Destrieux atlas
#

LUT_DIR=/users/chenhao/Documents/projects/ebbinghaus/MR
mkdir ${OUTPUT_DIR}

labelconvert \
	${FREESURFER_DATA_DIR}/mri/${org_file} \
	${root_dir}/FreeSurferColorLUT.txt \
	${LUT_DIR}/${lut_file} ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_nodes.mif \
	-nthreads 0

${COSTLABELSGMFIX_DIR}/costlabelsgmfix \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_nodes.mif \
	/projects/MINDLAB2016_MR-SensCogFromNeural/scratch/rsDenoise/raw/sub-${SUBJECT}/anat/sub-${SUBJECT}_run-01_T1w.nii.gz \
	${LUT_DIR}/${lut_file} \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_nodes_fixed.mif -premasked \
	${TT5_DIR} \
	-nthreads 0

mrtransform \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_nodes_fixed.mif \
	-linear ${MRTRIX3_DIR}/sub-${SUBJECT}_run-01_diff2struct_mrtrix_bbr.txt \
	-inverse ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_nodes_fixed_coreg.mif \
	-nthreads 0

tck2connectome \
	${MRTRIX3_DIR}/sub-${SUBJECT}_run-01_10M_prob.tck \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_nodes_fixed_coreg.mif ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_connectome.csv \
	-tck_weights_in ${MRTRIX3_DIR}/sub-${SUBJECT}_run-01_10M_prob.sift \
	-out_assignments ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_assignments.txt \
	-nthreads 0