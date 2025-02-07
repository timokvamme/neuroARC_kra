
# by Timo Kvamme (Timokvamme@gmail.com)
#Doc
"""
#
# This script automates the processing of neuroimaging data for multiple subjects
# by submitting jobs to a cluster running the Grid Engine (SGE) scheduling system.
#
# **Purpose:**
# The script ensures that:
#  - Multiple subjects are processed in parallel while respecting cluster job limits.
#  - Jobs are submitted in batches (e.g., 10 at a time) to avoid overloading the cluster.
#  - Steps are executed sequentially for all subjects (Step 1 must complete for all before Step 2 starts, etc.).
#
# **Requirements:**
# - For a complete setup look through timo_install_notes.txt
# - Necessary environment variables for Grid Engine and FreeSurfer must be set correctly.
# - Required dependencies: pandas, numpy, subprocess, shutil, os, time
#
# **Structure:**
# - The script reads subject IDs from a CSV file containing their corresponding IDs.
# - It defines which processing steps to run (steps 1 to 5).
# - Each step's pipeline script is executed in a controlled manner.
# - Cleanup functions ensure fresh data processing before new submissions.
#
# **Execution Flow:**
# 1. Load subject IDs from CSV.
# 2. Loop through processing steps, submitting jobs in batches of 10.
# 3. Wait for each batch to complete before proceeding.
# 4. Logs and job outputs are stored per subject for tracking and debugging.
#
# **Usage Instructions:**
# 1. Ensure the necessary environment variables are set:
#    - `SGE_ROOT` should point to the Grid Engine installation path.
#    - `PATH` should include Grid Engine binary location.
#
# 2. Activate the correct Conda environment:
#    ```bash
#    source /users/timo/anaconda3/etc/profile.d/conda.sh && conda activate mrtrix
#    ```
#
# 3. Run the script using:
#    ```bash
#    python run_pipeline.py
#    ```
#
# **Key Files:**
# - `job_helper.py`: Contains helper functions for job submission, waiting, and cleanup.
# - `krakow_id_correspondance_clean.csv`: Maps subject IDs.
# - `mrtrix_pipeline_step_X.sh`: The processing scripts for each step.
#
# **Example:**
# ```python
# from job_helper import submit_job, wait_for_job_completion, cleanup_subject
#
# subject_id = "0005"
# submit_job(subject_id, "logs/job_0005.out", "logs/job_0005.err", "mrtrix_pipeline_step_1.sh", "/scratch", email="timo@cfin.au.dk")
# ```
#
# **Notes:**
# - The script will stop execution if an error occurs during job submission.
# - Email notifications can be enabled to receive job status updates.
#
# Look at `run_job.py` or `job_helper.py` for a simplified version of the workflow.
"""



from job_helper import *

# Set environment variables for Grid Engine
os.environ["SGE_ROOT"] = "/usr/local/common/GridEngine"
os.environ["PATH"] += os.pathsep + "/usr/local/common/GridEngine/bin/lx-amd64"
# Directory paths
results_dir = "/projects/2022_MR-SensCogGlobal/scratch/results/mrtrix3"
logs_dir = "/projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/logs"
root_dir = "/projects/2022_MR-SensCogGlobal/scratch"

# Load subject IDs
os.chdir("/projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra")
all_subjects = np.array(pd.read_csv("krakow_id_correspondance_clean.csv", dtype=str)["storm_db_id"]) # check lookup_id_krakow.R

all_subjects = all_subjects[0:10]  # Limit to first 20 subjects for testing
#all_subjects = ["0003","0004"]

# Define parameters
batch_size = 10
check_interval = 60  # Time in seconds to wait between job status checks

# Configuration for steps to run
steps_to_run = {
    "clean": 0,
    "step_1": 0,
    "step_2": 0,
    "step_3": 1,
    "step_4": 0,
    "step_5_desikan": 0,
    "step_5_destrieux": 0
}

# Paths to script files
script_paths = {
    #"step_1": "/projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/mrtrix_pipeline_step_1_test_fast_flirt.sh",
    "step_1": "/projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/mrtrix_pipeline_step_1.sh",
    "step_2": "/projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/mrtrix_pipeline_step_2.sh",
    "step_3": "/projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/mrtrix_pipeline_step_3.sh",
    "step_4": "/projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/mrtrix_pipeline_step_4.sh",
    "step_5_desikan": "/projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/mrtrix_pipeline_step_5_desikan.sh",
    "step_5_destrieux": "/projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/mrtrix_pipeline_step_5_destrieux.sh"
}


# Run pipeline steps sequentially

if steps_to_run["clean"]:
    for subject_id in all_subjects:
        cleanup_subject(subject_id, results_dir, logs_dir)
    steps_to_run.pop("clean")

for step in steps_to_run.keys():
    if steps_to_run[step]:
        print(f"Running pipeline step: {step}")

        if step == "step_2":
            process_single_subject(step, all_subjects[0], root_dir, script_paths, logs_dir, check_interval)
        else:
            print(f"Starting {step} for all subjects...")
            process_subjects_in_batches(step,all_subjects, root_dir, batch_size,script_paths,logs_dir,check_interval)
            print(f"Completed {step} for all subjects.")



print("All pipeline steps completed successfully.")



# import numpy as np
# from nilearn import image
# nifti_file = "/projects/2022_MR-SensCogGlobal/scratch/results/mrtrix3/sub-0004/sub-0004_run-01_mean_b0_brain.nii.gz"
# img = image.load_img(nifti_file)
#
# # Convert to NumPy array
# data = img.get_fdata()
#
# # Check for NaN values
# num_nans = np.isnan(data).sum()
# if num_nans > 0:print(f"❌ Found {num_nans} NaN values in the image data!")
# else:print("✅ No NaN values found in the image.")
#
