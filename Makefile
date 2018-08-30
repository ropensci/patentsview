all: data-raw/fieldsdf.csv doc README.md vig test

# Pull endpoint fields from PatentsView website
data-raw/fields.csv: data-raw/fieldsdf.R
	Rscript -e "source('data-raw/fieldsdf.R')"

# Render README.Rmd to README.md
README.md: README.Rmd
	- Rscript -e "rmarkdown::render('README.Rmd', output_file = 'README.md', output_dir = getwd(), output_format = 'github_document', quiet = TRUE)"
	- Rscript -e "file.remove('README.html')"
ifeq ($(CRAN),true)

else
	echo "[![ropensci\_footer](http://ropensci.org/public_images/github_footer.png)](http://ropensci.org)" >> README.md
endif

# Document package
doc:
	Rscript -e "devtools::document()"

# Compile vignettes
vig: vignettes/*
	Rscript -e "devtools::build_vignettes()"

# Test package
test:
	Rscript -e "devtools::test()"

# Build site (not part of all)
site: _pkgdown.yml inst/site/*
	Rscript -e "source('inst/site/build-site.R'); build_site()"

# Clean
clean:
	rm -R README.md inst/doc docs

.PHONY: doc test clean
