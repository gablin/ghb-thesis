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
\RequirePackage{textcomp}
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

\NewDocumentCommand{\@mkInfoCommand}{m}{%
  \expandafter\NewDocumentCommand\csname #1\endcsname{m}{%
    \expandafter\DeclareDocumentCommand\csname @#1\endcsname{}{##1}%
  }
}
\undef{\@title}
\undef{\@author}
\NewDocumentCommand{\kthLogo}{m}{%
  \DeclareDocumentCommand{\@kthLogo}{}{%
    \adjustbox{max width=.2\textwidth, max height=.14\textheight}{#1}%
  }%
}
\@mkInfoCommand{subtitle}
\@mkInfoCommand{kthSchool}
\@mkInfoCommand{thesisDegreeEng}
\@mkInfoCommand{thesisDegreeSwe}
\@mkInfoCommand{thesisYear}
\@mkInfoCommand{thesisMonth}
\@mkInfoCommand{thesisTrita}
\@mkInfoCommand{thesisIssn}
\@mkInfoCommand{thesisIsrn}
\@mkInfoCommand{thesisIsbn}
\@mkInfoCommand{thesisSubjectEng}
\@mkInfoCommand{thesisSubjectSwe}
\@mkInfoCommand{defenseDateEng}
\@mkInfoCommand{defenseDateSwe}
\@mkInfoCommand{defenseTime}
\@mkInfoCommand{defenseHallEng}
\@mkInfoCommand{defenseHallSwe}
\NewDocumentCommand{\@getInfo}{m}{%
  \expandafter\ifcsdef{@#1}{%
    \csname @#1\endcsname%
  }{%
    \textbackslash #1 NOT SET!%
  }%
}
\NewDocumentCommand{\@ifHasInfo}{mmm}{%
  \expandafter\ifcsdef{@#1}{#2}{#3}%
}

% Commands that convert cases do not play nicely with \@getInfo, so we provide
% custom commands that work around this problem

% Capitalizes the first letter
\NewDocumentCommand{\@getInfoCap}{m}{%
  \@ifHasInfo{#1}{%
    % For some reason, three levels of \expandafter are needed here
    \expandafter\expandafter\expandafter\makefirstuc%
    \expandafter\expandafter\expandafter{\csname @#1\endcsname}%
  }{%
    % Print appropriate error message
    \@getInfo{#1}%
  }%
}
% Convert to lower case
\NewDocumentCommand{\@getInfoLC}{m}{%
  \@ifHasInfo{#1}{%
    % Same workaround as in \@getInfoCap
    \expandafter\expandafter\expandafter\MakeLowercase%
    \expandafter\expandafter\expandafter{\csname @#1\endcsname}%
  }{%
    % Print appropriate error message
    \@getInfo{#1}%
  }%
}
% Convert to upper case
\NewDocumentCommand{\@getInfoUC}{m}{%
  \@ifHasInfo{#1}{%
    % Same workaround as in \@getInfoLC
    \expandafter\expandafter\expandafter\MakeUppercase%
    \expandafter\expandafter\expandafter{\csname @#1\endcsname}%
  }{%
    % Print appropriate error message
    \@getInfo{#1}%
  }%
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
    \@getInfo{kthLogo}\par
    \vfill
    \vskip 2em
    {\@titleFont\@getInfo{title}\par}
    \@ifHasInfo{subtitle}{%
      \vskip .75em
      {\@subtitleFont\@getInfo{subtitle}}
    }{}
    \vskip 2em
    {\Large\scshape\MakeLowercase{\@getInfo{author}}\par}
    \vskip 2em
    {%
      \itshape%
      \begin{tabular}{c}
        Submitted in Partial Fulfillment of\\
        the Requirements for the Degree of \@getInfoCap{thesisDegreeEng}
      \end{tabular}
    }\par
    \vskip 1em
    \@getInfoCap{thesisMonth} \@getInfo{thesisYear}\par
    \vfill\vfill\vfill
    \begin{tabular}{c}
      \@getInfo{kthSchool}\\
      KTH Royal Institute of Technology\\
      Stockholm, Sweden
    \end{tabular}\par
  \end{center}
}

\NewDocumentCommand{\makecopyright}{}{%
  \newpage
  \thispagestyle{empty}
  \mbox{}
  \vfill
  \begingroup%
  \setlength{\parindent}{0pt}%
  \begin{minipage}{\textwidth}%
    \begin{tabular}[b]{@{}l@{}}
      TRITA-ICT \@getInfo{thesisTrita}\\
      \@ifHasInfo{thesisIssn}{%
        ISSN: \@getInfo{thesisIssn}\\
      }{}%
      \@ifHasInfo{thesisIsrn}{%
        ISRN: \@getInfo{thesisIsrn}\\
      }{}%
      ISBN: \@getInfo{thesisIsbn}\\
    \end{tabular}%
    \hfill%
    \begin{tabular}[b]{@{}r@{}}
      School of ICT\\
      KTH Royal Institute of Technology\\
      SE-164 40 Kista\\
      SWEDEN
    \end{tabular}%
  \end{minipage}
  \vskip 1em
  Academic dissertation that, with permission from KTH Royal Institute of
  Technology, is presented for public examination for completion of degree of
  \@getInfoLC{thesisDegreeEng} in \@getInfoLC{thesisSubjectEng} on
  \@getInfo{defenseDateEng}, at \@getInfo{defenseTime}, in
  \@getInfo{defenseHallEng}, Electrum, KTH Royal Institute of Technology,
  Kistag{\aa}ngen 16, Kista, Sweden.\par
  \vskip 1em
  Akademisk avhandling som med tillst{\aa}nd av Kungl Tekniska H\"ogskolan
  framl\"agges till offentlig granskning f\"or avl\"aggande av
  \@getInfoLC{thesisDegreeSwe}sexamen i \@getInfoLC{thesisSubjectSwe} den
  \@getInfoLC{defenseDateSwe}, klockan \@getInfo{defenseTime}, i
  \@getInfo{defenseHallSwe}, Electrum, Kungl Tekniska H\"ogskolan,
  Kistag{\aa}ngen 16, Kista.\par
  \vskip 1em
  \textcopyright\hspace{4pt}\@getInfo{author},
  \@getInfoLC{thesisMonth} \@getInfo{thesisYear}
  \vskip 1em
  Printed by Universitetsservice US AB
  \endgroup%
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
