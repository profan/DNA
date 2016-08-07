dna
-----------
This is intended to be a library supplying the necessities for making a game in D, this is not what you would normally have a game engine go under, but more of a game making library.

A comparison to XNA might be apt as it intends to give you what is necessary to be on your way making your game, without being too opinionated about exactly **how** this is supposed to be done. 

However, unlike XNA it aims to be a bit more pure, and tries to avoid global and static state when possible.

Basic Idea
-----------
Give the user a basic game loop, the possibility to easily play sound, (somewhat) easily draw on the screen, take input and get something up and running with as little ceremony as possible.

What it provides
-----------------
 * Audio Subsystem (Based on OpenAL)
 * Graphics Subsystem
   * Basic Text Rendering (ASCII only, based on FreeType)
   * OpenGL abstraction based on ``gland``
 * Input Subsystem (Based on SDL2, mouse, keyboard, joypads)
 * Windowing Subsystem (ditto)

Dependencies
-----------

* C Dependencies:
 * OpenAL
 * OpenALURE
 * FreeType

* D Dependencies:
 * collections (datastructures built ontop of std.experimental.allocator)
 * gland (OpenGL abstraction)

License
-----------
MIT, see LICENSE file for details.
