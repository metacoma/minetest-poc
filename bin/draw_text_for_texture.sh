COLOR="${2:-#000000}"
convert -size 240x240 -fill "${COLOR}" xc:White \
  -gravity Center \
  -weight 700 -pointsize 50 \
  -annotate 0 $* \
  png:-
