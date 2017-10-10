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
\DeclareOption{a3paper}{\ClassError{kthdiff}{'a3paper' format not supported}}
\DeclareOption{a4paper}{\def\kthdiff@trimmedsize{afour}}
\DeclareOption{a5paper}{\ClassError{kthdiff}{'a5paper' format not supported}}
\DeclareOption{a6paper}{\ClassError{kthdiff}{'a6paper' format not supported}}
\DeclareOption{b3paper}{\ClassError{kthdiff}{'b3paper' format not supported}}
\DeclareOption{b4paper}{\ClassError{kthdiff}{'b4paper' format not supported}}
\DeclareOption{b5paper}{\ClassError{kthdiff}{'b5paper' format not supported}}
\DeclareOption{b6paper}{\ClassError{kthdiff}{'b6paper' format not supported}}
\DeclareOption{letterpaper}{%
  \ClassError{kthdiff}{'letterpaper' format not supported}%
}
\DeclareOption{legalpaper}{%
  \ClassError{kthdiff}{'legalpaper' format not supported}%
}
\DeclareOption{executivepaper}{%
  \ClassError{kthdiff}{'executivepaper' format not supported}%
}
\DeclareOption{ebook}{\ClassError{kthdiff}{'ebook' format not supported}}
\DeclareOption{landscape}{%
  \ClassError{kthdiff}{'landscape' format not supported}%
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
  \else
    % Set stock size to A4 format
    \setstocksize{297mm}{210mm}
  \fi
  \settrimmedsize{239mm}{169mm}{*}
  \if@kthdiff@electronic
  \else
    \setlength{\trimtop}{\stockheight}
    \addtolength{\trimtop}{-\paperheight}
    \setlength{\trimtop}{0.5\trimtop}
    \setlength{\trimedge}{\stockwidth}
    \addtolength{\trimedge}{-\paperwidth}
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

\RequirePackage{adjustbox}
\RequirePackage{etoolbox}
\RequirePackage{graphicx}
\RequirePackage{mfirstuc}
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

\RenewDocumentCommand{\@title}{}{%
  NO TITLE PROVIDED,
  USE \textbackslash title COMMAND%
}
\NewDocumentCommand{\@subtitle}{}{}
\NewDocumentCommand{\subtitle}{m}{%
  \RenewDocumentCommand{\@subtitle}{}{#1}%
}
\RenewDocumentCommand{\@author}{}{%
  NO AUTHOR PROVIDED,
  USE \textbackslash author COMMAND%
}
\NewDocumentCommand{\@kthLogo}{}{%
  NO KTH LOGO PROVIDED,
  USE \textbackslash kthLogo COMMAND%
}
\NewDocumentCommand{\kthLogo}{m}{%
  \RenewDocumentCommand{\@kthLogo}{}{%
    \adjustbox{max width=.2\textwidth, max height=.14\textheight}{#1}%
  }%
}
\NewDocumentCommand{\@kthSchool}{}{%
  NO SCHOOL PROVIDED,
  USE \textbackslash kthSchool COMMAND%
}
\NewDocumentCommand{\kthSchool}{m}{%
  \RenewDocumentCommand{\@kthSchool}{}{#1}%
}
\NewDocumentCommand{\@thesisDegree}{}{%
  NO DEGREE PROVIDED,
  USE \textbackslash kthDegree COMMAND%
}
\NewDocumentCommand{\thesisDegree}{m}{%
  \RenewDocumentCommand{\@thesisDegree}{}{#1}%
}
\NewDocumentCommand{\@thesisYear}{}{%
  NO YEAR PROVIDED,
  USE \textbackslash thesisYear COMMAND%
}
\NewDocumentCommand{\thesisYear}{m}{%
  \RenewDocumentCommand{\@thesisYear}{}{#1}%
}
\NewDocumentCommand{\@thesisMonth}{}{%
  NO MONTH PROVIDED,
  USE \textbackslash thesisMonth COMMAND%
}
\NewDocumentCommand{\thesisMonth}{m}{%
  \RenewDocumentCommand{\@thesisMonth}{}{#1}%
}
\NewDocumentCommand{\@titleFont}{}{%
  \LARGE\bfseries%
}
\NewDocumentCommand{\@subtitleFont}{}{%
  \Large%
}
\RenewDocumentCommand{\maketitle}{}{%
  \newpage
  \thispagestyle{empty}
  \begin{center}%
    \@kthLogo\par
    \vfill%
    \vskip 2em%
    {\@titleFont\@title\par}%
    \expandafter\notblank\expandafter{\@subtitle}{%
      \vskip .75em%
      {\@subtitleFont\@subtitle\par}
    }{}%
    \vskip 2em%
    {\Large\scshape\MakeLowercase{\@author}\par}%
    \vskip 2em%
    {%
      \itshape%
      \begin{tabular}{c}%
        Submitted in Partial Fulfillment of\\
        the Requirements for the Degree of
        \expandafter\capitalisewords\expandafter{\@thesisDegree}
      \end{tabular}%
    }%\par
    \vskip 1em
    \expandafter\capitalisewords\expandafter{\@thesisMonth}
    \@thesisYear\par
    \vfill\vfill\vfill%
    \begin{tabular}{c}%
      \@kthSchool\\
      KTH Royal Institute of Technology\\
      Stockholm, Sweden
    \end{tabular}\par
  \end{center}%
}

\NewDocumentCommand{\makecopyright}{}{%
  \newpage
  \thispagestyle{empty}
  TODO: implement
}

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
