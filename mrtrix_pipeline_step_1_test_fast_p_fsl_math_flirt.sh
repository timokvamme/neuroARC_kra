echo "Step 1: Running FAST segmentation..."
fast -p ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz

# Check if FAST produced the expected outputs
if [[ ! -f ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pve_2.nii.gz ]]; then
  echo "Error: FAST segmentation failed for SUBJECT=$SUBJECT."
  exit 1
fi

# Rename white matter segmentation
mv ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pve_2.nii.gz ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg.nii.gz

# Cleanup unnecessary outputs from FAST
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pve_0.nii.gz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pve_1.nii.gz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_mixeltype.nii.gz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_pveseg.nii.gz
rm ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain_seg.nii.gz

echo "Step 2: Binarizing white matter segmentation..."
fslmaths ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg.nii.gz \
         -thr 0.5 -bin \
         ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg_bin.nii.gz

# Verify if binarization worked
if [[ ! -f ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg_bin.nii.gz ]]; then
  echo "Error: WM segmentation binarization failed for SUBJECT=$SUBJECT."
  exit 1
fi

echo "Step 3: Running initial FLIRT registration..."
flirt -in ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0_brain.nii.gz \
      -ref ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz \
      -dof 6 \
      -omat ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_fsl_initial.mat

# Verify if FLIRT produced the initial transformation matrix
if [[ ! -f ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_fsl_initial.mat ]]; then
  echo "Error: Initial FLIRT registration failed for SUBJECT=$SUBJECT."
  exit 1
fi

echo "Step 4: Running FLIRT with BBR..."
flirt -in ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_mean_b0_brain.nii.gz \
      -ref ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_T1w_brain.nii.gz \
      -dof 6 \
      -cost bbr \
      -wmseg ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_wm_seg_bin.nii.gz \
      -init ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_fsl_initial.mat \
      -omat ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_fsl_bbr.mat \
      -schedule $FSLDIR/etc/flirtsch/bbr.sch

# Verify if BBR completed successfully
if [[ ! -f ${OUTPUT_DIR}/sub-${SUBJECT}_run-01_diff2struct_fsl_bbr.mat ]]; then
  echo "Error: BBR registration failed for SUBJECT=$SUBJECT."
  exit 1
fi

echo "Pipeline completed successfully for SUBJECT=$SUBJECT."