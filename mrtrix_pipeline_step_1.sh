
echo "running mrtrix_pipeline_step_1.sh"

# Load environment setup
source /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/setup_env.sh # if you chance this file you need to run
# sed -i 's/\r$//' /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/setup_env.sh
# sed -i 's/\r$//' /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/mrtrix_pipeline_step_1.sh
# sed -i 's/\r$//' /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/mrtrix_pipeline_step_2.sh
# sed -i 's/\r$//' /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/mrtrix_pipeline_step_3.sh
# sed -i 's/\r$//' /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/mrtrix_pipeline_step_4.sh
# sed -i 's/\r$//' /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/mrtrix_pipeline_step_5_destrieux.sh


# stand in the folder
# cd /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra
# you might need to run:
# chmod +x mrtrix_pipeline_step_1.sh

# and for the freesurfer
# chmod -R u+r /projects/MINDLAB2016_MR-SensCogFromNeural/scratch/timo/krakow_rsfmri_raw/freesurfer/

# ./mrtrix_pipeline_step_1.sh 0002 /projects/2022_MR-SensCogGlobal/scratch


# looking at images:
#  cd /projects/2022_MR-SensCogGlobal/scratch/results

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



echo "Script step_1.sh starting successfully for $SUBJECT."

echo "Creating output directory..."
mkdir -p ${OUTPUT_DIR}

echo "Concatenating diffusion-weighted images..."
mrcat ${CFIN_DIR}/datakurtosis2024/${SUBJECT}/*/MR/KURTOSIS_DIRS/NATSPACE/*nii ${OUTPUT_DIR}/temp.mif

echo "Converting diffusion data to MRtrix format..."
mrconvert \
	${OUTPUT_DIR}/temp.mif \
	-fslgrad \
	${CFIN_DIR}/infokurtosis2024/${SUBJECT}/*/MR/KURTOSIS/diffusion.bvec \
	${CFIN_DIR}/infokurtosis2024/${SUBJECT}/*/MR/KURTOSIS/diffusion.bval \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_DWI.mif

rm ${OUTPUT_DIR}/temp.mif

echo "Creating 5TT image for Anatomically-Constrained Tractography (ACT)..."
5ttgen hsvs ${FREESURFER_DIR} ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt.mif -scratch ${SCRATCH}/sub-${SUBJECT} -nocleanup

echo "Extracting mean B0 image..."
dwiextract ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_DWI.mif - -bzero | \
	mrmath - mean ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0.nii.gz -axis 3

echo "Performing brain extraction..."
bet ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0.nii.gz ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0_brain.nii.gz

echo "Co-registering T1-weighted images..."
mri_vol2vol --mov ${FREESURFER_DIR}/mri/brain.mgz --targ ${FREESURFER_DIR}/mri/rawavg.mgz --regheader --o ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.mgz --no-save-reg
mri_vol2vol --mov ${FREESURFER_DIR}/mri/T1.mgz --targ ${FREESURFER_DIR}/mri/rawavg.mgz --regheader --o ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w.mgz --no-save-reg
mri_label2vol --seg ${FREESURFER_DIR}/mri/wm.seg.mgz --temp ${FREESURFER_DIR}/mri/rawavg.mgz --o ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg.mgz --regheader ${FREESURFER_DIR}/mri/wm.seg.mgz

echo "Converting MGZ to NIfTI format..."
mri_convert -it mgz -ot nii ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.mgz ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz
mri_convert -it mgz -ot nii ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w.mgz ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w.nii.gz
mri_convert -it mgz -ot nii ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg.mgz ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg.nii.gz

rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.mgz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w.mgz

echo "Segmenting white matter..."
fast -p ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz

# fslmaths step suggested by Claude, binarizes the wm_seg and is used in flirt bbr command.
fslmaths ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pve_2.nii.gz -thr 0.5 -bin ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg_bin.nii.gz

rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pve_0.nii.gz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pve_1.nii.gz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_mixeltype.nii.gz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pveseg.nii.gz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_seg.nii.gz

echo "Registering DWI to structural space..."
flirt -in ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0_brain.nii.gz \
	-ref ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz \
	-dof 6 \
	-omat ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_fsl_initial.mat

echo "Refining registration with BBR..."
flirt -in ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0_brain.nii.gz \
	-ref ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz \
	-dof 6 \
	-cost bbr \
	-wmseg ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg_bin.nii.gz \
	-init ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_fsl_initial.mat \
	-omat ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_fsl_bbr.mat \
	-schedule $FSLDIR/etc/flirtsch/bbr.sch

echo "Converting transformation for MRtrix..."
transformconvert ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_fsl_bbr.mat \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0_brain.nii.gz \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz \
	flirt_import ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_mrtrix_bbr.txt

echo "Applying transformation to T1-weighted image..."
mrtransform ${T1_DIR}/T1.mgz \
	-linear ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_mrtrix_bbr.txt \
	-inverse ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_coreg.mif

echo "Applying transformation to 5TT image..."
mrtransform ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt.mif \
	-linear ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_mrtrix_bbr.txt \
	-inverse ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt_coreg.mif

echo "Creating 5TT visualization for quality control..."
5tt2vis ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt.mif ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt_vis.mif
5tt2vis ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt_coreg.mif ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt_vis_coreg.mif

echo "Estimating response functions..."
dwi2response dhollander \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_DWI.mif \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_RF_WM.txt \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_RF_GM.txt \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_RF_CSF.txt \
	-voxels ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_RF_voxels.mif

echo "Script step_1.sh finished succesfully for $SUBJECT."