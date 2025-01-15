#!/bin/bash


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

mkdir ${RESPONSE_DIR}

responsemean ${MRTRIX3_DIR}/sub-*/sub-*_run-01_RF_WM.txt $RESPONSE_DIR/group_average_response_wm.txt
responsemean ${MRTRIX3_DIR}/sub-*/sub-*_run-01_RF_GM.txt $RESPONSE_DIR/group_average_response_gm.txt
responsemean ${MRTRIX3_DIR}/sub-*/sub-*_run-01_RF_CSF.txt $RESPONSE_DIR/group_average_response_csf.txt
