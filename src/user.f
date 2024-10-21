: black 0 ;
: brown 1 ;
: red 2 ;
: orange 3 ;
: yellow 4 ;
: green 5 ;
: blue 6 ;
: violet 7 ;
: grey 8 ;
: white 9 ;
: text_color 27 emit ." [" . ." m" ;
: resistor_in_ohms rot 10 * rot + 1 rot 0 swap do 10 * loop * ;
: resistor_in_human_readible_form 32 text_color dup 1000000 >= if 1000000 / . ." M ohm" else dup 1000 >= if 1000 / . ." k Ohm" else . ."  ohm" then then 0 text_color ;
: resistor resistor_in_ohms resistor_in_human_readible_form ;
: lellow 33 text_color ;
: 10print repeat 30 38 rnd text_color ." Hello world " begin ;