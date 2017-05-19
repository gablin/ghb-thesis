% Copyright (c) 2017, Gabriel Hjort Blindell <ghb@kth.se>
%
% This work is licensed under a Creative Commons 4.0 International License (see
% LICENSE file or visit <http://creativecommons.org/licenses/by/4.0/> for a copy
% of the license).

\NeedsTeXFormat{LaTeX2e}[2001/01/01]
\ProvidesClass{kthdiss}[2017/05/09 v0.1 Document class for KTH dissertations]

%=========
% OPTIONS
%=========

% Declare options
\newif\if@kthdiff@electronic \@kthdiff@electronicfalse
\DeclareOption{electronic}{\@kthdiff@electronictrue}
\DeclareOption{g5paper}{\def\kthdiff@trimmedsize{gfive}}
\DeclareOption{a3paper}{\PackageError{kthdiff}{'a3paper' format not supported}}
\DeclareOption{a4paper}{\def\kthdiff@trimmedsize{afour}}
\DeclareOption{a5paper}{\PackageError{kthdiff}{'a5paper' format not supported}}
\DeclareOption{a6paper}{\PackageError{kthdiff}{'a6paper' format not supported}}
\DeclareOption{b3paper}{\PackageError{kthdiff}{'b3paper' format not supported}}
\DeclareOption{b4paper}{\PackageError{kthdiff}{'b4paper' format not supported}}
\DeclareOption{b5paper}{\PackageError{kthdiff}{'b5paper' format not supported}}
\DeclareOption{b6paper}{\PackageError{kthdiff}{'b6paper' format not supported}}
\DeclareOption{letterpaper}{%
  \PackageError{kthdiff}{'letterpaper' format not supported}%
}
\DeclareOption{legalpaper}{%
  \PackageError{kthdiff}{'legalpaper' format not supported}%
}
\DeclareOption{executivepaper}{%
  \PackageError{kthdiff}{'executivepaper' format not supported}%
}
\DeclareOption{ebook}{\PackageError{kthdiff}{'ebook' format not supported}}
\DeclareOption{landscape}{%
  \PackageError{kthdiff}{'landscape' format not supported}%
}

% Pass on undeclared options to memoir class
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{memoir}}

% Default options
\ExecuteOptions{g5paper}

\ProcessOptions\relax

\LoadClass{memoir}

% Set margins
\def\@kthdiff@setpapersize@afour{%
  \setstocksize{297mm}{210mm}
  \settrimmedsize{297mm}{210mm}{*}
  \settypeblocksize{49pc}{33pc}{*}
}
\def\@kthdiff@setpapersize@gfive{%
  \if@kthdiff@electronic
    \setstocksize{239mm}{169mm}
    \settrimmedsize{239mm}{169mm}{*}
    \ifpdf
    \else
      \special{papersize=169mm,239mm}
    \fi
  \else
    \setstocksize{297mm}{210mm}
    \settrimmedsize{239mm}{169mm}{*}
    \setlength{\trimtop}{\stockheight}
    \addtolength{\trimtop}{-\paperheight}
    \setlength{\trimtop}{0.5\trimtop}
    \setlength{\trimedge}{\stockwidth}
    \addtolength{\trimedge}{-\paperwidth}
    \ifpdf
      \AtBeginDocument{%
        \setlength{\pdfpagewidth}{\stockwidth}%
        \setlength{\pdfpageheight}{\stockheight}%
      }
    \fi
  \fi
  \settypeblocksize{43pc}{30pc}{*}
}
\@nameuse{@kthdiff@setpapersize@\kthdiff@trimmedsize}
\setlrmargins{*}{*}{*}
\setulmargins{*}{*}{*}
\checkandfixthelayout



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
