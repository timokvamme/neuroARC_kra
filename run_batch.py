import subprocess
import sys

# Get command-line arguments
subject = sys.argv[1]
root_dir = sys.argv[2]

print(f'Processing subject: {subject}')

# Run the processing command (update as needed)
processing_script = "mrtrix_pipeline_step_1_test.sh"
subprocess.run([f"./{processing_script}", subject, root_dir], check=True)

print(f'Completed processing for subject: {subject}')