Diploma thesis - LaTeX source package
=====================================
Files:
  diploma.tex     - full LaTeX source of the thesis
  images/         - all 16 figures/screenshots used by the document

How to compile (XeLaTeX recommended - renders Latin + Cyrillic):
  xelatex diploma.tex
  xelatex diploma.tex      (run 2-3 times for the table of contents and references)
  xelatex diploma.tex

It also compiles with pdfLaTeX (Latin text only; Cyrillic glyphs require XeLaTeX).
