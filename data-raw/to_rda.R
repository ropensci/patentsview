library(devtools)

# Read and save fieldsdf.csv, as if fieldsdf.R worked
fieldsdf <- read.csv("fieldsdf.csv", header = TRUE, sep = ",")

use_data(fieldsdf, internal = FALSE, overwrite = TRUE)
use_data(fieldsdf, internal = TRUE, overwrite = TRUE)
