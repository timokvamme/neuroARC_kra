

# THIS WORKED!!! .. mr convert works, but thats it. didnt test more
qsub -q long.q \
     -o /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/logs/job_0005.out \
     -e /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/logs/job_0005.err \
     -b y /bin/bash -c "source /users/timo/anaconda3/etc/profile.d/conda.sh && conda activate mrtrix && /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/mrtrix_pipeline_step_1_test.sh 0005 /projects/2022_MR-SensCogGlobal/scratch"

# to check
cat /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/logs/job_0005.out
cat /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/logs/job_0005.err


# non test: - still issues after some times --- i figured
qsub -q long.q \
  -o /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/logs/job_0005.out \
  -e /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/logs/job_0005.err \
  -N job_0005_step1.sh \
  -b y /bin/bash -c "source /users/timo/anaconda3/etc/profile.d/conda.sh && conda activate mrtrix && /projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/mrtrix_pipeline_step_1.sh 0005 /projects/2022_MR-SensCogGlobal/scratch"


