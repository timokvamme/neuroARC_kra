#!/bin/bash

echo "running mrtrix_pipeline_step_2.sh"

# Load environment setup
source /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/setup_env.sh

# stand in the folder
# cd /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra
# you might need to run:
# chmod +x mrtrix_pipeline_step_1.sh

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


echo "Script step_2.sh starting succesfully for $SUBJECT."

mkdir ${RESPONSE_DIR}

responsemean ${MRTRIX3_DIR}/sub-*/sub-*_run-01_RF_WM.txt $RESPONSE_DIR/group_average_response_wm.txt -force
responsemean ${MRTRIX3_DIR}/sub-*/sub-*_run-01_RF_GM.txt $RESPONSE_DIR/group_average_response_gm.txt -force
responsemean ${MRTRIX3_DIR}/sub-*/sub-*_run-01_RF_CSF.txt $RESPONSE_DIR/group_average_response_csf.txt -force

echo "Response Mean Done"
echo "Script step_2.sh finished succesfully"