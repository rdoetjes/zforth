# ZFORTH
Zorth is a partial Forth interpreter written in Zig, it has been created as a teaching tool to teach Zig and Forth.

## Partial features
There's only a small subset of the Forth language implemented. Enough to create some simple programs and understand the basics.
You can easily extend the interpreter by adding the missing features, yourself.
However, there are complete Forth implementations already available lig gforth and zeptofortg (for PiPico), so there's no need for me to add (a lot) more features.

When you ever need a nice partial interpreter, you can always use this one and make it fit your needs. That is the charm of Forth, it can be as simple or as complex as you want it to be.

## No classic Lexer, Parser, AST, Interpreter
I initially started with a lexer, parser and AST, but it turned out to be a lot of work and defeating the whole purpose of Forth which was meant to be simple to be implemented in assembly.
So after two eveings of work, I decided to scrap it and start from scratch and just implement the interpreter directly. Achieving the same result, but in a lot less time and less memory usage.