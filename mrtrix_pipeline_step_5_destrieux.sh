
# NeurArchCon Diffusion Script

echo "running mrtrix_pipeline_step_5_destrieux.sh"

# Load environment setup
source /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/setup_env.sh

# stand in the folder
# cd /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra
# you might need to run:
# chmod +x mrtrix_pipeline_step_5_destrieux.sh
# chmod +x /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/costlabelsgmfix/costlabelsgmfix

# and for the freesurfer
# chmod -R u+r /projects/MINDLAB2016_MR-SensCogFromNeural/scratch/timo/krakow_rsfmri_raw/freesurfer/

# ./mrtrix_pipeline_step_5_destrieux.sh 0002 /projects/2022_MR-SensCogGlobal/scratch

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
org_file=aparc.a2009s+aseg.mgz # Destrieux atlas
TT5_DIR=$MRTRIX3_DIR/5tt/sub-${SUBJECT}

# Print paths for verification
echo "Directories setup:"
echo "OUTPUT_DIR=$OUTPUT_DIR"
echo "MASK_DIR=$MASK_DIR"
echo "T1_DIR=$T1_DIR"
echo "SCRATCH=$SCRATCH"


echo "Script step_5_destrieux.sh starting succesfully for $SUBJECT."

#
echo "Converting FreeSurfer labels to MRtrix format..."
labelconvert \
    "${FREESURFER_DIR}/mri/${org_file}" \
     ${SCRIPT_DIR}/FreeSurferColorLUT.txt \
     ${SCRIPT_DIR}/fs_a2009s.txt ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_nodes.mif \
     -nthreads 0 -force

echo "Applying CostLabelSGMFix for anatomical corrections..."
${SCRIPT_DIR}/costlabelsgmfix/costlabelsgmfix \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_nodes.mif \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz \
	${SCRIPT_DIR}/fs_a2009s.txt \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_nodes_fixed.mif -premasked \
	${TT5_DIR} \
	-nthreads 0 -force

echo "Transforming corrected nodes to diffusion space..."
mrtransform \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_nodes_fixed.mif \
	-linear ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_mrtrix_bbr.txt \
	-inverse ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_nodes_fixed_coreg.mif \
	-nthreads 0 -force

echo "Generating structural connectome from tractography..."
tck2connectome \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_10M_prob.tck \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_nodes_fixed_coreg.mif \
	${OUTPUT_DIR}/sub-${SUBJECT}_run-01_connectome.csv \
	-tck_weights_in ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_10M_prob.sift \
	-out_assignments ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_assignments.txt \
	-nthreads 0 -force

echo "Script step_5_destrieux.sh completed succesfully for $SUBJECT."