all: data-raw/fieldsdf.csv doc README.md test

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

doc:
	Rscript -e "devtools::document()"

test:
	Rscript -e "devtools::test()"

# Build pkgdown site
site:
	Rscript -e "source('vignettes/build.R'); build_site_locally()"

# "Half-render" the vigenttes for the ROpenSci builds. See the README in
# the vignettes directory for details.
half-render:
	Rscript -e "source('vignettes/build.R'); half_render_vignettes()"

clean:
	rm -R README.md inst/doc docs

.PHONY: doc test clean
