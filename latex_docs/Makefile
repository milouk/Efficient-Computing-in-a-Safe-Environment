all: ecse

ecse: ecse19.tex
	pdflatex $<
	bibtex $(basename $<)
	pdflatex $<
	pdflatex $<

clean:
	-rm *.aux *.bbl *.blg *.log *.out *.gz ecse19.pdf
