all: data-raw/fieldsdf.csv readme_all doc vig test
dev: data-raw/fieldsdf.csv readme_dev doc vig test
.PHONY: clean

# Pull endpoint fields from PatentsView website
data-raw/fields.csv: data-raw/fieldsdf.R
	Rscript -e "source('data-raw/fieldsdf.R')"

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

# Test package
test:
	Rscript -e "library(testthat); library(patentsview); \
	test_dir('tests/testthat/'); test_examples('man')"

# Clean
clean:
	rm README.md inst/doc/writing-queries.html