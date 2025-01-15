

df <- read.csv("krakow_id_correspondance.csv")

#freesurfer folder
free_surfer <- "//hyades00.pet.auh.dk/projects/MINDLAB2016_MR-SensCogFromNeural/scratch/timo/krakow_rsfmri_raw/freesurfer"

sub_names <- list.dirs(free_surfer, full.names = FALSE, recursive = FALSE)
cleaned_sub_names <- gsub("^sub-", "", sub_names[grep("^sub-", sub_names)])
# these are the subs we have freesurfer on


# Remove the first line
df <- df[-1, ]

# Rename the columns
names(df)[names(df) == "Name."] <- "storm_db_id"
names(df)[names(df) == "KrakowID.."] <- "krakow_id"

# Remove "Subject " from 'storm_db_id' and "Â " from 'krakow_id'
df$storm_db_id <- gsub("Subject ", "", df$storm_db_id)
df$krakow_id <- gsub("Â ", "", df$krakow_id)
df$krakow_id <- substr(df$krakow_id, 2, nchar(df$krakow_id))
# Display the cleaned data
df <- subset(df,df$Comments != "pilot",select=c("storm_db_id","krakow_id"))

df <- subset(df,df$krakow_id %in% cleaned_sub_names)


write.csv(df,"krakow_id_correspondance_clean.csv")


