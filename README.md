# ZFORTH
Zorth is a partial Forth interpreter written in Zig, it has been created as a teaching tool to teach Zig and Forth.

## Partial features
There's only a small subset of the Forth language implemented. Enough to create some simple programs and understand the basics.
You can easily extend the interpreter by adding the missing features, yourself.
However, there are complete Forth implementations already available lig gforth and zeptofortg (for PiPico), so there's no need for me to add (a lot) more features.

When you ever need a nice partial interpreter, you can always use this one and make it fit your needs. That is the charm of Forth, it can be as simple or as complex as you want it to be.

## No classic Lexer, Parser, AST, Interpreter
I initially started with a lexer, parser and AST, but it turned out to be a lot of work and defeating the whole purpose of a simple Forth PoC.
So after an evening I decided to scrap it and start from scratch and just implement the interpreter directly. Achieving the same result, but in a lot less time. However as a result it's not very fast because every iteration in a loop if the interpreter is a lot slower than an AST. But speed is not the point of this Proof of Concept, it's more about learning and understanding how Forth works and what Zig can do in the world of making interpreters. And it's also a lot more fun and easier to write than in C, I think.

## Float 32 
This interpreter uses 32 bit floats instead of the standard integer. Which for me gives makes it more flexible.

## example program that calculates  the value of a resistor in kilo Ohm
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
: human_readible dup 1000000 >= if 1000000 / . ." M ohm" else dup 1000 >= if 1000 / . ." k Ohm" else . ."  ohm" then then ;
: resistor resistor_in_ohms human_readible ;
```

usage:
```
brown black red resistor
1 Kilo Ohm
```
