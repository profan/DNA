module dna.lib.fontstash;

import std.typecons : Tuple;

/**
 * This is a reimplementation of C library fontstash in more idiomatic D code,
 * created mostly because the original ported C code was such a horrific fucking
 * mess, basically impossible to navigate not because of domain difficulty, but because
 * it was full of leaky abstractions, crappy error handling and generally a lot of things that
 * came out of being written in rather shitty C.
 *
 * Goals
 * ----------
 *  1. Avoid nullable pointers whenever possible, prefer references (make structures move-only when possible).
 *  2. When C-like memory management is required, use scope(exit) to handle errors instead of gotos to labels,
 *      this lets us keep code that belogns together, actually together.
 *  3. Make code less C-like, declare variables only as soon as they are actually used, do not re-use unless absolutely
 *      necessary as gratuitous mutability just muddles things, especially if it's just a few bytes.
 *  4. ???
 *  5. Profit!
*/

alias Rect = Tuple!(float, "x", float, "y", float, "s", float, "t");

struct Quad {

	Rect top_left;
	Rect bottom_right;

} // Quad

struct FontStash {

} // FontStash
