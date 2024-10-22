# ZFORTH
ZForth is a partial Forth interpreter written in Zig, it has been created as a teaching tool to teach Zig and Forth.

## Partial features
There's only a small subset of the Forth language implemented. Enough to create some simple programs and understand the basics.
You can easily extend the interpreter by adding the missing features, yourself.
However, there are complete Forth implementations already available lig gforth and zeptofortg (for PiPico), so there's no need for me to add (a lot) more features.

When you ever need a nice partial interpreter, you can always use this one and make it fit your needs. That is the charm of Forth, it can be as simple or as complex as you want it to be.

### No classic Lexer, Parser, AST, Interpreter (no speed ;) )
I initially started with a lexer, parser and AST, but it turned out to be a lot of work and defeating the whole purpose of a simple Forth PoC.
So after an evening I decided to scrap it and start from scratch and just implement the interpreter directly. Achieving the same result, but in a lot less time. However as a result it's not very fast because every iteration in a loop if the interpreter is a lot slower than an AST. But speed is not the point of this Proof of Concept, it's more about learning and understanding how Forth works and what Zig can do in the world of making interpreters. And it's also a lot more fun and easier to write than in C, I think.

### Float 32 
This interpreter uses 32 bit floats instead of the standard integer. Which for me gives makes it more flexible.

### Single line words
This interpreter only supports single line words. This is merely a limitation of the repl, when the repl would strip \n from the input, it would allow you to write multi line words. But for educational purposes it's better to keep it simple and small.
As an added benefit, it makes writing smaller more readable code.

### No remarks i,plemented ( yet )
Remarks are not implemented yet, since it wouldn't help with the single line words implementation that is currently in place.
Therefore ( ) and \ are not implemented yet.

# Forth files
there are two forth files, namely:
- system.f
- user.f
These should locally be in the same directory as the interpreter. In our source tree they are symbolically linked in zig-out/bin to the respective files src/system.f and src/user.f
We currently just support single line words -- just to keep things simple for education purposes.

## system.f
This is the file that holds the definition of the system words that are build up from the compiled_words and immediate words. Words like 2dup and 2drop are defined in the system.f file.

## user.f
This is the file that holds the definition of the user defined words. Currently there's no save from the interpreter (yet). But it would be trivial to add this. You just loop through the user_words keys and get the definition and write it to the file.

## turnkey word
The turnkey word is a special word that is automatically started when the interpreter starts. So one can simply define the word turnkey and call your word and it will be called when the interpreter starts.

# Examples

## example 10 print equivalent program
Your typical:
10 print "Hello World!";
20 goto 10

program in forth:

```
: 10print repeat 0 5 do ." Hello World " loop cr begin ;
```

## print text in colour
This is a simple word that sets the text to a certain ansii colour. The colours are defined by the ANSI escape codes and these codes are in the range of 30-38. Where 0 text_color would set the colour back to the standard colour (white).

```
: text_color 27 emit ." [" . ." m" ;
```

usage:
```
31 text_color ." Hello World!"
```

## random numbers
There's a a random number generator word in this implemetation. 
It takes two arguments from the stack (begin number and end number) and returns a random number between those two numbers, including the begin and end number.

```
0 30 rnd .
```

Will generate a number  between 0 and 30 (including 0 and 30).

## example 10 print with colours
The following example prints hello world in random colours.
The colors are the standard ANSI escape codes with the color codes 30-38.

```
: text_color 27 emit ." [" . ." m" ;
: 10printcolor repeat 30 38 rnd text_color ." Hello world " begin ;
```

## making 10printcolor 'turnkey'
The following code will make the 10printcolor word the turnkey word and will be called when the interpreter starts.
```
: turnkey 10printcolor ;
```
Now exit the Forth interpreter and start it again and it will print hello world in random colours. CTRL-C will bring continue the interpreter in the REPL loop.

## example program that calculates  the value of a resistor in human readable form.
The following code wil calculate the value of a resistor in human readable form based on the colors you enter in the REPL, which are in turn translated to their value between (0-9) depending on the color.
These 3 values on the stack are used to calculate the value of the resistor in M Ohms, K Ohms or ohms depending on their size.

```
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
: resistor_in_ohms rot 10 * rot + 1 rot 0 swap do 10 * loop * ;
: resistor_in_human_readible_form dup 1000000 >= if 1000000 / . ." M ohm" else dup 1000 >= if 1000 / . ." k Ohm" else . ."  ohm" then then ;
: resistor resistor_in_ohms resistor_in_human_readible_form ;
```

usage:
```
brown black red resistor
1 Kilo Ohm
```
## KnightRider scanner (on console)
```
: kitt_up repeat 1 rol .s dup 128 = until  ;
: kitt_down repeat 1 ror .s dup 1 = until  ;
: knight_rider_scanner 1 repeat kitt_up kitt_down begin ;
```