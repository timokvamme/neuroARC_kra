


import subprocess
import shutil
import os
import time
import subprocess, os
import numpy as np
import pandas as pd

def submit_job(subject_id, log_out_template, log_err_template, script_path, scratch_dir, email=""):
    """
    Submits a job to the cluster for the given subject ID with customizable parameters.
    Optionally sends an email notification upon job completion if an email is provided.
    """
    script_path_last_9 = script_path[-9:]
    job_name = f"j_{subject_id}_{script_path_last_9}".format(subject_id=subject_id,script_path_last_9=script_path_last_9)
    log_out = log_out_template.format(subject_id=subject_id)
    log_err = log_err_template.format(subject_id=subject_id)

    qsub_path = "/usr/local/common/GridEngine/bin/lx-amd64/qsub"

    submit_command = [
        qsub_path,
        "-q", "long.q",
        "-o", log_out,
        "-e", log_err,
        "-N", job_name,
        "-b", "y",
    ]

    if email:
        submit_command.extend(["-M", email, "-m", "bea"])  # Send mail at begin, end, and abort

    submit_command.extend([
        "/bin/bash", "-c",
        f"source /users/timo/anaconda3/etc/profile.d/conda.sh && conda activate mrtrix && {script_path} {subject_id} {scratch_dir}"
    ])

    try:
        result = subprocess.run(submit_command, capture_output=True, text=True, check=True)
        print(f"Job for subject {subject_id} submitted successfully.")
        print("Submission Output:\n", result.stdout)

        # Extract job ID from submission output
        job_id = result.stdout.strip().split()[2]  # Get the third word assuming typical output format: "Your job 7480398 ("job_0003_step1.sh") has been submitted"
        return job_id
    except subprocess.CalledProcessError as e:
        print(f"Error submitting job for subject {subject_id}:\n", e.stderr)
    except FileNotFoundError:
        print("Error: Could not find the qsub command. Make sure Grid Engine is installed and available.")

    return None


def qstat():
    """
    Checks the status of submitted jobs in the queue.
    """
    qstat_path = "/usr/local/common/GridEngine/bin/lx-amd64/qstat"
    res = None
    try:
        result = subprocess.run([qstat_path], capture_output=True, text=True, check=True)
        print("Current job status:\n")
        print(result.stdout)
        res = result
    except subprocess.CalledProcessError as e:
        print("Error checking job status:\n", e.stderr)
    except FileNotFoundError:
        print(f"Error: Could not find qstat at {qstat_path}")

    return res


def check_job_status(job_id):
    """
    Checks the status of a submitted job in the queue.

    Parameters:
        job_id (str): The job ID to check.

    Returns:
        bool: True if job is still running, False otherwise.
    """
    qstat_path = "/usr/local/common/GridEngine/bin/lx-amd64/qstat"
    try:
        result = subprocess.run([qstat_path], capture_output=True, text=True, check=True)
        if job_id in result.stdout:
            return True  # Job is still running
        else:
            return False  # Job is no longer in the queue
    except subprocess.CalledProcessError as e:
        print("Error checking job status:\n", e.stderr)
    except FileNotFoundError:
        print(f"Error: Could not find qstat at {qstat_path}")

    return False


def wait_for_job_completion(job_id, check_interval=10):
    """
    Waits for a job to finish by continuously checking its status.

    Parameters:
        job_id (str): The job ID to monitor.
        check_interval (int): Time interval in seconds to check the job status.
    """
    print(f"Waiting for job {job_id} to complete...")
    while check_job_status(job_id):
        print(f"Job {job_id} is still running. Checking again in {check_interval} seconds...")
        time.sleep(check_interval)

    print(f"Job {job_id} has completed.")


def cleanup_subject(subject_id, results_dir, logs_dir):
    """
    Cleans up the subject's data by deleting the subject folder and log files.

    Parameters:
        subject_id (str): Subject ID (e.g., "0002")
        results_dir (str): Path to the results directory (e.g., "/projects/2022_MR-SensCogGlobal/scratch/results/mrtrix3")
        logs_dir (str): Path to the logs directory (e.g., "/projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/logs")
    """
    subject_folder = os.path.join(results_dir, f"sub-{subject_id}")
    log_out = os.path.join(logs_dir, f"job_{subject_id}.out")
    log_err = os.path.join(logs_dir, f"job_{subject_id}.err")

    # Delete the subject folder
    if os.path.exists(subject_folder):
        try:
            shutil.rmtree(subject_folder)
            print(f"Deleted folder: {subject_folder}")
        except Exception as e:
            print(f"Error deleting {subject_folder}: {e}")
    else:
        print(f"Subject folder does not exist: {subject_folder}")

    # Delete the log files
    for log_file in [log_out, log_err]:
        if os.path.exists(log_file):
            try:
                os.remove(log_file)
                print(f"Deleted log file: {log_file}")
            except Exception as e:
                print(f"Error deleting {log_file}: {e}")
        else:
            print(f"Log file does not exist: {log_file}")

    print(f"Cleanup completed for subject {subject_id}.")



def process_single_subject(step_name, subject_id, root_dir, script_paths, logs_dir, check_interval):
    """
    Submits a single job for a specific step and waits for its completion.

    Parameters:
        step_name (str): The step to run (e.g., "step_1", "step_2", etc.).
        subject_id (str): The subject ID to process.
        root_dir (str): Root directory for processing.
        script_paths (dict): Dictionary containing script paths for different steps.
        logs_dir (str): Directory for log files.
        check_interval (int): Time in seconds between job status checks.
    """
    if step_name not in script_paths:
        print(f"Error: Step {step_name} is not recognized.")
        return

    script_path = script_paths[step_name]

    print(f"Processing {step_name} for subject {subject_id}")

    # Define log paths for the subject
    log_err = os.path.join(logs_dir, f"job_{subject_id}_{step_name}.err")

    # Submit job
    job_id = submit_job(subject_id, log_err, log_err, script_path, root_dir, email="")

    if job_id:
        print(f"Job {job_id} for subject {subject_id} submitted successfully.")
        wait_for_job_completion(job_id, check_interval)
    else:
        print(f"Failed to submit job for subject {subject_id} in {step_name}.")


# Function to process subjects in batches
def process_subjects_in_batches(step_name, subjects, root_dir, batch_size,script_paths,logs_dir,check_interval,email=""):
    """Submits jobs in batches and waits for completion."""
    script_path = script_paths[step_name]
    job_ids = []

    for i in range(0, len(subjects), batch_size):
        batch = subjects[i:i + batch_size]
        for subject_id in batch:
            print(f"Processing {step_name} for subject {subject_id}")


            # Define err paths for the subject
            log_err_template = f"/{logs_dir}/sub_{subject_id}_{step_name}.err"


            # Submit job
            job_id = submit_job(subject_id, log_err_template, log_err_template, script_path, root_dir,
                                email=email)

            if job_id:
                job_ids.append(job_id)
            else:
                print(f"Failed to submit job for subject {subject_id}")

        # Wait for the current batch of jobs to complete before moving to the next batch
        for job_id in job_ids:
            wait_for_job_completion(job_id, check_interval)

        job_ids.clear()  # Clear job IDs for the next batch