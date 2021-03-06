% Copyright (c) 2017-2018, Gabriel Hjort Blindell <ghb@kth.se>
%
% This work is licensed under a Creative Commons Attribution-NoDerivatives 4.0
% International License (see LICENSE file or visit
% <http://creativecommons.org/licenses/by-nc-nd/4.0/> for details).
%
% Based on the 'kthesis' class by Lars Engebretsen.

\NeedsTeXFormat{LaTeX2e}[2001/01/01]
\ProvidesClass{kthesis}%
              [2017/10/10 v0.1 Document class for KTH EECS dissertations]

%=========
% OPTIONS
%=========

% Declare options
\DeclareOption{g5paper}{\def\kthesis@trimmedsize{gfive}}
\DeclareOption{a3paper}{\ClassError{kthesis}{'a3paper' format not supported}}
\DeclareOption{a4paper}{\def\kthesis@trimmedsize{afour}}
\DeclareOption{a5paper}{\ClassError{kthesis}{'a5paper' format not supported}}
\DeclareOption{a6paper}{\ClassError{kthesis}{'a6paper' format not supported}}
\DeclareOption{b3paper}{\ClassError{kthesis}{'b3paper' format not supported}}
\DeclareOption{b4paper}{\ClassError{kthesis}{'b4paper' format not supported}}
\DeclareOption{b5paper}{\ClassError{kthesis}{'b5paper' format not supported}}
\DeclareOption{b6paper}{\ClassError{kthesis}{'b6paper' format not supported}}
\DeclareOption{letterpaper}{%
  \ClassError{kthesis}{'letterpaper' format not supported}%
}
\DeclareOption{legalpaper}{%
  \ClassError{kthesis}{'legalpaper' format not supported}%
}
\DeclareOption{executivepaper}{%
  \ClassError{kthesis}{'executivepaper' format not supported}%
}
\DeclareOption{ebook}{\ClassError{kthesis}{'ebook' format not supported}}
\DeclareOption{landscape}{%
  \ClassError{kthesis}{'landscape' format not supported}%
}
\newif\if@kthesis@print \@kthesis@printfalse
\newif\if@kthesis@electronic \@kthesis@electronicfalse
\DeclareOption{print}{\@kthesis@printtrue}
\DeclareOption{electronic}{\@kthesis@electronictrue}
\newif\if@kthesis@phd \@kthesis@phdfalse
\newif\if@kthesis@lic \@kthesis@licfalse
\DeclareOption{phd}{\@kthesis@phdtrue}
\DeclareOption{lic}{\@kthesis@lictrue}

% Pass on undeclared options to memoir class
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{memoir}}

% Default options
\ExecuteOptions{g5paper}

\ProcessOptions\relax

% Check options
\if@kthesis@print
\else
  \if@kthesis@electronic
  \else
    \ClassError{kthesis}{Either 'print' or 'electronic' must be provided}
  \fi
\fi
\if@kthesis@phd
\else
  \if@kthesis@lic
  \else
    \ClassError{kthesis}{Either 'phd' or 'lic' must be provided}
  \fi
\fi

\LoadClass{memoir}

% Set correct color scheme for printing
\if@kthesis@print
  \PassOptionsToPackage{cmyk}{xcolor}
\fi

% Set margins
\def\@kthesis@setpapersize@afour{%
  \setstocksize{297mm}{210mm}
  \settrimmedsize{297mm}{210mm}{*}
  \settypeblocksize{49pc}{33pc}{*}
}
\def\@kthesis@setpapersize@gfive{%
  \if@kthesis@electronic
    \setstocksize{239mm}{169mm}
  \else
    % Set stock size to A4 format
    \setstocksize{297mm}{210mm}
  \fi
  \settrimmedsize{239mm}{169mm}{*}
  \if@kthesis@electronic
  \else
    \setlength{\trimtop}{\stockheight}
    \addtolength{\trimtop}{-\paperheight}
    \setlength{\trimtop}{0.5\trimtop}
    \setlength{\trimedge}{\stockwidth}
    \addtolength{\trimedge}{-\paperwidth}
  \fi
  \settypeblocksize{43pc}{30pc}{*}
}
\@nameuse{@kthesis@setpapersize@\kthesis@trimmedsize}
\setlrmargins{*}{*}{*}
\setulmargins{*}{*}{*}
\checkandfixthelayout


%===============
% LOAD PACKAGES
%===============

\RequirePackage{adjustbox}
\RequirePackage{etoolbox}
\RequirePackage{graphicx}
\RequirePackage[english,swedish,calc]{datetime2}
\RequirePackage{mfirstuc}
\RequirePackage{textcomp}
\RequirePackage{xparse}
\RequirePackage{xstring}


%===========================
% DOCUMENT STRUCTURE MACROS
%===========================

\newcommand{\@hfMarkText}[1]{#1}
\makepagestyle{frontMatterChapPage}
\makeevenhead{frontMatterChapPage}{\@hfMarkText{\thepage}}{}{}
\makeoddhead{frontMatterChapPage}{}{}{\@hfMarkText{\thepage}}
\newcommand{\@frontMatterChapFont}{%
  \large\bfseries%
}
\NewDocumentEnvironment{frontMatterChap}{m}{%
  \clearpage%
  \markboth{#1}{#1}%
  \thispagestyle{frontMatterChapPage}%
  \begin{center}%
    \@frontMatterChapFont{#1}%
  \end{center}%
}{}

\NewDocumentCommand{\@mkFieldCommand}{m}{%
  \expandafter\NewDocumentCommand\csname #1\endcsname{m}{%
    \expandafter\def\csname @#1\endcsname{##1}%
  }
}
\undef{\@title}
\undef{\@author}
\NewDocumentCommand{\kthLogo}{m}{%
  \def\@kthLogo{%
    \adjustbox{max width=2.6cm, max height=2.6cm}{#1}%
  }%
}
\@mkFieldCommand{dedication}
\@mkFieldCommand{subtitle}
\@mkFieldCommand{degreeSwe}
\@mkFieldCommand{degreeThesis}
\@mkFieldCommand{tritaName}
\@mkFieldCommand{tritaYear}
\@mkFieldCommand{tritaNumber}
\@mkFieldCommand{issn}
\@mkFieldCommand{isrn}
\@mkFieldCommand{isbn}
\@mkFieldCommand{monthSubmitted}
\NewDocumentCommand{\defenseDate}{m}{%
  \def\@defenseDate{#1}%
  \DTMsavedate{defensedate}{#1}%
}
\@mkFieldCommand{defenseTime}
\@mkFieldCommand{defenseHallSwe}

% Gets a field if set, otherwise prints an error message
\NewDocumentCommand{\@getField}{m}{%
  \expandafter\ifcsdef{@#1}{%
    \csname @#1\endcsname%
  }{%
    \textbackslash #1 NOT SET!%
  }%
}

% Checks if a field is set
\NewDocumentCommand{\@ifHasField}{mmm}{%
  \expandafter\ifcsdef{@#1}{#2}{#3}%
}

% Get field and capitalizes the first letter of each word
\NewDocumentCommand{\@getFieldCap}{m}{%
  \@ifHasField{#1}{%
    \MFUnocap{of}%
    \ecapitalisewords{\csname @#1\endcsname}%
  }{%
    % Print appropriate error message
    \@getField{#1}%
  }%
}
% Convert to lower case
\NewDocumentCommand{\@getFieldLC}{m}{%
  \@ifHasField{#1}{%
    \MakeLowercase{\csname @#1\endcsname}%
  }{%
    % Print appropriate error message
    \@getField{#1}%
  }%
}
% Convert to upper case
\NewDocumentCommand{\@getFieldUC}{m}{%
  \@ifHasField{#1}{%
    \MakeUppercase{\csname @#1\endcsname}%
  }{%
    % Print appropriate error message
    \@getField{#1}%
  }%
}

% Prints the month of submission in the specific language.
\NewDocumentCommand{\@printMonthSubmitted}{m}{%
  \@ifHasField{monthSubmitted}{%
    \protected@edef\@tmonth{%
      \csname DTM#1monthname\endcsname{\@monthSubmitted}%
    }%
    \@tmonth%
  }{%
    % Print appropriate error message
    \@getField{defenseDate}%
  }%
}

% Removes any initial zeroes from the given number string.
\newcommand{\@removeZeros}[1]{%
  \IfBeginWith{#1}{0}{%
    \StrGobbleLeft{#1}{1}[\tempa]%
    \@removeZeros{\tempa}%
  }{%
    #1%
  }%
}

% Prints the defense date in Swedish to be used in the copyright page.
\NewDocumentCommand{\@printDefenseDateSwe}{}{%
  \@ifHasField{defenseDate}{%
    \DTMcomputedayofweekindex{\@defenseDate}{\dowindex}%
    \protected@edef\@tweekday{\DTMswedishweekdayname{\dowindex}}%
    \protected@edef\@tday{\DTMfetchday{defensedate}}%
    \protected@edef\@tmonthnum{\DTMfetchmonth{defensedate}}%
    \protected@edef\@tmonthalp{\DTMswedishmonthname{\@tmonthnum}}%
    \protected@edef\@tyear{\DTMfetchyear{defensedate}}%
    \@tweekday{}en den \@removeZeros{\@tday}\ \@tmonthalp\ \@tyear%
  }{%
    % Print appropriate error message
    \@getField{defenseDate}%
  }%
}

% Set degree fields
\if@kthesis@phd
  \degreeSwe{teknologie doktorsexamen}
  \degreeThesis{doctoral thesis}
\fi
\if@kthesis@lic
  \degreeSwe{teknologie licentiatexamen}
  \degreeThesis{licentiate thesis}
\fi

\newcommand{\@titleFont}{%
  \Huge\bfseries%
}
\newcommand{\@subtitleFont}{%
  \Large%
}
\RenewDocumentCommand{\maketitle}{}{%
  \cleardoublepage
  \thispagestyle{empty}
  \begin{center}%
    \@getField{kthLogo}
    \vfill\vfill\vfill
    {\@titleFont\@getField{title}\par}
    \@ifHasField{subtitle}{%
      \vskip .75em
      {\@subtitleFont\@getField{subtitle}}
    }{}
    \vfill
    {\Large\scshape\@getFieldLC{author}\par}
    \vfill\vfill\vfill\vfill\vfill\vfill\vfill
    \begin{tabular}{c}
      \@getFieldCap{degreeThesis} in Information and Communication Technology\\
      School of Electrical Engineering and Computer Science\\
      KTH Royal Institute of Technology\\
      Stockholm, Sweden \@getField{tritaYear}
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
      \@getField{tritaName}-\@getField{tritaYear}:\@getField{tritaNumber}\\
      \@ifHasField{issn}{%
        ISSN: \@getField{issn}\\
      }{}%
      \@ifHasField{isrn}{%
        ISRN: \@getField{isrn}\\
      }{}%
      ISBN: \@getField{isbn}\\
    \end{tabular}%
    \hfill%
    \begin{tabular}[b]{@{}r@{}}
      School of Electrical Engineering\\
      and Computer Science\\
      KTH Royal Institute of Technology\\
      SE-164 40 Kista\\
      SWEDEN
    \end{tabular}%
  \end{minipage}
  \vskip 1em
  Akademisk avhandling som med tillst{\aa}nd av Kungliga Tekniska H\"ogskolan
  framl\"agges till offentlig granskning f\"or avl\"aggande av
  \@getFieldLC{degreeSwe} p{\aa} \@printDefenseDateSwe{}
  kl.\ \@getField{defenseTime} i \@getField{defenseHallSwe}, Electrum, Kungliga
  Tekniska Högskolan, Kistag{\aa}ngen~16, Kista.\par
  \vskip 1em
  \textcopyright\hspace{4pt}\@getField{author},
  \@printMonthSubmitted{english} \@getField{tritaYear}\par
  \vskip 1em
  Printed by Universitetsservice US-AB
  \endgroup%
}

\newcommand{\@dedicationFont}{%
  \itshape%
}
\NewDocumentCommand{\makededication}{}{%
  \cleardoublepage
  \thispagestyle{empty}
  \begingroup%
  \setlength{\parindent}{0pt}%
  \mbox{}
  \vfill
  \begin{flushright}%
    \@dedicationFont%
    \@getField{dedication}%
  \end{flushright}
  \vfill
  \vfill
  \mbox{}
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
