
# by Timo Kvamme (Timokvamme@gmail.com)
#Doc
"""
#
# Neuroimaging Processing Pipeline for Tractography
#
# **Purpose:**
# This script automates the processing of neuroimaging data for multiple subjects
# by submitting jobs to a cluster running the Grid Engine (SGE) scheduling system.
#
# **Features:**
# - Processes multiple subjects in parallel while respecting cluster job limits.
# - Jobs are submitted in controlled batches (e.g., 10 at a time) to avoid overloading the cluster.
# - Ensures sequential execution of steps (Step 1 must complete for all subjects before Step 2 starts, etc.).
# - Supports job tracking, logging, and automated cleanup of intermediate files.
#
# **Requirements:**
# - Complete setup instructions: see `timo_install_notes.txt`
# - Dependencies: pandas, numpy, subprocess, shutil, os, time
# - Necessary environment variables for Grid Engine and FreeSurfer must be set.
#
# **Workflow:**
# 1. Load subject IDs from a CSV file (`krakow_id_correspondance_clean.csv`).
# 2. Loop through processing steps (Step 1 → Step 2 → ... → Step 5), submitting jobs in batches.
# 3. Wait for each batch to complete before proceeding.
# 4. Logs and job outputs are stored per subject for tracking and debugging.
#
# **Usage Instructions:**
#
# 1. Start a **tmux** session (to keep the process running after logout):
#    ```bash
#    tmux new -s tract
#    ```
#
# 2. Activate the correct Conda environment:
#    ```bash
#    source /users/timo/anaconda3/etc/profile.d/conda.sh && conda activate mrtrix
#    ```
#
# 3. Navigate to the script directory:
#    ```bash
#    cd /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra
#    ```
#
# 4. Run the pipeline:
#    ```bash
#    python run_con_generation_all_steps.py
#    ```
#
# **Key Files:**
# - `job_helper.py`: Helper functions for job submission, waiting, and cleanup.
# - `krakow_id_correspondance_clean.csv`: Maps subject IDs.
# - `mrtrix_pipeline_step_X.sh`: Processing scripts for each step.
#
# **Example Job Submission:**
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
# **To Detach from tmux (leave the session running in the background):**
# - Press `Ctrl + B`, then `D`
#
# **To Reattach the tmux Session:**
# ```bash
# tmux attach -t tract
# ```
#
# **To Kill the tmux Session:**
# ```bash
# tmux kill-session -t tract
# ```
#
# Look at `run_job.py` or `job_helper.py` for a simplified version of the workflow.

# i found that removing #!/bin/bash from the step.sh was required for python here to work

# to run this script:
    conda activate mrtrix
    cd /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra
    python run_con_generation_all_steps.py


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

all_subjects = all_subjects[100:150]  # Limit to first 20 subjects for testing
#all_subjects = ["0002"]

# Define parameters
batch_size = 10
check_interval = 60  # Time in seconds to wait between job status checks

# Configuration for steps to run #
steps_to_run = {
    "clean": 1,
    "step_1": 1,
    "step_2": 1,
    "step_3": 1,
    "step_4": 1,
    "step_5_desikan": 0,
    "step_5_destrieux": 1
}

# Paths to script files #
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
            if step != "step_5_destrieux":
                process_subjects_in_batches(step,all_subjects, root_dir, batch_size,script_paths,logs_dir,check_interval,email="")
            else:
                process_subjects_in_batches(step, all_subjects, root_dir, batch_size, script_paths, logs_dir,
                                            check_interval, email="timo@cfin.au.dk")

            print(f"Completed {step} for all subjects.")


print("All pipeline steps completed successfully.")






