#NAME
#	Reproducible Builds for Computational Research Papers Makefile help.
#
#SEE ALSO
#	https://github.com/pbizopoulos/cookiecutter-reproducible-builds-for-computational-research-papers
#	https://github.com/pbizopoulos/reproducible-builds-for-computational-research-papers
#
#SYNTAX
#	make [OPTION] [ARGS=--full]
#
#USAGE
# 
#	+-------------------+----------------------+---------------------------+
#	|         \ ARGS    |       (empty)        |          --full           |
#	|   OPTION \        |                      |                           |
#	+-------------------+----------------------+---------------------------+
#	| (ms.pdf or empty) |  debug/development   |       release paper       |
#	+-------------------+----------------------+---------------------------+
#	|       test        | test reproducibility | test reproducibility full |
#	+-------------------+----------------------+---------------------------+
#
#OPTIONS

.POSIX:

ARGS=
GPU=--gpus all
INTERACTIVE=-it

ms.pdf: ms.tex ms.bib results/.completed # Generate pdf.
	docker run --rm \
		--user $(shell id -u):$(shell id -g) \
		-v $(PWD):/home/latex \
		ghcr.io/pbizopoulos/texlive-full \
		latexmk -usepretex="\pdfinfoomitdate=1\pdfsuppressptexinfo=-1\pdftrailerid{}" -gg -pdf -cd /home/latex/ms.tex

results/.completed: Dockerfile $(shell find . -maxdepth 1 -name '*.py')
	rm -rf results/* results/.completed
	docker build -t comprehensive-comparison-of-deep-learning-models-for-lung-and-covid-19-lesion-segmentation-in-ct .
	docker run --rm $(INTERACTIVE) \
		--user $(shell id -u):$(shell id -g) \
		-w /usr/src/app \
		-e HOME=/usr/src/app/cache \
		-v $(PWD):/usr/src/app \
		 $(GPU)  comprehensive-comparison-of-deep-learning-models-for-lung-and-covid-19-lesion-segmentation-in-ct \
		python3 main.py $(ARGS)
	touch results/.completed

test: # Test whether the paper has a reproducible build.
	make clean && make ARGS=$(ARGS) GPU="$(GPU)" INTERACTIVE= && mv ms.pdf tmp.pdf
	make clean && make ARGS=$(ARGS) GPU="$(GPU)" INTERACTIVE= 
	@diff ms.pdf tmp.pdf && echo 'ms.pdf has a reproducible build.' || echo 'ms.pdf has not a reproducible build.'
	@rm tmp.pdf

clean: # Remove cache, results directories and tex auxiliary files.
	rm -rf __pycache__/ cache/* results/* results/.completed ms.bbl
	docker run --rm \
		--user $(shell id -u):$(shell id -g) \
		-v $(PWD):/home/latex \
		ghcr.io/pbizopoulos/texlive-full \
		latexmk -C -cd /home/latex/ms.tex

help: # Show help.
	@grep '^#' Makefile | cut -b 2-
	@grep -E '^[a-z.-]*:.*# .*$$' Makefile | awk 'BEGIN {FS = ":.*# "}; {printf "\t%-6s - %s\n", $$1, $$2}'