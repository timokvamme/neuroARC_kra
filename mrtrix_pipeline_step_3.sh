
echo "running mrtrix_pipeline_step_3.sh"

# Load environment setup
source /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/setup_env.sh

# stand in the folder
# cd /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra
# you might need to run:
# chmod +x mrtrix_pipeline_step_3.sh

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


echo "Script step_3.sh starting successfully for $SUBJECT."

echo "Applying brain mask dilation..."
maskfilter ${MASK_DIR}/brainmask.nii dilate ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_brainmask.mif

echo "Computing fiber orientation distributions (FOD) using MSMT-CSD..."
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

echo "Performing multi-tissue normalization..."
mtnormalise \
	-nthreads 2 \
  	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_WM_FOD.mif ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_WM_FOD_norm.mif \
  	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_GM.mif ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_GM_norm.mif \
  	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_CSF.mif ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_CSF_norm.mif \
  	-mask ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_brainmask.mif

echo "Removing intermediate FOD images..."
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_WM_FOD.mif
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_GM.mif
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_CSF.mif

echo "Converting and concatenating FOD images into volume fraction maps..."
mrconvert \
	-coord 3 0 ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_WM_FOD_norm.mif - | \
	mrcat ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_CSF_norm.mif \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_GM_norm.mif \
	- ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_vf_norm.mif

echo "Generating probabilistic tractography (10 million streamlines)..."
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
  	-nthreads 8 \
  	-cutoff 0.06

echo "Processing step_3.sh completed for $SUBJECT."



