# Copyright (c) 2017, Gabriel Hjort Blindell <ghb@kth.se>
#
# This work is licensed under a Creative Commons 4.0 International License (see
# LICENSE file or visit <http://creativecommons.org/licenses/by/4.0/> for a copy
# of the license).

SRCTEX   := ghb-thesis.tex
SRCPDF   := $(SRCTEX:.tex=.pdf)
LATEX    := latex
LATEXMK  := latexmk -pdflatex=lualatex -recorder -use-make -deps
OKAY_TEXLIVE_VERSION := 2016
DEPS_DIR := .deps

GEN_PRIN_TIMELINE_SCRIPT := scripts/generate-principles-timeline
GEN_PRIN_TIMELINE_STYLE_FILE := \
    figures/existing-isel-techniques-and-reps/principles-timeline-styles.tex
PRIN_TIMELINE_FILE := \
    figures/existing-isel-techniques-and-reps/principles-timeline.tex
BIB_FILE := references.bib

-include $(DEPS_DIR)/$(SRCTEX).d

$(DEPS_DIR):
	mkdir $@

$(SRCPDF): check-environment $(DEPS_DIR)
	$(LATEXMK) -pdf -deps-out=$(DEPS_DIR)/$(SRCTEX).d $(SRCTEX)

.PHONY: clean
clean:
	$(LATEXMK) -c $(SRCTEX)
	$(RM) -r $(DEPS_DIR)
	$(RM) $(PRIN_TIMELINE_FILE)
	$(RM) *.c

.PHONY: distclean
distclean: clean
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

$(PRIN_TIMELINE_FILE): $(BIB_FILE) \
                       $(GEN_PRIN_TIMELINE_SCRIPT) \
                       $(GEN_PRIN_TIMELINE_STYLE_FILE)
	$(GEN_PRIN_TIMELINE_SCRIPT) $(BIB_FILE) > $@
