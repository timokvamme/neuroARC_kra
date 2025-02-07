# Frontoparietal network topology as a neuromarker of music perceptual abilities

## Overview

This repository hosts a suite of Bash scripts developed for processing diffusion-weighted MRI (dMRI) data and constructing structural connectomes using MRtrix3 and FSL. These tools are part of the NeurArchCon project, led by Claude Julien Bajada (claude.bajada@um.edu.mt). The conversion from Desikan to Destrieux atlas was performed by Hao Chen. The scripts for the CFIN preprocessing pipeline are available upon request. All scripts are fully commented to ensure ease of replication and understanding

## Software requirements

The following software packages are required to run the scripts:

- **FSL**: A comprehensive suite for FMRI, MRI, and dMRI data analysis [Installation guide](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation)
- **MRtrix3**: MRtrix3 provides a set of tools to perform various types of diffusion MRI analyses [Installation instructions](https://www.mrtrix.org/)
- **Freesurfer**: An open-source package for neuroimaging data analysis and visualization. [Installation guide](https://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall)

## Usage

The pipeline consists of six main scripts that should be run in the following order:

1. ``mrtrix_pipeline_step_1.sh``: Initiates MRtrix3 processing on diffusion MRI data from the CFIN pipeline, converting and co-registering images, generating a 5-tissue-type segmentation for ACT, and aligning structural images with diffusion data. It ensures diffusion and structural data are prepared for advanced tractography analysis.
2. ``mrtrix_pipeline_step_2.sh``: Computes the group average response functions for white matter, gray matter, and CSF.
3. ``mrtrix_pipeline_step_3.sh``: Implements multi-shell multi-tissue constrained spherical deconvolution (MSMT-CSD), normalizes the fiber orientation distributions (FODs) for WM, GM, and CSF, and performs tractography.
4. ``mrtrix_pipeline_step_4_mu_coeff.sh``: Applies the SIFT2 method to reduce false-positive connections and generates metrics such as the mean streamline weight (-out_mu) and streamline coefficients (-out_coeffs), offering quantitative insights into the tractogram's composition and the filtering process's impact.
5. ``mrtrix_pipeline_step_5_connectome_gen.sh``: Create structural connectomes using the Desikan parcelation.
6. ``gen_connectome.sh`` and ``gen_connectome_all.sh``:Convert structural connectomes of all participants from the Desikan to the Destriex atlas.


## Demo

To run the pipeline, follow these steps:

1. Clone this repository to your local machine
2. Navigate to the cloned repository
3. Run the scripts in the following order, replacing ‘$SUBJECTS’ and ‘$ROOT_DIR’ with the appropriate names for your data

```
bash mrtrix_pipeline_step_1.sh $SUBJECT $ROOT_DIR
bash mrtrix_pipeline_step_2.sh $SUBJECT $ROOT_DIR
bash mrtrix_pipeline_step_3.sh $SUBJECT $ROOT_DIR
bash mrtrix_pipeline_step_4_mu_coeff.sh $SUBJECT $ROOT_DIR
bash mrtrix_pipeline_step_5_connectome_gen.sh $SUBJECT $ROOT_DIR
bash gen_connectome_all.sh
```
### Troubleshooting

If you encounter issues, check the following:

- Software dependencies are correctly installed and updated.
- Input data formats meet the expected specifications.
- System resources (memory, CPU) are sufficient for processing.

For further assistance, contact claude.bajada@um.edu.mt & timokvamme@gmail.com (steps 1-5) or Hao Chen (step 6) 

