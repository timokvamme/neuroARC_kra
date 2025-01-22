
import subprocess


def submit_job(subject_id, job_name_template, log_out_template, log_err_template, script_path, scratch_dir, email=""):
    """
    Submits a job to the cluster for the given subject ID with customizable parameters.
    Optionally sends an email notification upon job completion if an email is provided.
    """
    job_name = job_name_template.format(subject_id=subject_id)
    log_out = log_out_template.format(subject_id=subject_id)
    log_err = log_err_template.format(subject_id=subject_id)

    qsub_path = "/usr/local/common/GridEngine/bin/lx-amd64/qsub"

    # Prepare the submission command
    submit_command = [
        qsub_path,
        "-q", "long.q",
        "-o", log_out,
        "-e", log_err,
        "-N", job_name,
        "-b", "y",
    ]

    # Add email notification if provided
    if email:
        submit_command.extend(["-M", email, "-m", "bea"])  # Send mail at begin, end, and abort

    # Add the actual bash command to run the pipeline
    submit_command.extend([
        "/bin/bash", "-c",
        f"source /users/timo/anaconda3/etc/profile.d/conda.sh && conda activate mrtrix && {script_path} {subject_id} {scratch_dir}"
    ])

    try:
        result = subprocess.run(submit_command, capture_output=True, text=True, check=True)
        print(f"Job for subject {subject_id} submitted successfully.")
        print("Submission Output:\n", result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error submitting job for subject {subject_id}:\n", e.stderr)
    except FileNotFoundError:
        print("Error: Could not find the qsub command. Make sure Grid Engine is installed and available.")



def check_job_status():
    """
    Checks the status of submitted jobs in the queue.
    """
    qstat_path = "/usr/local/common/GridEngine/bin/lx-amd64/qstat"

    try:
        result = subprocess.run([qstat_path], capture_output=True, text=True, check=True)
        print("Current job status:\n")
        print(result.stdout)
    except subprocess.CalledProcessError as e:
        print("Error checking job status:\n", e.stderr)
    except FileNotFoundError:
        print(f"Error: Could not find qstat at {qstat_path}")
