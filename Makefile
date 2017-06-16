all: data-raw/fieldsdf.csv doc README.md vig test
.PHONY: clean

# Pull endpoint fields from PatentsView website
data-raw/fields.csv: data-raw/fieldsdf.R
	Rscript -e "source('data-raw/fieldsdf.R')"

# Compile patentsview vignette into README.md
README.md: vignettes/patentsview.Rmd
	Rscript -e "rmarkdown::render('vignettes/patentsview.Rmd', output_file = 'README.md', output_dir = getwd(), output_format = 'github_document', quiet = TRUE, params = list(eval_all = TRUE))"
	Rscript -e "file.remove('README.html')"
	echo "[![ropensci\_footer](http://ropensci.org/public_images/github_footer.png)](http://ropensci.org)" >> README.md

# Document package
doc:
	Rscript -e "devtools::document()"

# Compile vignettes
vig: vignettes/writing-queries.Rmd vignettes/patentsview.Rmd
	Rscript -e "devtools::build_vignettes()"

# Test package
test:
	Rscript -e "library(testthat); library(patentsview); \
	devtools::test(); test_examples('man')"

# Clean
clean:
	rm -R README.md inst/doc