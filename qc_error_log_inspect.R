

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







