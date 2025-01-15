# by Timo Kvamme (Timokvamme@gmail.com)

# import
import subprocess, os
from stormdb.access import Query
import pandas as pd
import numpy as np

import mrtrix3

# define subjects and root
# q = Query('2022_MR-SensCogGlobal')
# subjects_XXX = q.get_subjects()
# all_subjects = [subject.split('_')[0] for subject in subjects_XXX]

# subjects we have freesurfer on
all_subjects = np.array(pd.read_csv("krakow_id_correspondance_clean.csv", dtype=str)["storm_db_id"])

# Define the root directory and subject IDs
root_dir = "/projects/2022_MR-SensCogGlobal/scratch"
subjects = all_subjects
subjects = ["0002"]  # Add all your subject IDs here


# Define the configuration for which steps to run (1 to run, 0 to skip)
steps_to_run = {
    "step_1": 1,
    "step_2": 1,
    "step_3": 1,
    "step_4_mu_coeff": 1,
    "step_5_desikan": 0,
    "step_5_destrieux": 1
}


# Paths to scripts
script_paths = {
    "step_1": "mrtrix_pipeline_step_1.sh",
    "step_2": "mrtrix_pipeline_step_2.sh",
    "step_3": "mrtrix_pipeline_step_3.sh",
    "step_4_mu_coeff": "mrtrix_pipeline_step_4_mu_coeff.sh",
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
