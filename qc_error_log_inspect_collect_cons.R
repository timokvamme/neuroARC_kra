
# this checks qc on the connectomes and moves the connectomes to the results folder
# this was results was moved to MINDLAB2016_MR-SensCogFromNeural\scratch\timo\krakow_struct_mrtrix_results



library(ggplot2)
log_file_path <- "//hyades00.pet.auh.dk/projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/qc_logs/qc_summary_24_02_2025.csv"

correspondance <- read.csv("//hyades00.pet.auh.dk/projects/2022_MR-SensCogGlobal/scripts/neuroARC_kra/krakow_id_correspondance_clean.csv")

df <- read.csv(log_file_path)
df$error_note <- ifelse(df$error_note == "", "no error", df$error_note)
table(df$error_note)




# format X which is id, with leading 4 zeroes
df$scanner_id <- sprintf("%04d", df$X)
# remove X
df <- df[, -1]

df$storm_db_id <- df$scanner_id

names(correspondance)
correspondance$storm_db_id <- sprintf("%04d", correspondance$storm_db_id)
df <- merge(df,correspondance,by.x = "storm_db_id",all.x = TRUE)

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
for (i in seq_along(df$scanner_id)) {
  scanner_id <- df$scanner_id[i]
  krakow_id <- df$krakow_id[i]  # Use Krakow ID for folder names
  error_status <- df$error_note[i]

  # Skip if krakow_id is missing
  if (is.na(krakow_id)) {
    warning(paste0("Missing Krakow ID for scanner_id ", scanner_id, ". Skipping."))
    next
  }

  # Define source files using scanner_id
  connectome_file <- file.path(connectome_dir, paste0("sub-", scanner_id), paste0("sub-", scanner_id, "_run-01_connectome.csv"))
  mu_file <- file.path(connectome_dir, paste0("sub-", scanner_id), paste0("sub-", scanner_id, "_run-01_10M_prob.mu"))

  # Define subject folder using Krakow ID
  subject_output_dir <- ifelse(error_status == "streamline error",
                               file.path(streamline_error_dir, paste0("sub-", krakow_id)),
                               file.path(output_dir, paste0("sub-", krakow_id)))

  # Create subject folder if it doesn't exist
  dir_create(subject_output_dir, recurse = TRUE)

  # Move and rename files if they exist
  if (file_exists(connectome_file)) {
    new_connectome_file <- file.path(subject_output_dir, paste0("sub-", krakow_id, "_run-01_connectome.csv"))
    file_copy(connectome_file, new_connectome_file, overwrite = TRUE)
  } else {
    warning(paste0("No connectome file found for subject ", krakow_id, " (Scanner ID: ", scanner_id, ")"))
  }

  if (file_exists(mu_file)) {
    new_mu_file <- file.path(subject_output_dir, paste0("sub-", krakow_id, "_run-01_10M_prob.mu"))
    file_copy(mu_file, new_mu_file, overwrite = TRUE)
  } else {
    warning(paste0("No mu file found for subject ", krakow_id, " (Scanner ID: ", scanner_id, ")"))
  }
}

print("Files have been renamed, moved, and organized successfully.")



# moved to MINDLAB2016_MR-SensCogFromNeural\scratch\timo\krakow_struct_mrtrix_results using python
# import shutilx
# source = "/projects/2022_MR-SensCogGlobal/scratch/results/mrtrix3_final_connectome_destrieux"
# destination = "/projects/MINDLAB2016_MR-SensCogFromNeural/scratch/timo/krakow_struct_mrtrix_results"


