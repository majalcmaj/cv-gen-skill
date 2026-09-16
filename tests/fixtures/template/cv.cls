%% cv.cls — layout inspired by legacy/CV-accuris.pdf: letterspaced dark-grey name +
%% role top-left, CONTACT block top-right (same row), grey ruled section headings,
%% tight spacing so a full work history fits one page, and a near-invisible
%% ATS keyword line pinned to the bottom of the page.
%%
%% Class options select the body font (one per document, default: lato):
%%   lato | montserrat | raleway | inter | firasans | sourcesans | helvet
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{cv}[2026/01/01 cv-gen-flow CV class]
\LoadClass[10pt]{article}

% ---- Font selection (class option) ------------------------------------------
% Each option only records *how* to load the family; the load itself happens
% after \ProcessOptions so the chosen package wins over the default.
\newcommand{\cv@loadfont}{\RequirePackage[default]{lato}}
\DeclareOption{lato}{\renewcommand{\cv@loadfont}{\RequirePackage[default]{lato}}}
\DeclareOption{montserrat}{\renewcommand{\cv@loadfont}{\RequirePackage[defaultfam,tabular,lining]{montserrat}}}
\DeclareOption{raleway}{\renewcommand{\cv@loadfont}{\RequirePackage[default,lining]{raleway}}}
\DeclareOption{inter}{\renewcommand{\cv@loadfont}{\RequirePackage[sfdefault]{inter}}}
\DeclareOption{firasans}{\renewcommand{\cv@loadfont}{\RequirePackage[sfdefault]{FiraSans}}}
\DeclareOption{sourcesans}{\renewcommand{\cv@loadfont}{\RequirePackage[default]{sourcesanspro}}}
\DeclareOption{helvet}{\renewcommand{\cv@loadfont}{\RequirePackage{helvet}}}
\ProcessOptions\relax

\RequirePackage[a4paper, margin=2cm]{geometry}
\RequirePackage[T1]{fontenc}
\RequirePackage[utf8]{inputenc} % facts.md/content.yaml carry names with diacritics (e.g. "Michał")
\cv@loadfont
\renewcommand{\familydefault}{\sfdefault} % sans-serif default family
\RequirePackage{xcolor}
\RequirePackage{graphicx} % \resizebox, used to keep the keyword line to one line
\RequirePackage{enumitem}
\RequirePackage{titlesec}
\RequirePackage{tabularx}
\RequirePackage[letterspace=80]{microtype} % \lsstyle spaces out the name
\RequirePackage{hyperref}

% ---- Grey palette (no pure black anywhere) ----------------------------------
\definecolor{cvname}{HTML}{3A3A3A}   % name — dark grey, the heaviest ink on the page
\definecolor{cvink}{HTML}{404040}    % section headings, role/degree emphasis
\definecolor{cvbody}{HTML}{4A4A4A}   % running text
\definecolor{cvmuted}{HTML}{7A7A7A}  % company, dates, contact details
\definecolor{cvrule}{HTML}{C4C4C4}   % section rules
\definecolor{cvkeyword}{HTML}{EEEEEE} % bottom keyword line — barely visible to humans

\hypersetup{colorlinks=true, urlcolor=cvmuted, linkcolor=cvmuted}
\AtBeginDocument{\color{cvbody}}

% Some body fonts (e.g. raleway) are wide enough that a slash-joined run or a
% long compound word can still overflow the margin even once \allowbreak
% marks a slash as breakable (render_cv.py's latex_escape) — TeX's line
% breaker can reject that break as too bad and fall back to an overfull box.
% \emergencystretch lets it add extra interword stretch instead of
% overflowing; \tolerance/\hbadness widen what counts as an acceptable line.
% This is a second, font-independent line of defense — render_cv.py still
% hard-fails the build if an overfull hbox slips through anyway.
\tolerance=9999
\emergencystretch=3em
\hbadness=10000

\pagestyle{empty} % no page numbers on a CV

% Tight itemize: small \itemsep/\parskip everywhere so a full work history fits.
\setlist[itemize]{itemsep=1.5pt, topsep=2pt, parsep=0pt, partopsep=0pt, leftmargin=1.1em}

% Grey, ruled section headings (SUMMARY, EDUCATION, PROFESSIONAL EXPERIENCE, ...).
% No SKILLS heading is ever defined here — skills render only via \keywordsline.
\titleformat{\section}
  {\normalfont\bfseries\large\color{cvink}}{}{0pt}{}[{\color{cvrule}\titlerule[0.8pt]}]
% {left}{before}{after}: 12pt of air above a heading, 7pt between the rule and
% the first line of the section body.
\titlespacing*{\section}{0pt}{12pt}{7pt}

% ---- Header: name + role top-left, CONTACT block top-right, same row. ----
% #1 = name (e.g. "Alex Nowak"), #2 = role/title line(s),
% #3 = contact block content (already formatted lines, right-aligned).
\newcommand{\cvheader}[3]{%
  \noindent
  \begin{tabularx}{\linewidth}{@{}X r@{}}
    \begin{minipage}[t]{0.64\linewidth}
      \raggedright\hyphenpenalty=10000\exhyphenpenalty=10000
      % \par inside the group so the loosened \baselineskip applies to a name
      % that wraps onto a second line.
      {\bfseries\Huge\color{cvname}\selectfont
       \setlength{\baselineskip}{1.0\baselineskip}\lsstyle #1\par}
      \vspace{5pt}
      {\normalsize\color{cvmuted} #2}
    \end{minipage}
    &
    \begin{minipage}[t]{0.34\linewidth}
      \raggedleft
      {\bfseries\normalsize\color{cvink}\lsstyle CONTACT}\\[3pt]
      {\small\color{cvmuted} #3}
    \end{minipage}
  \end{tabularx}
  \par\vspace{4pt}
}

% Left block wraps, right block holds the dates flush right. Two [t] minipages
% (not \hfill) so a long role/degree wraps instead of colliding with the dates,
% and both keep the same first baseline.
\newcommand{\cv@titlerow}[2]{%
  \noindent
  \begin{minipage}[t]{0.78\linewidth}\raggedright #1\end{minipage}%
  \hfill
  \begin{minipage}[t]{0.20\linewidth}\raggedleft #2\end{minipage}%
}

% ---- Education entry: #1 degree, #2 school, #3 dates (dates right-aligned) ----
\newcommand{\eduentry}[3]{%
  \cv@titlerow{{\bfseries\color{cvink}#1}\enspace{\color{cvbody}#2}}{\color{cvmuted}#3}%
  \par\vspace{1.5pt}%
}

% ---- Job header: #1 role, #2 company, #3 dates ----
\newcommand{\jobheader}[3]{%
  \cv@titlerow{\bfseries\color{cvink}#1}{\color{cvmuted}#3}%
  \par\nobreak\noindent{\color{cvmuted}#2}\par\vspace{2pt}%
}

% ---- Keyword line: pinned to the page bottom, one line, barely visible. ----
% Machine-readable ATS keyword dump that doubles as the closing separator.
% If the keywords are wider than the text block they are scaled down rather
% than wrapped, so this always stays a single horizontal line.
\newsavebox{\cv@kwbox}
\newcommand{\keywordsline}[1]{%
  \par\vfill
  \sbox{\cv@kwbox}{\scriptsize\color{cvkeyword}#1}%
  \noindent
  \ifdim\wd\cv@kwbox>\linewidth
    \resizebox{\linewidth}{!}{\usebox{\cv@kwbox}}%
  \else
    \usebox{\cv@kwbox}%
  \fi
  \par
}
