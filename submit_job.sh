#!/bin/bash

# Load Anaconda correctly
source /users/timo/anaconda3/etc/profile.d/conda.sh
export PATH="/users/timo/anaconda3/bin:$PATH"
conda activate mrtrix

# Run the job script for the subject
bash "$JOB_SCRIPT" "$SUBJECT"