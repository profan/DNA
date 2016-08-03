module smidig.math;

import std.math;
import gfm.math : Vector, Matrix;

import tested : name;

//OpenGL maths related
alias Vec2i = Vector!(int, 2);
alias Vec2f = Vector!(float, 2);
alias Vec3f = Vector!(float, 3);
alias Vec4f = Vector!(float, 4);
alias Mat3f = Matrix!(float, 3, 3);
alias Mat4f = Matrix!(float, 4, 4);

T clamp(T)(T value, T min, T max) pure @nogc nothrow {
	return (value > max) ? max : (value < min) ? min : value;
} //clamp

T normalize(T)(T val, T min, T max, T val_max) pure @nogc nothrow {
	return (min + val) / (val_max / (max - min));
} //normalize

@name("normalize 1")
unittest {

	import std.string : format;
	import std.stdio: writefln;

	float[5] values = [1, 2, 3, 4, 5];

	float min = 0, max = 1;
	float val_max = 5;
	foreach (value; values) {
		float n = normalize(value, min, max, val_max);
		assert(n >= min && n <= max, format("expected value in range, was %f", n));
	}

}

bool pointInRect(int x, int y, int r_x, int r_y, int w, int h) nothrow @nogc pure {
	return (x < r_x + w && y < r_y + h && x > r_x && y > r_y);
} //pointInRect

@name("pointInRect 1")
unittest {

	import std.random : uniform;
	import std.format : format;

	enum iterations = 10000;

	foreach (i; 0..iterations) {

		int b_x = uniform(-512, 512);
		int b_y = uniform(-512, 512);
		int b_w = uniform(2, 2048);
		int b_h = uniform(2, 2048);

		foreach (ip; 0..1000) {
			int p_x = uniform(b_x+1, b_x + b_w);
			int p_y = uniform(b_y+1, b_y + b_h);
			assert(pointInRect(p_x, p_y, b_x, b_y, b_w, b_h),
				format("(%d, %d) wasn't in rect: (%d, %d) at (%d, %d)?", p_x, p_y, b_w, b_h, b_x, b_y));
		}

	}

}

bool pointInRect(T)(Vector!(T, 2) point, Vector!(T, 4) rect) nothrow @nogc pure {
	return pointInRect(point.x, point.y, rect.x, rect.y, rect.z, rect.w);
} //pointInRect

/**
 * rotation transformation on a vector, takes vector and radians, returns new rotated vector
*/
T rotate(T)(ref T vec, double radians) nothrow @nogc pure {

	auto ca = cos(radians);
	auto sa = sin(radians);
	return T(ca*vec.x - sa*vec.y, sa*vec.x + ca*vec.y);

} //rotate

/**
 * Accepts an angle in radians, returns a unit vector representing the heading,
 * relative to a coordinate system with x+ = right and y+ = up.
*/
auto angleToVec2(T)(float radians) nothrow @nogc pure {

	auto vec = Vector!(T, 2)(cos(radians), sin(radians));
	return vec;

} //angleToVec2

T._T squaredDistanceTo(T)(ref T vec, ref T other_vec) nothrow @nogc pure if (is(T : Vector) && T._N == 2) {

	return ((vec.x - other_vec.x)*(vec.x - other_vec.x)) -
		((vec.y - other_vec.y)*(vec.y - other_vec.y));

} //squaredDistanceTo

float deg2Rad(float degrees) pure {
	return degrees * (PI/180);
} //deg2Rad

float rad2Deg(float radians) pure {
	return radians * (180/PI);
} //rad2Deg
