# by Timo Kvamme (Timokvamme@gmail.com)

# import
import subprocess, os
from stormdb.access import Query
import pandas as pd
import numpy as np

# define subjects and root
# q = Query('2022_MR-SensCogGlobal')
# subjects_XXX = q.get_subjects()
# all_subjects = [subject.split('_')[0] for subject in subjects_XXX]

os.chdir("/projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra")
# subjects we have freesurfer on
all_subjects = np.array(pd.read_csv("krakow_id_correspondance_clean.csv", dtype=str)["storm_db_id"])

# Define the root directory and subject IDs
root_dir = "/projects/2022_MR-SensCogGlobal/scratch"
subjects = all_subjects
subjects = ["0002"]  # Add all your subject IDs here


# Define the configuration for which steps to run (1 to run, 0 to skip)
steps_to_run = {
    "step_1": 1,
    "step_2": 0,
    "step_3": 0,
    "step_4_mu_coeff": 0,
    "step_5_desikan": 0,
    "step_5_destrieux": 0
}


# Paths to scripts
script_paths = {
    "step_1": "mrtrix_pipeline_step_1_test.sh",
    "step_2": "mrtrix_pipeline_step_2.sh",
    "step_3": "mrtrix_pipeline_step_3.sh",
    "step_4_mu_coeff": "mrtrix_pipeline_step_4.sh",
    "step_5_desikan": "mrtrix_pipeline_step_5_desikan.sh",
    "step_5_destrieux": "mrtrix_pipeline_step_5_destrieux.sh"
}

def run_step_for_all_subjects(step_name, subjects, root_dir):
    """Run a specific step script for all subjects."""
    script = script_paths[step_name]
    for subject in subjects:
        try:
            print(f"Running {script} for SUBJECT={subject}")
            subprocess.run([f"./{script}", subject, root_dir], check=True)
        except subprocess.CalledProcessError as e:
            print(f"Error while running {script} for SUBJECT={subject}: {e}")
            break  # Stop if an error occurs

# Run all steps sequentially for all subjects
for step in ["step_1", "step_2", "step_3", "step_4_mu_coeff", "step_5_desikan", "step_5_destrieux"]:
    if steps_to_run[step]:
        print(f"Starting {step} for all subjects...")
        run_step_for_all_subjects(step, subjects, root_dir)
        print(f"Completed {step} for all subjects.")

print("All steps completed.")




from stormdb.cluster import ClusterJob
import subprocess

# Define the full path to qsub
qsub_path = "/usr/local/common/GridEngine/bin/lx-amd64/qsub"

# Job parameters
root_dir = "/projects/2022_MR-SensCogGlobal/scratch"
subject = "0003"
script_name = "mrtrix_pipeline_step_1.sh"
queue = "short.q"
job_name = "mrtrix_test"
proj_name = "2022_MR-SensCogGlobal"

# Construct submission command for bash script
submit_cmd = f"source /usr/local/common/GridEngine/default/common/settings.sh && {qsub_path} -q {queue} -N {job_name} -cwd -b y bash {script_name} {subject} {root_dir}"

try:
    subprocess.run(submit_cmd, shell=True, check=True)
    print(f"Job {job_name} submitted successfully for SUBJECT={subject} to cluster.")
except subprocess.CalledProcessError as e:
    print(f"Error submitting job: {e}")




import subprocess

# Define the full path to qsub
qsub_path = "/usr/local/common/GridEngine/bin/lx-amd64/qsub"

# Job parameters
script_name = "test_bash.sh"
queue = "short.q"
job_name = "test_10min_job"

# Construct submission command for bash script
submit_cmd = f"source /usr/local/common/GridEngine/default/common/settings.sh && {qsub_path} -q {queue} -N {job_name} -cwd -b y bash {script_name}"

try:
    subprocess.run(submit_cmd, shell=True, check=True)
    print(f"Job {job_name} submitted successfully to cluster.")
except subprocess.CalledProcessError as e:
    print(f"Error submitting job: {e}")



def check_job_status():
    qstat_path = "/usr/local/common/GridEngine/bin/lx-amd64/qstat"

    try:
        result = subprocess.run([qstat_path], capture_output=True, text=True, check=True)
        print("Current job status:\n")
        print(result.stdout)
    except subprocess.CalledProcessError as e:
        print("Error checking job status:", e)
    except FileNotFoundError:
        print(f"Error: Could not find qstat at {qstat_path}")


# Call function to check status
check_job_status()