all: data-raw/fieldsdf.csv README.md doc vig test
.PHONY: clean

# Pull endpoint fields from PatentsView website
data-raw/fields.csv: data-raw/fieldsdf.R
	Rscript -e "source('data-raw/fieldsdf.R')"

# Compile patentsview vignette into README.md
README.md: vignettes/patentsview.Rmd
	Rscript -e "rmarkdown::render('vignettes/patentsview.Rmd', output_file = 'README.md', output_dir = getwd(), output_format = 'github_document', quiet = TRUE, params = list(eval_all = TRUE))"
	Rscript -e "file.remove('README.html')"

# Document package
doc:
	Rscript -e "devtools::document()"

# Compile vignettes
vig: inst/doc/writing-queries.html inst/doc/patentsview.html

inst/doc/writing-queries.html: vignettes/writing-queries.Rmd
	Rscript -e "devtools::build_vignettes()"

inst/doc/patentsview.html: vignettes/patentsview.Rmd
	Rscript -e "devtools::build_vignettes()"

# Test package
test:
	Rscript -e "library(testthat); library(patentsview); \
	test_dir('tests/testthat/'); test_examples('man')"

# Clean
clean:
	rm -R README.md inst/doc