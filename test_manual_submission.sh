qsub -q long.q \
     -o "/projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/logs/job_0004.out" \
     -e "/projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/logs/job_0004.err" \
     -N "job_0004" \
     -v SUBJECT="0004",JOB_SCRIPT="mrtrix_pipeline_step_1_test.sh" \
     submit_job.sh