module dna.util;

import dna.text : FontAtlas;

ref FontAtlas renderFmtString(string format, Args...)(ref FontAtlas atlas, float[4][4][1] projection, float offset_x, float offset_y, Args args) {

	char[format.length*2] buf;
	const char[] str = cformat(buf[], format, args);

	atlas.renderText(projection, str, offset_x, offset_y, 1, 1, 0xffffff);

	return atlas;

} // renderFmtString

/**
 * A safer D interface to sprintf, uses a supplied char buffer for formatting, returns a slice.
 * You will most definitely die a fiery death if the format string doesn't have a null terminator.
*/
const(char[]) cformat(Args...)(char[] buf, in char[] format, Args args) {

	import core.stdc.stdio : snprintf;

	auto chars = snprintf(buf.ptr, buf.length, format.ptr, args);
	const char[] str = buf[0 .. (chars > 0) ? chars+1 : 0];

	return str;

} // cformat

/**
 * Convenience function which calls cformat on a temporary char buffer,
 * which is then returned as a value.
*/
const(char[Size]) tempformat(size_t Size, Args...)(in char[] format, Args args) {

	char[Size] temp_buf;
	cformat(temp_buf, format, args);

	return temp_buf;

} // tempformat
