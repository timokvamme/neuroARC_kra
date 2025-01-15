

df <- read.csv("C:/code/projects/mi/analyses/aim1/kra_struct_connectome_tractography/krakow_id_correspondance.csv")


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

write.csv(df,"C:/code/projects/mi/analyses/aim1/kra_struct_connectome_tractography/krakow_id_correspondance_clean.csv")


