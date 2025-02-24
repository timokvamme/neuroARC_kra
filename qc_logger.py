import os
import pandas as pd
import numpy as np

# Define paths
logs_dir = "/projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/logs"
connectome_dir = "/projects/2022_MR-SensCogGlobal/scratch/results/mrtrix3"
subject_list_path = "/projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/krakow_id_correspondance_clean.csv"
qc_logs_folder =  "/projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/qc_logs"


# Load subject IDs
all_subjects = np.array(pd.read_csv(subject_list_path, dtype=str)["storm_db_id"])

# Initialize DataFrame
qc_results = pd.DataFrame(index=all_subjects, columns=[
    "node_streamline_assigned_err", "logfile_found", "con_matrix_found", "num_NA", "num_zeros"
])

for subject in all_subjects:
    log_file_path = os.path.join(logs_dir, f"sub_{subject}_step_5_destrieux.err")
    connectome_file_path = os.path.join(connectome_dir, f"sub-{subject}", f"sub-{subject}_run-01_connectome.csv")

    # Check for step 5 log file
    try:
        with open(log_file_path, 'r') as log_file:
            log_content = log_file.read()
            if "tck2connectome: [WARNING] The following nodes do not have any streamlines assigned:" in log_content:
                qc_results.loc[subject, "node_streamline_assigned_err"] = True
            else:
                qc_results.loc[subject, "node_streamline_assigned_err"] = False
        qc_results.loc[subject, "logfile_found"] = True
    except FileNotFoundError:
        qc_results.loc[subject, "node_streamline_assigned_err"] = "NA"
        qc_results.loc[subject, "logfile_found"] = False

    # Check for connectome file and count NA/zeros
    try:
        con_matrix = pd.read_csv(connectome_file_path, header=None)
        qc_results.loc[subject, "num_NA"] = con_matrix.isna().sum().sum()
        qc_results.loc[subject, "num_zeros"] = (con_matrix == 0).sum().sum()
        qc_results.loc[subject, "con_matrix_found"] = True
    except FileNotFoundError:
        qc_results.loc[subject, "num_NA"] = "NA"
        qc_results.loc[subject, "num_zeros"] = "NA"
        qc_results.loc[subject, "con_matrix_found"] = False

# Save QC results
qc_results.to_csv(qc_logs_folder + "/qc_summary_24_02_2025.csv")


import shutil
source = "/projects/2022_MR-SensCogGlobal/scratch/results/mrtrix3_final_connectome_destrieux"
destination = "/projects/MINDLAB2016_MR-SensCogFromNeural/scratch/timo/krakow_struct_mrtrix_results"
shutil.copytree(source, destination)