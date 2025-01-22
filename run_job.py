
from job_helper import *
import os

os.environ["SGE_ROOT"] = "/usr/local/common/GridEngine"  # Change this if necessary
os.environ["PATH"] += os.pathsep + "/usr/local/common/GridEngine/bin/lx-amd64"

# Set the subject ID here
subject_id = "0005"  # Change this ID as needed

job_name_template = f"job_{subject_id}_step1.sh"
log_out_template = f"/projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/logs/job_{subject_id}.out"
log_err_template = f"/projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/logs/job_{subject_id}.err"
script_path = "/projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/mrtrix_pipeline_step_1.sh"
scratch_dir = "/projects/2022_MR-SensCogGlobal/scratch"
# Submit the job with the provided parameters
submit_job(subject_id, job_name_template, log_out_template, log_err_template, script_path, scratch_dir, email="timo@cfin.au.dk")

# Check job status
check_job_status()