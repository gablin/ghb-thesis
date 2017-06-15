# Copyright (c) 2017, Gabriel Hjort Blindell <ghb@kth.se>
#
# This work is licensed under a Creative Commons 4.0 International License (see
# LICENSE file or visit <http://creativecommons.org/licenses/by/4.0/> for a copy
# of the license).

SRCTEX  := dissertation.tex
SRCPDF  := $(SRCTEX:.tex=.pdf)
LATEX   := latex
LATEXMK := latexmk
OKAY_TEXLIVE_VERSION := 2016

.PHONY: $(SRCPDF)
$(SRCPDF): check-environment
	$(LATEXMK) -pdf $(SRCTEX)

.PHONY: clean
clean:
	$(LATEXMK) -c $(SRCTEX)
	$(RM) *.c
	$(RM) *.glg *.glo *.gls *.ist

.PHONY: distclean
distclean:
	$(LATEXMK) -C $(SRCTEX)

.PHONY: check-environment
check-environment:
	@echo -n "Checking environment... "
	@if [ -z `which $(LATEX)` ]; then \
		echo; \
		echo "ERROR: $(LATEX) not installed"; \
		echo; \
		exit 1; \
	fi
	@if [ -z `which $(LATEXMK)` ]; then \
		echo; \
		echo "ERROR: $(LATEXMK) not installed"; \
		echo; \
		exit 1; \
	fi
	@LATEX_VERSION=`$(LATEX) --version | head -n1 | grep "TeX Live"` && \
	if [ -z "$(TEXLIVECHECK)" ] && [ -z "$$LATEX_VERSION" ]; then \
		echo; \
		echo "WARN: Tex Live not installed"; \
		echo "Set TEXLIVECHECK=false to disable this check."; \
		echo; \
		exit 1; \
	fi && \
	TEXLIVE_VERSION=`echo "$$LATEX_VERSION" | \
					 sed 's/.*TeX Live //' | \
					 sed 's/).*//'` && \
	if [ -z "$(TEXLIVECHECK)" ] && \
	   [ $$TEXLIVE_VERSION -lt $(OKAY_TEXLIVE_VERSION) ]; then \
		echo; \
		echo -n "WARN: too old Tex Version "; \
	    echo "(found $$TEXLIVE_VERSION, expected >= $(OKAY_TEXLIVE_VERSION))"; \
		echo "Set TEXLIVECHECK=false to disable this check."; \
		echo; \
		exit 1; \
	fi
	@echo "OK"

