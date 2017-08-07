# Copyright (c) 2017, Gabriel Hjort Blindell <ghb@kth.se>
#
# This work is licensed under a Creative Commons 4.0 International License (see
# LICENSE file or visit <http://creativecommons.org/licenses/by/4.0/> for a copy
# of the license).

add_cus_dep('glo', 'gls', 0, 'makeglo2gls');
sub makeglo2gls {
    system("makeglossaries -t '$_[0]'.glg -o '$_[0]'.gls '$_[0]'");
    # Remove unwanted sequences of commas in the index
    system("sed -i '/\\glsxtrunusedformat/d' $_[0].gls");
}
