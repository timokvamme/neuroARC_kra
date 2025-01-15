# Copyright Claude Bajada
# claude.bajada@um.edu.mt
# modified by CHEN Hao
# modified by Timo Kvamme

org_file=aparc.a2009s+aseg.mgz # Destrieux atlas

SUBJECT=$1
root_dir=${FREESURFER_HOME}
FREESURFER_DATA_DIR=/scratch7/MINDLAB2016_MR-SensCogFromNeural/results/freesurfer/sub-${SUBJECT}
MRTRIX3_DIR=/scratch7/MINDLAB2016_MR-SensCogFromNeural/results/mrtrix3/sub-${SUBJECT}
OUTPUT_DIR=/scratch7/MINDLAB2016_MR-SensCogFromNeural/results/mrtrix3_Destrieux/sub-${SUBJECT}
TT5_DIR=/scratch7/MINDLAB2016_MR-SensCogFromNeural/results/5tt/sub-${SUBJECT}
COSTLABELSGMFIX_DIR=/users/chenhao/Documents/projects/ebbinghaus/MR/costlabelsgmfix
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