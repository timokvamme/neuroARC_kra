import nibabel as nib
import numpy as np
import os
import matplotlib.pyplot as plt
import imageio
from nilearn.plotting import plot_anat

# Define paths
subject_id = "0051"
root_dir = "/projects/2022_MR-SensCogGlobal/scratch/results/mrtrix3"
log_dir = "/projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/qc_logs"
os.makedirs(log_dir, exist_ok=True)

# Define image paths
img1_path = os.path.join(root_dir, f"sub-{subject_id}", "sub-0051_run-01_T1w_brain.nii.gz")
img2_path = os.path.join(root_dir, f"sub-{subject_id}", "sub-0051_run-01_mean_b0_brain.nii.gz")
gif_file = os.path.join(log_dir, f"qc_overlap_sub-{subject_id}.gif")

# Load images
img1 = nib.load(img1_path)
img2 = nib.load(img2_path)

# Get data arrays
data1 = img1.get_fdata()
data2 = img2.get_fdata()

# Ensure both images have the same shape
if data1.shape != data2.shape:
    raise ValueError("Image dimensions do not match! Consider resampling.")

# Generate GIF frames
frames = []
slices = np.linspace(10, data1.shape[2] - 10, 20).astype(int)
for z in slices:
    fig, ax = plt.subplots(figsize=(6, 6))
    plot_anat(img1_path, cut_coords=[0, 0, z], display_mode='ortho', annotate=False, axes=ax)
    plot_anat(img2_path, cut_coords=[0, 0, z], display_mode='ortho', alpha=0.5, cmap='Reds', annotate=False, axes=ax)
    fig.canvas.draw()
    frame = np.array(fig.canvas.renderer.buffer_rgba())
    frames.append(frame)
    plt.close(fig)

# Save as GIF
imageio.mimsave(gif_file, frames, duration=0.3)

print(f"GIF saved to {gif_file}")
