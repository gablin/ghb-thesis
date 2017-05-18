% Copyright (c) 2017, Gabriel Hjort Blindell <ghb@kth.se>
%
% This work is licensed under a Creative Commons 4.0 International License (see
% LICENSE file or visit <http://creativecommons.org/licenses/by/4.0/> for a copy
% of the license).

\NeedsTeXFormat{LaTeX2e}[2001/01/01]
\ProvidesClass{kthdiss}[2017/05/09 v0.1 Document class for KTH dissertations]

% Pass on undeclared options to memoir class
\DeclareOption*{%
  \PassOptionsToClass{\CurrentOption}{memoir}%
}
\ProcessOptions\relax

\LoadClass{memoir}



%===============
% LOAD PACKAGES
%===============

\RequirePackage{xparse}



%===========================
% DOCUMENT STRUCTURE MACROS
%===========================

\makepagestyle{frontMatterChapPage}
\makeevenhead{frontMatterChapPage}{\thepage}{}{}
\makeoddhead{frontMatterChapPage}{}{}{\thepage}
\NewDocumentEnvironment{frontMatterChap}{m}{%
  \clearpage%
  \markboth{#1}{#1}%
  \thispagestyle{frontMatterChapPage}%
  \begin{center}%
    \large\textbf{#1}%
  \end{center}%
}{}

\RenewDocumentEnvironment{abstract}{}{%
  \begin{frontMatterChap}{Abstract}%
}{
  \end{frontMatterChap}
}

\NewDocumentEnvironment{sammanfattning}{}{%
  \begin{frontMatterChap}{Sammanfattning}%
}{
  \end{frontMatterChap}
}

\NewDocumentEnvironment{acknowledgements}{}{%
  \begin{frontMatterChap}{Acknowledgements}%
}{
  \end{frontMatterChap}
}

\NewDocumentCommand{\makeListOfCommand}{mmmm}{%
  \DeclareDocumentCommand{#1}{s}{%
    \begingroup%
    \renewcommand{\cleardoublepage}{\clearpage}%
    \chapter*{#2}%
    \markboth{#2}{#2}%
    \endgroup%
    \@mkboth{#2}{#2}%
    \IfBooleanF{##1}{%
      \addcontentsline{toc}{#4}{#2}%
    }%
    \@starttoc{#3}%
  }%
}

\makeListOfCommand{\tableofcontents}{\contentsname}{toc}{chapter}
\makeListOfCommand{\listoffigures}{\listfigurename}{lof}{chapter}
\makeListOfCommand{\listoftables}{\listtablename}{lot}{chapter}
