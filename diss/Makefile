SRCTEX := dissertation.tex
SRCPDF := $(SRCTEX:.tex=.pdf)
LATEXMK := latexmk

.PHONY: $(SRCPDF)
$(SRCPDF):
	$(LATEXMK) -pdf $(SRCTEX)

.PHONY: clean
clean:
	$(LATEXMK) -c $(SRCTEX)

.PHONY=distclean
distclean:
	$(LATEXMK) -C $(SRCTEX)
