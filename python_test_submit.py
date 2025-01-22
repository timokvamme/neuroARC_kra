



import subprocess

# Job parameters
root_dir = "/projects/2022_MR-SensCogGlobal/scratch"
subject = "0003"
script_name = "mrtrix_pipeline_step_1.sh"

# Run the script directly without submission
try:
    subprocess.run([f"./{script_name}", subject, root_dir], check=True)
    print(f"Completed processing for subject: {subject}")
except subprocess.CalledProcessError as e:
    print(f"Error during processing: {e}")






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