#!/bin/bash

# if you change this file you need to run sed -i 's/\r$//' /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/setup_env.sh
# because of the windows line endings

# Load necessary environment
source ~/.bashrc
source /users/timo/anaconda3/etc/profile.d/conda.sh
conda activate mrtrix

export PATH="/users/timo/anaconda3/envs/mrtrix/bin:$PATH"

# Explicitly set and source FreeSurfer environment
export FREESURFER_HOME="/usr/local/freesurfer"
source ${FREESURFER_HOME}/SetUpFreeSurfer.sh

# Set paths for neuroimaging tools
export PATH="/users/timo/my_fsl/share/fsl/bin:${FREESURFER_HOME}/bin:$PATH"
export LD_LIBRARY_PATH="/users/timo/my_fsl/lib:${FREESURFER_HOME}/lib:$LD_LIBRARY_PATH"

# Debugging output
echo "Environment Setup Completed:"
echo "FREESURFER_HOME: $FREESURFER_HOME"
echo "BET path: $(which bet)"
echo "FLIRT path: $(which flirt)"
echo "MRI_CONVERT path: $(which mri_convert)"
echo "Python version: $(python --version 2>&1)"
echo "Active Conda environment: $(conda info --envs | grep '*' | awk '{print $1}')"
echo "PATH: $PATH"
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
