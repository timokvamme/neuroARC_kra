
# NeurArchCon Diffusion QC Script

# couldnt get working

echo "Running QC script for SUBJECT=$1"

# stand in the folder
# cd /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra
# you might need to run:
# chmod +x mrtrix_pipeline_QC.sh

# ./mrtrix_pipeline_QC.sh 0002 /projects/2022_MR-SensCogGlobal/scratch

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
  echo "Error: FreeSurfer directory does not exist: $FREESURFER_DIR"
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
QC_DIR=${MRTRIX3_DIR}/QC
QC_TEMP_DIR=${QC_DIR}/temp

mkdir -p ${QC_DIR}
mkdir -p ${QC_TEMP_DIR}

echo "Directories setup:"
echo "OUTPUT_DIR=$OUTPUT_DIR"
echo "MASK_DIR=$MASK_DIR"
echo "T1_DIR=$T1_DIR"
echo "SCRATCH=$SCRATCH"
echo "QC_DIR=$QC_DIR"

# Create still frame of 5tt image
echo "Generating still frame of 5tt image..."
mrview -load ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_5tt_vis.mif \
  -config MRViewOrthoAsRow 1 \
  -config MRViewDockFloating 1 \
  -mode 2 \
  -noannotations \
  -orientationlabel 1 \
  -intensity_range 0,2 \
  -colourbar 1 \
  -size 900,300 \
  -capture.folder ${QC_DIR} \
  -capture.prefix sub-${SUBJECT}_run-01_5tt_vis_ \
  -capture.grab \
  -exit

# Create gif of registrations
echo "Generating registration QC gif..."
mrview -load ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_coreg.mif \
  -config MRViewOrthoAsRow 1 \
  -config MRViewDockFloating 1 \
  -mode 2 \
  -noannotations \
  -orientationlabel 1 \
  -size 900,300 \
  -overlay.load ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0.nii.gz \
  -capture.folder ${QC_TEMP_DIR} \
  -capture.prefix sub-${SUBJECT}_temp_ \
  $(for x in `seq 0 0.05 1`; do echo -n "-overlay.opacity $x -capture.grab "; done) \
  -exit

# Convert captured frames to GIF
echo "Creating GIF..."
convert -delay 5 ${QC_TEMP_DIR}/sub-${SUBJECT}_temp_*.png -loop 0 ${QC_DIR}/sub-${SUBJECT}_run-01_T1toB0.gif
rm ${QC_TEMP_DIR}/sub-${SUBJECT}_temp_*.png

echo "QC process completed for SUBJECT=$SUBJECT"
