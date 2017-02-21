all: data-raw/fields.csv readme_all doc vig
dev: data-raw/fields.csv readme_dev doc vig
.PHONY: clean

# Pull endpoint fields from PatentsView website
data-raw/fields.csv: data-raw/fields.R
	Rscript -e "source('data-raw/fields.R')"

# Compile README
readme_all: README.Rmd
	Rscript -e "rmarkdown::render('README.Rmd', quiet = TRUE, params = list(eval_all = TRUE))"

readme_dev: README.Rmd
	Rscript -e "rmarkdown::render('README.Rmd', quiet = TRUE)"

# Document package
doc:
	Rscript -e "devtools::document()"

# Compile vignette
vig: inst/doc/writing-queries.html

inst/doc/writing-queries.html: vignettes/writing-queries.Rmd
	Rscript -e "devtools::build_vignettes()"

# Clean
clean:
	rm README.md inst/doc/writing-queries.html