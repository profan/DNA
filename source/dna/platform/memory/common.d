module dna.platform.memory.common;

public import std.experimental.allocator : allocatorObject, IAllocator, processAllocator, theAllocator, make, makeArray, dispose;
public import std.experimental.allocator.building_blocks.region : Region;
public import std.experimental.allocator.mallocator : Mallocator;

import tested : name;

void memmove(T)(auto ref T[] src, auto ref T[] target) {

	import core.stdc.string : memmove;
	memmove(target.ptr, src.ptr, src.length * T.sizeof);
	src = src.init;

} //memmove

@name("memmove - array 1")
unittest {

	import std.algorithm : equal;
	int[4] expected = [124, 3624, 6234, 52324];

	int[4] mem_src = expected;
	int[4] mem_trg;

	memmove(mem_src[], mem_trg[]);

	assert(equal(mem_trg[], expected[]));

}

void memmove(T)(T* src, T* target) {

	import core.stdc.string : memmove;
	memmove(target, src, T.sizeof);

} //memmove

@name("memmove 1 (unimplemented)")
unittest {

	assert(0);

}

void memswap(T)(T* src, T* target) {

	import core.stdc.string : memcpy;

	T tmp = void;
	memcpy(&tmp, target, T.sizeof);
	memmove(src, target);
	memmove(&tmp, src);

} //memswap

@name("memswap 1 (unimplemented)")
unittest {

}

//returns an aligned offset in bytes from current to allocate from.
private ptrdiff_t get_aligned(T = void)(void* current, size_t alignment = T.alignof) nothrow @nogc pure {

	import std.traits : classInstanceAlignment;

	static if (is(T == class)) {
		enum class_alignment = classInstanceAlignment!T;
		alignment = class_alignment;
	}

	ptrdiff_t diff = alignment - (cast(ptrdiff_t)current & (alignment-1));
	return (diff == T.alignof) ? 0 : diff;

} //get_aligned

//returns size of type in memory
size_t get_size(T)() nothrow @nogc pure {

	static if (is(T == class)) {
		return __traits(classInstanceSize, T);
	} else {
		return T.sizeof;
	}

} //get_size
