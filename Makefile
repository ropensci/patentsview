# Adapted from https://github.com/r-pkgs/functionmap2/blob/master/Makefile

all: README.md

README.md: README.Rmd
	Rscript -e "library(knitr); knit('README.Rmd', output = 'README.md', quiet = TRUE)"