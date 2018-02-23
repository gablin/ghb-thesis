# Copyright (c) 2017-2018, Gabriel Hjort Blindell <ghb@kth.se>
#
# This work is licensed under a Creative Commons Attribution-NoDerivatives 4.0
# International License (see LICENSE file or visit
# <http://creativecommons.org/licenses/by-nc-nd/4.0/> for details).

# Add handling of glossaries
add_cus_dep('glo', 'gls', 0, 'makeglo2gls');
sub makeglo2gls {
    system("makeglossaries -t '$_[0]'.glg -o '$_[0]'.gls '$_[0]'");
    # Remove unwanted sequences of commas in the index
    system("sed -i -E 's/\\\\setentrycounter\\[\\]\\{page\\}\\\\glsxtrunusedformat\\{\[0-9\]*\\}\\\\delimN//' $_[0].gls");
    # Remove excess whitespace and empty lines caused by the command above
    system("sed -i -e 's/\[ \\t\]*\$//' $_[0].gls");
    system("sed -i -e '/^\$/d' $_[0].gls");
    # Remove comma before "see also" (sed cannot be used as the string to be
    # replaced spans across two lines)
    system("perl -0777 -pi -e 's/\\\\delimN\n\t\t\\\\glsseeformat/\n\t\t\\\\glsseeformat/igs' $_[0].gls");
}
push @generated_exts, 'ist', 'glg', 'glo', 'gls';

# Add generation_exts info
push @generated_exts, 'loa', 'run.xml';
