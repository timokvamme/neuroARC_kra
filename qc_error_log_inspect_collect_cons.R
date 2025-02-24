
# this checks qc on the connectomes and moves the connectomes to the results folder
# this was results was moved to MINDLAB2016_MR-SensCogFromNeural\scratch\timo\krakow_struct_mrtrix_results



library(ggplot2)
log_file_path <- "//hyades00.pet.auh.dk/projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/qc_logs/qc_summary_24_02_2025.csv"

df <- read.csv(log_file_path)
df$error_note <- ifelse(df$error_note == "", "no error", df$error_note)
table(df$error_note)

# format X which is id, with leading 4 zeroes
df$scanner_id <- sprintf("%04d", df$X)
# remove X
df <- df[, -1]

dfc <- df

# compare zum_zeros between no eror and streamline error
mean(dfc$num_zeros[dfc$error_note == "no error"],na.rm = TRUE)
sd(dfc$num_zeros[dfc$error_note == "no error"],na.rm = TRUE)
max(dfc$num_zeros[dfc$error_note == "no error"],na.rm = TRUE)
mean(dfc$num_zeros[dfc$error_note == "streamline error"],na.rm=TRUE)
sd(dfc$num_zeros[dfc$error_note == "streamline error"],na.rm=TRUE)
min(dfc$num_zeros[dfc$error_note == "streamline error"],na.rm=TRUE)

# compare zum_zeros between no eror and streamline error with a density plot
ggplot(dfc, aes(x=num_zeros, fill=error_note)) +
  geom_density(alpha=0.5) +
  theme_minimal()





library(fs)  # For file operations
library(dplyr)

# Define paths
connectome_dir <- "//hyades00.pet.auh.dk/projects/2022_MR-SensCogGlobal/scratch/results/mrtrix3"
output_dir <- "//hyades00.pet.auh.dk/projects/2022_MR-SensCogGlobal/scratch/results/mrtrix3_final_connectome_destrieux"
streamline_error_dir <- file.path(output_dir, "streamline_error")

# Create main output directories if they don't exist
dir_create(output_dir, recurse = TRUE)
dir_create(streamline_error_dir, recurse = TRUE)

# Iterate over subjects
for (i in seq_along(dfc$scanner_id)) {
  subject <- dfc$scanner_id[i]
  error_status <- dfc$error_note[i]

  # Define source files
  connectome_file <- file.path(connectome_dir, paste0("sub-", subject), paste0("sub-", subject, "_run-01_connectome.csv"))
  mu_file <- file.path(connectome_dir, paste0("sub-", subject), paste0("sub-", subject, "_run-01_10M_prob.mu"))

  # Choose the correct destination folder
  subject_output_dir <- ifelse(error_status == "streamline error",
                               file.path(streamline_error_dir, paste0("sub-", subject)),
                               file.path(output_dir, paste0("sub-", subject)))

  # Create subject folder if it doesn't exist


  # Move files if they exist
  if (file_exists(connectome_file)) {
    dir_create(subject_output_dir, recurse = TRUE)
    file_copy(connectome_file, subject_output_dir, overwrite = TRUE)
  } else {
    warning(paste0("No connectome file found for subject ", subject))
  }


  if (file_exists(mu_file)) {
    file_copy(mu_file, subject_output_dir, overwrite = TRUE)
  } else {
    warning(paste0("No mu file found for subject ", subject))
  }

}

print("Files have been moved and organized successfully.")




# moved to MINDLAB2016_MR-SensCogFromNeural\scratch\timo\krakow_struct_mrtrix_results using python
# import shutilx
# source = "/projects/2022_MR-SensCogGlobal/scratch/results/mrtrix3_final_connectome_destrieux"
# destination = "/projects/MINDLAB2016_MR-SensCogFromNeural/scratch/timo/krakow_struct_mrtrix_results"


