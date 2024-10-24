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
: resistor_in_ohms rot 10 * rot + 1 rot 0 do 10 * loop * ;
: resistor_in_human_readible_form 32 text_color dup 1000000 >= if 1000000 / . ." M ohm" else dup 1000 >= if 1000 / . ." k Ohm" else . ."  ohm" then then 0 text_color ;
: resistor resistor_in_ohms resistor_in_human_readible_form ;

: lellow 33 text_color ;

: 10print repeat 5 0 do ." Hello World " loop cr begin ;

: 10printcolor repeat 38 30 rnd text_color ." Hello world " begin ;

: bin16 1 16 0 do dup rot over over & rot = if ." 1" else ." 0" then swap 1 rol loop 2drop cr ;
: kitt_up repeat 1 rol 30 ms dup 27 emit ." [10;10f" bin16 dup 32768 = until ;
: kitt_down repeat 1 ror 30 ms dup 27 emit ." [10;10f" bin16 dup 1 = until ;
: kitt 1 repeat kitt_up kitt_down begin ;