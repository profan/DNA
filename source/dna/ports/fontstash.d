/**
 * This structure is here because in the original port by ketmar, it was under the name FonsTextAlign and replaced the original
 * type in the fontstash library where it was just an integer with an enum, we don't wish to depend on anything nanovg specifically
 * and thus we redefine it here.
*/

align(1) struct FonsTextAlign {
align(1):

	/// Horizontal align.
	enum H : ubyte {
		Left     = 0, /// Default, align text horizontally to left.
		Center   = 1, /// Align text horizontally to center.
		Right    = 2, /// Align text horizontally to right.
	} // H

	/// Vertical align.
	enum V : ubyte {
		Baseline = 0, /// Default, align text vertically to baseline.
		Top      = 1, /// Align text vertically to top.
		Middle   = 2, /// Align text vertically to middle.
		Bottom   = 3, /// Align text vertically to bottom.
	} // V

	pure nothrow @safe @nogc:
	public:

		this (H h) { pragma(inline, true); value = h; }
		this (V v) { pragma(inline, true); value = cast(ubyte)(v<<4); }
		this (H h, V v) { pragma(inline, true); value = cast(ubyte)(h|(v<<4)); }
		this (V v, H h) { pragma(inline, true); value = cast(ubyte)(h|(v<<4)); }
		void reset () { pragma(inline, true); value = 0; }
		void reset (H h, V v) { pragma(inline, true); value = cast(ubyte)(h|(v<<4)); }
		void reset (V v, H h) { pragma(inline, true); value = cast(ubyte)(h|(v<<4)); }

	@property:

		bool left () const { pragma(inline, true); return ((value&0x0f) == H.Left); } ///
		void left (bool v) { pragma(inline, true); value = cast(ubyte)((value&0xf0)|(v ? H.Left : 0)); } ///
		bool center () const { pragma(inline, true); return ((value&0x0f) == H.Center); } ///
		void center (bool v) { pragma(inline, true); value = cast(ubyte)((value&0xf0)|(v ? H.Center : 0)); } ///
		bool right () const { pragma(inline, true); return ((value&0x0f) == H.Right); } ///
		void right (bool v) { pragma(inline, true); value = cast(ubyte)((value&0xf0)|(v ? H.Right : 0)); } ///
		//
		bool baseline () const { pragma(inline, true); return (((value>>4)&0x0f) == V.Baseline); } ///
		void baseline (bool v) { pragma(inline, true); value = cast(ubyte)((value&0x0f)|(v ? V.Baseline<<4 : 0)); } ///
		bool top () const { pragma(inline, true); return (((value>>4)&0x0f) == V.Top); } ///
		void top (bool v) { pragma(inline, true); value = cast(ubyte)((value&0x0f)|(v ? V.Top<<4 : 0)); } ///
		bool middle () const { pragma(inline, true); return (((value>>4)&0x0f) == V.Middle); } ///
		void middle (bool v) { pragma(inline, true); value = cast(ubyte)((value&0x0f)|(v ? V.Middle<<4 : 0)); } ///
		bool bottom () const { pragma(inline, true); return (((value>>4)&0x0f) == V.Bottom); } ///
		void bottom (bool v) { pragma(inline, true); value = cast(ubyte)((value&0x0f)|(v ? V.Bottom<<4 : 0)); } ///
		//
		H horizontal () const { pragma(inline, true); return cast(H)(value&0x0f); } ///
		void horizontal (H v) { pragma(inline, true); value = (value&0xf0)|v; } ///
		//
		V vertical () const { pragma(inline, true); return cast(V)((value>>4)&0x0f); } ///
		void vertical (V v) { pragma(inline, true); value = (value&0x0f)|cast(ubyte)(v<<4); } ///
		//

	private:
		ubyte value = 0; // low nibble: horizontal; high nibble: vertical

} // FonsTextAlign

/**
 * Ditto for these functions.
*/

auto nvg__min(T) (T a, T b) { pragma(inline, true); return (a < b ? a : b); }
auto nvg__max(T) (T a, T b) { pragma(inline, true); return (a > b ? a : b); }
auto nvg__clamp(T) (T a, T mn, T mx) { pragma(inline, true); return (a < mn ? mn : (a > mx ? mx : a)); }
float nvg__absf() (float a) { pragma(inline, true); return (a >= 0.0f ? a : -a); }
auto nvg__sign(T) (T a) { pragma(inline, true); return (a >= cast(T)0 ? cast(T)1 : cast(T)(-1)); }
float nvg__cross() (float dx0, float dy0, float dx1, float dy1) { pragma(inline, true); return (dx1*dy0-dx0*dy1); }

// ////////////////////////////////////////////////////////////////////////// //
// fontstash
// ////////////////////////////////////////////////////////////////////////// //
import core.stdc.stdlib : malloc, realloc, free;
import core.stdc.string : memset, memcpy, strncpy, strcmp, strlen;
import core.stdc.stdio : FILE, fopen, fclose, fseek, ftell, fread, SEEK_END, SEEK_SET;

public:
// welcome to version hell!
version(nanovg_force_detect) {} else version(nanovg_use_freetype) { version = nanovg_use_freetype_ii; }

version(nanovg_use_freetype_ii) {
	enum HasAST = false;
} else {
	static if (__traits(compiles, { import stb_truetype; })) {
		import stb_truetype;
		enum HasAST = true;
	} else static if (__traits(compiles, { import derelict.freetype.ft; })) {
		import derelict.freetype.ft;
		enum HasAST = false;
	} else {
		static assert(0, "no stb_ttf/freetype found!");
	}
}

// ////////////////////////////////////////////////////////////////////////// //

enum FONS_INVALID = -1;

alias FONSflags = int;
enum /* FONSflags */ {
	FONS_ZERO_TOPLEFT    = 1<<0,
	FONS_ZERO_BOTTOMLEFT = 1<<1,
}

/**
alias FONSalign = int;
enum /+ FONSalign +/ {
	// Horizontal align
	FONS_ALIGN_LEFT   = 1<<0, // Default
	FONS_ALIGN_CENTER   = 1<<1,
	FONS_ALIGN_RIGHT  = 1<<2,
	// Vertical align
	FONS_ALIGN_TOP    = 1<<3,
	FONS_ALIGN_MIDDLE = 1<<4,
	FONS_ALIGN_BOTTOM = 1<<5,
	FONS_ALIGN_BASELINE = 1<<6, // Default
}
*/

alias FONSerrorCode = int;
enum /*FONSerrorCode*/ {
	// Font atlas is full.
	FONS_ATLAS_FULL = 1,
	// Scratch memory used to render glyphs is full, requested size reported in 'val', you may need to bump up FONS_SCRATCH_BUF_SIZE.
	FONS_SCRATCH_FULL = 2,
	// Calls to fonsPushState has created too large stack, if you need deep state stack bump up FONS_MAX_STATES.
	FONS_STATES_OVERFLOW = 3,
	// Trying to pop too many states fonsPopState().
	FONS_STATES_UNDERFLOW = 4,
}

struct FONSparams {
	int width, height;
	ubyte flags;
	void* userPtr;
	bool function (void* uptr, int width, int height) renderCreate;
	int function (void* uptr, int width, int height) renderResize;
	void function (void* uptr, int* rect, const(ubyte)* data) renderUpdate;
	void function (void* uptr, const(float)* verts, const(float)* tcoords, const(uint)* colors, int nverts) renderDraw;
	void function (void* uptr) renderDelete;
}

struct FONSquad {
	float x0, y0, s0, t0;
	float x1, y1, s1, t1;
}

struct FONStextIter {
	float x, y, nextx, nexty, scale, spacing;
	uint codepoint;
	short isize, iblur;
	FONSfont* font;
	int prevGlyphIndex;
	union {
		// for char
		struct {
			const(char)* str;
			const(char)* next;
			const(char)* end;
			uint utf8state;
		}
		// for dchar
		struct {
			const(dchar)* dstr;
			const(dchar)* dnext;
			const(dchar)* dend;
		}
	}
	bool isChar;
	@property const(T)* string(T) () const pure nothrow @nogc if (is(T == char) || is(T == dchar)) {
		pragma(inline, true);
		static if (is(T == char)) return str; else return dstr;
	}
	@property const(T)* nextp(T) () const pure nothrow @nogc if (is(T == char) || is(T == dchar)) {
		pragma(inline, true);
		static if (is(T == char)) return next; else return dnext;
	}
	@property const(T)* endp(T) () const pure nothrow @nogc if (is(T == char) || is(T == dchar)) {
		pragma(inline, true);
		static if (is(T == char)) return end; else return dend;
	}
	~this () { pragma(inline, true); if (isChar) { str = next = end = null; utf8state = 0; } else { dstr = dnext = dend = null; } }
}


// ////////////////////////////////////////////////////////////////////////// //

static if (!HasAST) {

	import derelict.freetype.ft;

	struct FONSttFontImpl {
		FT_Face font;
		bool mono; // no aa?
	}

	__gshared FT_Library ftLibrary;

	int fons__tt_init (FONScontext* context) {
		FT_Error ftError;
		//FONS_NOTUSED(context);
		ftError = FT_Init_FreeType(&ftLibrary);
		return (ftError == 0);
	}

	void fons__tt_setMono (FONScontext* context, FONSttFontImpl* font, bool v) {
		font.mono = v;
	}

	int fons__tt_loadFont (FONScontext* context, FONSttFontImpl* font, ubyte* data, int dataSize) {
		FT_Error ftError;
		//font.font.userdata = stash;
		ftError = FT_New_Memory_Face(ftLibrary, cast(const(FT_Byte)*)data, dataSize, 0, &font.font);
		return ftError == 0;
	}

	void fons__tt_getFontVMetrics (FONSttFontImpl* font, int* ascent, int* descent, int* lineGap) {
		*ascent = font.font.ascender;
		*descent = font.font.descender;
		*lineGap = font.font.height-(*ascent - *descent);
	}

	float fons__tt_getPixelHeightScale (FONSttFontImpl* font, float size) {
		return size/(font.font.ascender-font.font.descender);
	}

	int fons__tt_getGlyphIndex (FONSttFontImpl* font, int codepoint) {
		return FT_Get_Char_Index(font.font, codepoint);
	}

	int fons__tt_buildGlyphBitmap (FONSttFontImpl* font, int glyph, float size, float scale, int* advance, int* lsb, int* x0, int* y0, int* x1, int* y1) {
		FT_Error ftError;
		FT_GlyphSlot ftGlyph;
		uint exflags = (font.mono ? FT_LOAD_MONOCHROME : 0);
		ftError = FT_Set_Pixel_Sizes(font.font, 0, cast(FT_UInt)(size*cast(float)font.font.units_per_EM/cast(float)(font.font.ascender-font.font.descender)));
		if (ftError) return 0;
		ftError = FT_Load_Glyph(font.font, glyph, FT_LOAD_RENDER|/*FT_LOAD_NO_AUTOHINT|*/exflags);
		if (ftError) return 0;
		ftError = FT_Get_Advance(font.font, glyph, FT_LOAD_NO_SCALE|/*FT_LOAD_NO_AUTOHINT|*/exflags, cast(FT_Fixed*)advance);
		if (ftError) return 0;
		ftGlyph = font.font.glyph;
		*lsb = cast(int)ftGlyph.metrics.horiBearingX;
		*x0 = ftGlyph.bitmap_left;
		*x1 = *x0+ftGlyph.bitmap.width;
		*y0 = -ftGlyph.bitmap_top;
		*y1 = *y0+ftGlyph.bitmap.rows;
		return 1;
	}

	void fons__tt_renderGlyphBitmap (FONSttFontImpl* font, ubyte* output, int outWidth, int outHeight, int outStride, float scaleX, float scaleY, int glyph) {
		FT_GlyphSlot ftGlyph = font.font.glyph;
		if (font.mono) {
			auto src = ftGlyph.bitmap.buffer;
			auto dst = output;
			auto spt = ftGlyph.bitmap.pitch;
			if (spt < 0) spt = -spt;
			foreach (int y; 0..ftGlyph.bitmap.rows) {
				ubyte count = 0, b = 0;
				auto s = src;
				auto d = dst;
				foreach (int x; 0..ftGlyph.bitmap.width) {
					if (count-- == 0) { count = 7; b = *s++; } else b <<= 1;
					*d++ = (b&0x80 ? 255 : 0);
				}
				src += spt;
				dst += outStride;
			}
		} else {
			auto src = ftGlyph.bitmap.buffer;
			auto dst = output;
			auto spt = ftGlyph.bitmap.pitch;
			if (spt < 0) spt = -spt;
			foreach (int y; 0..ftGlyph.bitmap.rows) {
				import core.stdc.string : memcpy;
				//dst[0..ftGlyph.bitmap.width] = src[0..ftGlyph.bitmap.width];
				memcpy(dst, src, ftGlyph.bitmap.width);
				src += spt;
				dst += outStride;
			}
		}
	}

	int fons__tt_getGlyphKernAdvance (FONSttFontImpl* font, int glyph1, int glyph2) {
		FT_Vector ftKerning;
		FT_Get_Kerning(font.font, glyph1, glyph2, FT_Kerning_Mode.FT_KERNING_DEFAULT, &ftKerning);
		return cast(int)ftKerning.x;
	}

} else {
	// ////////////////////////////////////////////////////////////////////////// //
	struct FONSttFontImpl {
		stbtt_fontinfo font;
	}

	int fons__tt_init (FONScontext* context) {
		return 1;
	}

	void fons__tt_setMono (FONScontext* context, FONSttFontImpl* font, bool v) {
	}

	int fons__tt_loadFont (FONScontext* context, FONSttFontImpl* font, ubyte* data, int dataSize) {
		int stbError;
		font.font.userdata = context;
		stbError = stbtt_InitFont(&font.font, data, 0);
		return stbError;
	}

	void fons__tt_getFontVMetrics (FONSttFontImpl* font, int* ascent, int* descent, int* lineGap) {
		stbtt_GetFontVMetrics(&font.font, ascent, descent, lineGap);
	}

	float fons__tt_getPixelHeightScale (FONSttFontImpl* font, float size) {
		return stbtt_ScaleForPixelHeight(&font.font, size);
	}

	int fons__tt_getGlyphIndex (FONSttFontImpl* font, int codepoint) {
		return stbtt_FindGlyphIndex(&font.font, codepoint);
	}

	int fons__tt_buildGlyphBitmap (FONSttFontImpl* font, int glyph, float size, float scale, int* advance, int* lsb, int* x0, int* y0, int* x1, int* y1) {
		stbtt_GetGlyphHMetrics(&font.font, glyph, advance, lsb);
		stbtt_GetGlyphBitmapBox(&font.font, glyph, scale, scale, x0, y0, x1, y1);
		return 1;
	}

	void fons__tt_renderGlyphBitmap (FONSttFontImpl* font, ubyte* output, int outWidth, int outHeight, int outStride, float scaleX, float scaleY, int glyph) {
		stbtt_MakeGlyphBitmap(&font.font, output, outWidth, outHeight, outStride, scaleX, scaleY, glyph);
	}

	int fons__tt_getGlyphKernAdvance (FONSttFontImpl* font, int glyph1, int glyph2) {
		return stbtt_GetGlyphKernAdvance(&font.font, glyph1, glyph2);
	}

} // version


private:
enum FONS_SCRATCH_BUF_SIZE = 64000;
enum FONS_HASH_LUT_SIZE = 256;
enum FONS_INIT_FONTS = 4;
enum FONS_INIT_GLYPHS = 256;
enum FONS_INIT_ATLAS_NODES = 256;
enum FONS_VERTEX_COUNT = 1024;
enum FONS_MAX_STATES = 20;

uint fons__hashint() (uint a) {
	pragma(inline, true);
	a += ~(a<<15);
	a ^=  (a>>10);
	a +=  (a<<3);
	a ^=  (a>>6);
	a += ~(a<<11);
	a ^=  (a>>16);
	return a;
}

struct FONSglyph {
	uint codepoint;
	int index;
	int next;
	short size, blur;
	short x0, y0, x1, y1;
	short xadv, xoff, yoff;
}

struct FONSfont {
	FONSttFontImpl font;
	char[64] name;
	uint namelen;
	ubyte* data;
	int dataSize;
	ubyte freeData;
	float ascender;
	float descender;
	float lineh;
	FONSglyph* glyphs;
	int cglyphs;
	int nglyphs;
	int[FONS_HASH_LUT_SIZE] lut;
}

struct FONSstate {
	int font;
	FonsTextAlign talign;
	float size;
	uint color;
	float blur;
	float spacing;
}

struct FONSatlasNode {
	short x, y, width;
}

struct FONSatlas {
	int width, height;
	FONSatlasNode* nodes;
	int nnodes;
	int cnodes;
}

public struct FONScontext {
	FONSparams params;
	float itw, ith;
	ubyte* texData;
	int[4] dirtyRect;
	FONSfont** fonts;
	FONSatlas* atlas;
	int cfonts;
	int nfonts;
	float[FONS_VERTEX_COUNT*2] verts;
	float[FONS_VERTEX_COUNT*2] tcoords;
	uint[FONS_VERTEX_COUNT] colors;
	int nverts;
	ubyte* scratch;
	int nscratch;
	FONSstate[FONS_MAX_STATES] states;
	int nstates;
	void function (void* uptr, int error, int val) handleError;
	void* errorUptr;
}

void* fons__tmpalloc (size_t size, void* up) {
	ubyte* ptr;
	FONScontext* stash = cast(FONScontext*)up;
	// 16-byte align the returned pointer
	size = (size+0xf)&~0xf;
	if (stash.nscratch+cast(int)size > FONS_SCRATCH_BUF_SIZE) {
		if (stash.handleError) stash.handleError(stash.errorUptr, FONS_SCRATCH_FULL, stash.nscratch+cast(int)size);
		return null;
	}
	ptr = stash.scratch+stash.nscratch;
	stash.nscratch += cast(int)size;
	return ptr;
}

void fons__tmpfree (void* ptr, void* up) {
	// empty
}

// Copyright (c) 2008-2010 Bjoern Hoehrmann <bjoern@hoehrmann.de>
// See http://bjoern.hoehrmann.de/utf-8/decoder/dfa/ for details.

enum FONS_UTF8_ACCEPT = 0;
enum FONS_UTF8_REJECT = 12;

static immutable ubyte[364] utf8d = [
	// The first part of the table maps bytes to character classes that
	// to reduce the size of the transition table and create bitmasks.
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
	7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,  7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
	8, 8, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,  2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
	10, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 3, 3, 11, 6, 6, 6, 5, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,

	// The second part is a transition table that maps a combination
	// of a state of the automaton and a character class to a state.
	0, 12, 24, 36, 60, 96, 84, 12, 12, 12, 48, 72, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
	12, 0, 12, 12, 12, 12, 12, 0, 12, 0, 12, 12, 12, 24, 12, 12, 12, 12, 12, 24, 12, 24, 12, 12,
	12, 12, 12, 12, 12, 12, 12, 24, 12, 12, 12, 12, 12, 24, 12, 12, 12, 12, 12, 12, 12, 24, 12, 12,
	12, 12, 12, 12, 12, 12, 12, 36, 12, 36, 12, 12, 12, 36, 12, 12, 12, 12, 12, 36, 12, 36, 12, 12,
	12, 36, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
];

private enum DecUtfMixin(string state, string codep, string byte_) =
`{
	uint type_ = utf8d.ptr[`~byte_~`];
	`~codep~` = (`~state~` != FONS_UTF8_ACCEPT ? (`~byte_~`&0x3fu)|(`~codep~`<<6) : (0xff>>type_)&`~byte_~`);
	if ((`~state~` = utf8d.ptr[256+`~state~`+type_]) == FONS_UTF8_REJECT) {
		`~state~` = FONS_UTF8_ACCEPT;
		`~codep~` = '?';
	}
}`;

// Atlas based on Skyline Bin Packer by Jukka Jylänki
void fons__deleteAtlas (FONSatlas* atlas) {
	if (atlas is null) return;
	if (atlas.nodes !is null) free(atlas.nodes);
	free(atlas);
}

FONSatlas* fons__allocAtlas (int w, int h, int nnodes) {
	FONSatlas* atlas = null;

	// Allocate memory for the font stash.
	atlas = cast(FONSatlas*)malloc(FONSatlas.sizeof);
	if (atlas is null) goto error;
	memset(atlas, 0, FONSatlas.sizeof);

	atlas.width = w;
	atlas.height = h;

	// Allocate space for skyline nodes
	atlas.nodes = cast(FONSatlasNode*)malloc(FONSatlasNode.sizeof*nnodes);
	if (atlas.nodes is null) goto error;
	memset(atlas.nodes, 0, FONSatlasNode.sizeof*nnodes);
	atlas.nnodes = 0;
	atlas.cnodes = nnodes;

	// Init root node.
	atlas.nodes[0].x = 0;
	atlas.nodes[0].y = 0;
	atlas.nodes[0].width = cast(short)w;
	++atlas.nnodes;

	return atlas;

error:
	if (atlas !is null) fons__deleteAtlas(atlas);
	return null;
}

bool fons__atlasInsertNode (FONSatlas* atlas, int idx, int x, int y, int w) {
	// Insert node
	if (atlas.nnodes+1 > atlas.cnodes) {
		atlas.cnodes = (atlas.cnodes == 0 ? 8 : atlas.cnodes*2);
		atlas.nodes = cast(FONSatlasNode*)realloc(atlas.nodes, FONSatlasNode.sizeof*atlas.cnodes);
		if (atlas.nodes is null) return false;
	}
	for (int i = atlas.nnodes; i > idx; --i) atlas.nodes[i] = atlas.nodes[i-1];
	atlas.nodes[idx].x = cast(short)x;
	atlas.nodes[idx].y = cast(short)y;
	atlas.nodes[idx].width = cast(short)w;
	++atlas.nnodes;
	return 1;
}

void fons__atlasRemoveNode (FONSatlas* atlas, int idx) {
	if (atlas.nnodes == 0) return;
	for (int i = idx; i < atlas.nnodes-1; ++i) atlas.nodes[i] = atlas.nodes[i+1];
	--atlas.nnodes;
}

void fons__atlasExpand (FONSatlas* atlas, int w, int h) {
	// Insert node for empty space
	if (w > atlas.width) fons__atlasInsertNode(atlas, atlas.nnodes, atlas.width, 0, w-atlas.width);
	atlas.width = w;
	atlas.height = h;
}

void fons__atlasReset (FONSatlas* atlas, int w, int h) {
	atlas.width = w;
	atlas.height = h;
	atlas.nnodes = 0;
	// Init root node.
	atlas.nodes[0].x = 0;
	atlas.nodes[0].y = 0;
	atlas.nodes[0].width = cast(short)w;
	++atlas.nnodes;
}

bool fons__atlasAddSkylineLevel (FONSatlas* atlas, int idx, int x, int y, int w, int h) {
	// Insert new node
	if (!fons__atlasInsertNode(atlas, idx, x, y+h, w)) return false;

	// Delete skyline segments that fall under the shadow of the new segment
	for (int i = idx+1; i < atlas.nnodes; ++i) {
		if (atlas.nodes[i].x < atlas.nodes[i-1].x+atlas.nodes[i-1].width) {
			int shrink = atlas.nodes[i-1].x+atlas.nodes[i-1].width-atlas.nodes[i].x;
			atlas.nodes[i].x += cast(short)shrink;
			atlas.nodes[i].width -= cast(short)shrink;
			if (atlas.nodes[i].width <= 0) {
				fons__atlasRemoveNode(atlas, i);
				--i;
			} else {
				break;
			}
		} else {
			break;
		}
	}

	// Merge same height skyline segments that are next to each other
	for (int i = 0; i < atlas.nnodes-1; ++i) {
		if (atlas.nodes[i].y == atlas.nodes[i+1].y) {
			atlas.nodes[i].width += atlas.nodes[i+1].width;
			fons__atlasRemoveNode(atlas, i+1);
			--i;
		}
	}

	return true;
}

int fons__atlasRectFits (FONSatlas* atlas, int i, int w, int h) {
	// Checks if there is enough space at the location of skyline span 'i',
	// and return the max height of all skyline spans under that at that location,
	// (think tetris block being dropped at that position). Or -1 if no space found.
	int x = atlas.nodes[i].x;
	int y = atlas.nodes[i].y;
	int spaceLeft;
	if (x+w > atlas.width) return -1;
	spaceLeft = w;
	while (spaceLeft > 0) {
		if (i == atlas.nnodes) return -1;
		y = nvg__max(y, atlas.nodes[i].y);
		if (y+h > atlas.height) return -1;
		spaceLeft -= atlas.nodes[i].width;
		++i;
	}
	return y;
}

bool fons__atlasAddRect (FONSatlas* atlas, int rw, int rh, int* rx, int* ry) {
	int besth = atlas.height, bestw = atlas.width, besti = -1;
	int bestx = -1, besty = -1;

	// Bottom left fit heuristic.
	for (int i = 0; i < atlas.nnodes; ++i) {
		int y = fons__atlasRectFits(atlas, i, rw, rh);
		if (y != -1) {
			if (y+rh < besth || (y+rh == besth && atlas.nodes[i].width < bestw)) {
				besti = i;
				bestw = atlas.nodes[i].width;
				besth = y+rh;
				bestx = atlas.nodes[i].x;
				besty = y;
			}
		}
	}

	if (besti == -1) return false;

	// Perform the actual packing.
	if (!fons__atlasAddSkylineLevel(atlas, besti, bestx, besty, rw, rh)) return false;

	*rx = bestx;
	*ry = besty;

	return true;
}

void fons__addWhiteRect (FONScontext* stash, int w, int h) {
	int gx, gy;
	ubyte* dst;

	if (!fons__atlasAddRect(stash.atlas, w, h, &gx, &gy)) return;

	// Rasterize
	dst = &stash.texData[gx+gy*stash.params.width];
	foreach (int y; 0..h) {
		foreach (int x; 0..w) {
			dst[x] = 0xff;
		}
		dst += stash.params.width;
	}

	stash.dirtyRect[0] = nvg__min(stash.dirtyRect[0], gx);
	stash.dirtyRect[1] = nvg__min(stash.dirtyRect[1], gy);
	stash.dirtyRect[2] = nvg__max(stash.dirtyRect[2], gx+w);
	stash.dirtyRect[3] = nvg__max(stash.dirtyRect[3], gy+h);
}

public FONScontext* fonsCreateInternal (FONSparams* params) {
	FONScontext* stash = null;

	// Allocate memory for the font stash.
	stash = cast(FONScontext*)malloc(FONScontext.sizeof);
	if (stash is null) goto error;
	memset(stash, 0, FONScontext.sizeof);

	stash.params = *params;

	// Allocate scratch buffer.
	stash.scratch = cast(ubyte*)malloc(FONS_SCRATCH_BUF_SIZE);
	if (stash.scratch is null) goto error;

	// Initialize implementation library
	if (!fons__tt_init(stash)) goto error;

	if (stash.params.renderCreate !is null) {
		if (!stash.params.renderCreate(stash.params.userPtr, stash.params.width, stash.params.height)) goto error;
	}

	stash.atlas = fons__allocAtlas(stash.params.width, stash.params.height, FONS_INIT_ATLAS_NODES);
	if (stash.atlas is null) goto error;

	// Allocate space for fonts.
	stash.fonts = cast(FONSfont**)malloc((FONSfont*).sizeof*FONS_INIT_FONTS);
	if (stash.fonts is null) goto error;
	memset(stash.fonts, 0, (FONSfont*).sizeof*FONS_INIT_FONTS);
	stash.cfonts = FONS_INIT_FONTS;
	stash.nfonts = 0;

	// Create texture for the cache.
	stash.itw = 1.0f/stash.params.width;
	stash.ith = 1.0f/stash.params.height;
	stash.texData = cast(ubyte*)malloc(stash.params.width*stash.params.height);
	if (stash.texData is null) goto error;
	memset(stash.texData, 0, stash.params.width*stash.params.height);

	stash.dirtyRect[0] = stash.params.width;
	stash.dirtyRect[1] = stash.params.height;
	stash.dirtyRect[2] = 0;
	stash.dirtyRect[3] = 0;

	// Add white rect at 0, 0 for debug drawing.
	fons__addWhiteRect(stash, 2, 2);

	fonsPushState(stash);
	fonsClearState(stash);

	return stash;

error:
	fonsDeleteInternal(stash);
	return null;
}

FONSstate* fons__getState (FONScontext* stash) {
	pragma(inline, true);
	return &stash.states[stash.nstates-1];
}

public void fonsSetSize (FONScontext* stash, float size) {
	pragma(inline, true);
	fons__getState(stash).size = size;
}

public void fonsSetColor (FONScontext* stash, uint color) {
	pragma(inline, true);
	fons__getState(stash).color = color;
}

public void fonsSetSpacing (FONScontext* stash, float spacing) {
	pragma(inline, true);
	fons__getState(stash).spacing = spacing;
}

public void fonsSetBlur (FONScontext* stash, float blur) {
	pragma(inline, true);
	fons__getState(stash).blur = blur;
}

public void fonsSetAlign (FONScontext* stash, FonsTextAlign talign) {
	pragma(inline, true);
	fons__getState(stash).talign = talign;
}

public void fonsSetFont (FONScontext* stash, int font) {
	pragma(inline, true);
	fons__getState(stash).font = font;
}

public void fonsPushState (FONScontext* stash) {
	if (stash.nstates >= FONS_MAX_STATES) {
		if (stash.handleError) stash.handleError(stash.errorUptr, FONS_STATES_OVERFLOW, 0);
		return;
	}
	if (stash.nstates > 0) memcpy(&stash.states[stash.nstates], &stash.states[stash.nstates-1], FONSstate.sizeof);
	++stash.nstates;
}

public void fonsPopState (FONScontext* stash) {
	if (stash.nstates <= 1) {
		if (stash.handleError) stash.handleError(stash.errorUptr, FONS_STATES_UNDERFLOW, 0);
		return;
	}
	--stash.nstates;
}

public void fonsClearState (FONScontext* stash) {
	FONSstate* state = fons__getState(stash);
	state.size = 12.0f;
	state.color = 0xffffffff;
	state.font = 0;
	state.blur = 0;
	state.spacing = 0;
	state.talign.reset; // FONS_ALIGN_LEFT|FONS_ALIGN_BASELINE;
}

void fons__freeFont (FONSfont* font) {
	if (font is null) return;
	if (font.glyphs) free(font.glyphs);
	if (font.freeData && font.data) free(font.data);
	free(font);
}

int fons__allocFont (FONScontext* stash) {

	FONSfont* font = null;

	if (stash.nfonts+1 > stash.cfonts) {
		stash.cfonts = (stash.cfonts == 0 ? 8 : stash.cfonts*2);
		stash.fonts = cast(FONSfont**)realloc(stash.fonts, (FONSfont*).sizeof*stash.cfonts);
		if (stash.fonts is null) return -1;
	}

	font = cast(FONSfont*)malloc(FONSfont.sizeof);
	if (font is null) goto error;
	memset(font, 0, FONSfont.sizeof);

	font.glyphs = cast(FONSglyph*)malloc(FONSglyph.sizeof*FONS_INIT_GLYPHS);
	if (font.glyphs is null) goto error;
	font.cglyphs = FONS_INIT_GLYPHS;
	font.nglyphs = 0;

	stash.fonts[stash.nfonts++] = font;

	return stash.nfonts-1;

error:
	fons__freeFont(font);

	return FONS_INVALID;

}

private enum NoAlias = ":noaa";

public int fonsAddFont (FONScontext* stash, const(char)[] name, const(char)[] path) {

	import std.internal.cstring;

	FILE* fp = null;
	int dataSize = 0;
	ubyte* data = null;

	// if font path ends with ":noaa", add this to font name instead
	if (path.length >= NoAlias.length && path[$-NoAlias.length..$] == NoAlias) {
		path = path[0..$-NoAlias.length];
		if (name.length < NoAlias.length || name[$-NoAlias.length..$] != NoAlias) name = name.idup~":noaa";
	}

	if (path.length == 0) return FONS_INVALID;
	if (name.length == 0 || name == NoAlias) return FONS_INVALID;

	if (path.length && path[0] == '~') {
		import std.path : expandTilde;
		path = path.idup.expandTilde;
	}

	// Read in the font data.
	fp = fopen(path.tempCString, "rb");
	if (fp is null) goto error;
	fseek(fp, 0, SEEK_END);
	dataSize = cast(int)ftell(fp);
	fseek(fp, 0, SEEK_SET);
	data = cast(ubyte*)malloc(dataSize);
	if (data is null) goto error;
	fread(data, 1, dataSize, fp);
	fclose(fp);
	fp = null;

	return fonsAddFontMem(stash, name, data, dataSize, 1);

error:
	if (data) free(data);
	if (fp) fclose(fp);
	return FONS_INVALID;
}

public int fonsAddFontMem (FONScontext* stash, const(char)[] name, ubyte* data, int dataSize, int freeData) {

	int i, ascent, descent, fh, lineGap;
	FONSfont* font;

	if (name.length == 0 || name == NoAlias) return FONS_INVALID;

	int idx = fons__allocFont(stash);
	if (idx == FONS_INVALID) return FONS_INVALID;

	font = stash.fonts[idx];

	if (name.length > font.name.length-1) { name = name[0..font.name.length-1]; }
	font.name[] = 0;
	font.name[0..name.length] = name[];
	font.namelen = cast(uint)name.length;

	// Init hash lookup.
	for (i = 0; i < FONS_HASH_LUT_SIZE; ++i) { font.lut[i] = -1; }

	// Read in the font data.
	font.dataSize = dataSize;
	font.data = data;
	font.freeData = cast(ubyte)freeData;

	if (name.length >= NoAlias.length && name[$-NoAlias.length..$] == NoAlias) {
		//{ import core.stdc.stdio : printf; printf("MONO: [%.*s]\n", cast(uint)name.length, name.ptr); }
		fons__tt_setMono(stash, &font.font, true);
	}

	// Init font
	stash.nscratch = 0;
	if (!fons__tt_loadFont(stash, &font.font, data, dataSize)) goto error;

	// Store normalized line height. The real line height is got
	// by multiplying the lineh by font size.
	fons__tt_getFontVMetrics( &font.font, &ascent, &descent, &lineGap);
	fh = ascent-descent;
	font.ascender = cast(float)ascent/cast(float)fh;
	font.descender = cast(float)descent/cast(float)fh;
	font.lineh = cast(float)(fh+lineGap)/cast(float)fh;

	return idx;

error:
	fons__freeFont(font);
	stash.nfonts--;
	return FONS_INVALID;
}

public int fonsGetFontByName (FONScontext* s, const(char)[] name) {

	foreach (immutable idx, FONSfont* font; s.fonts[0..s.nfonts]) {
		if (font.namelen == name.length && font.name[0..font.namelen] == name[]) return cast(int)idx;
	}

	// not found, try variations
	if (name.length >= NoAlias.length && name[$-NoAlias.length..$] == NoAlias) {
		// search for font name without ":noaa"
		name = name[0..$-NoAlias.length];
		foreach (immutable idx, FONSfont* font; s.fonts[0..s.nfonts]) {
			if (font.namelen == name.length && font.name[0..font.namelen] == name[]) return cast(int)idx;
		}
	} else {
		// search for font name with ":noaa"
		foreach (immutable idx, FONSfont* font; s.fonts[0..s.nfonts]) {
			if (font.namelen == name.length+NoAlias.length) {
				if (font.name[0..name.length] == name[] && font.name[name.length..font.namelen] == NoAlias) {
					//{ import std.stdio; writeln(font.name[0..name.length], " : ", name, " <", font.name[name.length..$], ">"); }
					return cast(int)idx;
				}
			}
		}
	}

	return FONS_INVALID;

}


FONSglyph* fons__allocGlyph (FONSfont* font) {

	if (font.nglyphs+1 > font.cglyphs) {
		font.cglyphs = (font.cglyphs == 0 ? 8 : font.cglyphs*2);
		font.glyphs = cast(FONSglyph*)realloc(font.glyphs, FONSglyph.sizeof*font.cglyphs);
		if (font.glyphs is null) return null;
	}

	++font.nglyphs;
	return &font.glyphs[font.nglyphs-1];

}


// Based on Exponential blur, Jani Huhtanen, 2006

enum APREC = 16;
enum ZPREC = 7;

void fons__blurCols (ubyte* dst, int w, int h, int dstStride, int alpha) {
	foreach (int y; 0..h) {
		int z = 0; // force zero border
		foreach (int x; 1..w) {
			z += (alpha*((cast(int)(dst[x])<<ZPREC)-z))>>APREC;
			dst[x] = cast(ubyte)(z>>ZPREC);
		}
		dst[w-1] = 0; // force zero border
		z = 0;
		for (int x = w-2; x >= 0; --x) {
			z += (alpha*((cast(int)(dst[x])<<ZPREC)-z))>>APREC;
			dst[x] = cast(ubyte)(z>>ZPREC);
		}
		dst[0] = 0; // force zero border
		dst += dstStride;
	}
}

void fons__blurRows (ubyte* dst, int w, int h, int dstStride, int alpha) {
	foreach (int x; 0..w) {
		int z = 0; // force zero border
		for (int y = dstStride; y < h*dstStride; y += dstStride) {
			z += (alpha*((cast(int)(dst[y])<<ZPREC)-z))>>APREC;
			dst[y] = cast(ubyte)(z>>ZPREC);
		}
		dst[(h-1)*dstStride] = 0; // force zero border
		z = 0;
		for (int y = (h-2)*dstStride; y >= 0; y -= dstStride) {
			z += (alpha*((cast(int)(dst[y])<<ZPREC)-z))>>APREC;
			dst[y] = cast(ubyte)(z>>ZPREC);
		}
		dst[0] = 0; // force zero border
		++dst;
	}
}


void fons__blur (FONScontext* stash, ubyte* dst, int w, int h, int dstStride, int blur) {
	import std.math : expf = exp;
	int alpha;
	float sigma;
	if (blur < 1) { return; }
	// Calculate the alpha such that 90% of the kernel is within the radius. (Kernel extends to infinity)
	sigma = cast(float)blur*0.57735f; // 1/sqrt(3)
	alpha = cast(int)((1<<APREC)*(1.0f-expf(-2.3f/(sigma+1.0f))));
	fons__blurRows(dst, w, h, dstStride, alpha);
	fons__blurCols(dst, w, h, dstStride, alpha);
	fons__blurRows(dst, w, h, dstStride, alpha);
	fons__blurCols(dst, w, h, dstStride, alpha);
	//fons__blurrows(dst, w, h, dstStride, alpha);
	//fons__blurcols(dst, w, h, dstStride, alpha);
}

FONSglyph* fons__getGlyph (FONScontext* stash, FONSfont* font, uint codepoint, short isize, short iblur) {

	int i, g, advance, lsb, x0, y0, x1, y1, gw, gh, gx, gy, x, y;
	float scale;
	FONSglyph* glyph = null;
	uint h;
	float size = isize/10.0f;
	int pad, added;
	ubyte* bdst;
	ubyte* dst;

	if (isize < 2) { return null; }
	if (iblur > 20) { iblur = 20; }
	pad = iblur+2;

	// Reset allocator.
	stash.nscratch = 0;

	// Find code point and size.
	h = fons__hashint(codepoint)&(FONS_HASH_LUT_SIZE-1);
	i = font.lut[h];
	while (i != -1) {
		if (font.glyphs[i].codepoint == codepoint && font.glyphs[i].size == isize && font.glyphs[i].blur == iblur) return &font.glyphs[i];
		i = font.glyphs[i].next;
	}

	// Could not find glyph, create it.
	scale = fons__tt_getPixelHeightScale(&font.font, size);
	g = fons__tt_getGlyphIndex(&font.font, codepoint);
	fons__tt_buildGlyphBitmap(&font.font, g, size, scale, &advance, &lsb, &x0, &y0, &x1, &y1);
	gw = x1-x0+pad*2;
	gh = y1-y0+pad*2;

	// Find free spot for the rect in the atlas
	added = fons__atlasAddRect(stash.atlas, gw, gh, &gx, &gy);
	if (added == 0 && stash.handleError !is null) {
		// Atlas is full, let the user to resize the atlas (or not), and try again.
		stash.handleError(stash.errorUptr, FONS_ATLAS_FULL, 0);
		added = fons__atlasAddRect(stash.atlas, gw, gh, &gx, &gy);
	}

	if (added == 0) { return null; }

	// Init glyph.
	glyph = fons__allocGlyph(font);
	glyph.codepoint = codepoint;
	glyph.size = isize;
	glyph.blur = iblur;
	glyph.index = g;
	glyph.x0 = cast(short)gx;
	glyph.y0 = cast(short)gy;
	glyph.x1 = cast(short)(glyph.x0+gw);
	glyph.y1 = cast(short)(glyph.y0+gh);
	glyph.xadv = cast(short)(scale*advance*10.0f);
	glyph.xoff = cast(short)(x0-pad);
	glyph.yoff = cast(short)(y0-pad);
	glyph.next = 0;

	// Insert char to hash lookup.
	glyph.next = font.lut[h];
	font.lut[h] = font.nglyphs-1;

	// Rasterize
	dst = &stash.texData[(glyph.x0+pad)+(glyph.y0+pad)*stash.params.width];
	fons__tt_renderGlyphBitmap(&font.font, dst, gw-pad*2, gh-pad*2, stash.params.width, scale, scale, g);

	// Make sure there is one pixel empty border.
	dst = &stash.texData[glyph.x0+glyph.y0*stash.params.width];
	for (y = 0; y < gh; y++) {
		dst[y*stash.params.width] = 0;
		dst[gw-1+y*stash.params.width] = 0;
	}
	for (x = 0; x < gw; x++) {
		dst[x] = 0;
		dst[x+(gh-1)*stash.params.width] = 0;
	}

	// Debug code to color the glyph background
	version(none) {
		ubyte* fdst = &stash.texData[glyph.x0+glyph.y0*stash.params.width];
		foreach (immutable yy; 0..gh) {
			foreach (immutable xx; 0..gw) {
				int a = cast(int)fdst[xx+yy*stash.params.width]+20;
				if (a > 255) a = 255;
				fdst[xx+yy*stash.params.width] = cast(ubyte)a;
			}
		}
	}

	// Blur
	if (iblur > 0) {
		stash.nscratch = 0;
		bdst = &stash.texData[glyph.x0+glyph.y0*stash.params.width];
		fons__blur(stash, bdst, gw, gh, stash.params.width, iblur);
	}

	stash.dirtyRect[0] = nvg__min(stash.dirtyRect[0], glyph.x0);
	stash.dirtyRect[1] = nvg__min(stash.dirtyRect[1], glyph.y0);
	stash.dirtyRect[2] = nvg__max(stash.dirtyRect[2], glyph.x1);
	stash.dirtyRect[3] = nvg__max(stash.dirtyRect[3], glyph.y1);

	return glyph;

}

void fons__getQuad (FONScontext* stash, FONSfont* font, int prevGlyphIndex, FONSglyph* glyph, float scale, float spacing, float* x, float* y, FONSquad* q) {

	float rx, ry, xoff, yoff, x0, y0, x1, y1;

	if (prevGlyphIndex >= 0) {
		float adv = fons__tt_getGlyphKernAdvance(&font.font, prevGlyphIndex, glyph.index)*scale;
		*x += cast(int)(adv+spacing+0.5f);
	}

	// Each glyph has 2px border to allow good interpolation,
	// one pixel to prevent leaking, and one to allow good interpolation for rendering.
	// Inset the texture region by one pixel for correct interpolation.
	xoff = cast(short)(glyph.xoff+1);
	yoff = cast(short)(glyph.yoff+1);
	x0 = cast(float)(glyph.x0+1);
	y0 = cast(float)(glyph.y0+1);
	x1 = cast(float)(glyph.x1-1);
	y1 = cast(float)(glyph.y1-1);

	if (stash.params.flags&FONS_ZERO_TOPLEFT) {
		rx = cast(float)cast(int)(*x+xoff);
		ry = cast(float)cast(int)(*y+yoff);

		q.x0 = rx;
		q.y0 = ry;
		q.x1 = rx+x1-x0;
		q.y1 = ry+y1-y0;

		q.s0 = x0*stash.itw;
		q.t0 = y0*stash.ith;
		q.s1 = x1*stash.itw;
		q.t1 = y1*stash.ith;
	} else {
		rx = cast(float)cast(int)(*x+xoff);
		ry = cast(float)cast(int)(*y-yoff);

		q.x0 = rx;
		q.y0 = ry;
		q.x1 = rx+x1-x0;
		q.y1 = ry-y1+y0;

		q.s0 = x0*stash.itw;
		q.t0 = y0*stash.ith;
		q.s1 = x1*stash.itw;
		q.t1 = y1*stash.ith;
	}

	*x += cast(int)(glyph.xadv/10.0f+0.5f);
}

void fons__flush (FONScontext* stash) {
	// Flush texture
	if (stash.dirtyRect[0] < stash.dirtyRect[2] && stash.dirtyRect[1] < stash.dirtyRect[3]) {
		if (stash.params.renderUpdate !is null) stash.params.renderUpdate(stash.params.userPtr, stash.dirtyRect.ptr, stash.texData);
		// Reset dirty rect
		stash.dirtyRect[0] = stash.params.width;
		stash.dirtyRect[1] = stash.params.height;
		stash.dirtyRect[2] = 0;
		stash.dirtyRect[3] = 0;
	}

	// Flush triangles
	if (stash.nverts > 0) {
		if (stash.params.renderDraw !is null) stash.params.renderDraw(stash.params.userPtr, stash.verts.ptr, stash.tcoords.ptr, stash.colors.ptr, stash.nverts);
		stash.nverts = 0;
	}
}

void fons__vertex (FONScontext* stash, float x, float y, float s, float t, uint c) {
	stash.verts[stash.nverts*2+0] = x;
	stash.verts[stash.nverts*2+1] = y;
	stash.tcoords[stash.nverts*2+0] = s;
	stash.tcoords[stash.nverts*2+1] = t;
	stash.colors[stash.nverts] = c;
	++stash.nverts;
}

float fons__getVertAlign (FONScontext* stash, FONSfont* font, FonsTextAlign talign, short isize) {
	if (stash.params.flags&FONS_ZERO_TOPLEFT) {
		final switch (talign.vertical) {
			case FonsTextAlign.V.Top: return font.ascender*cast(float)isize/10.0f;
			case FonsTextAlign.V.Middle: return (font.ascender+font.descender)/2.0f*cast(float)isize/10.0f;
			case FonsTextAlign.V.Baseline: return 0.0f;
			case FonsTextAlign.V.Bottom: return font.descender*cast(float)isize/10.0f;
		}
	} else {
		final switch (talign.vertical) {
			case FonsTextAlign.V.Top: return -font.ascender*cast(float)isize/10.0f;
			case FonsTextAlign.V.Middle: return -(font.ascender+font.descender)/2.0f*cast(float)isize/10.0f;
			case FonsTextAlign.V.Baseline: return 0.0f;
			case FonsTextAlign.V.Bottom: return -font.descender*cast(float)isize/10.0f;
		}
	}
	assert(0);
}

public bool fonsTextIterInit(T) (FONScontext* stash, FONStextIter* iter, float x, float y, const(T)[] str) if (is(T == char) || is(T == dchar)) {

	if (stash is null || iter is null) return false;

	FONSstate* state = fons__getState(stash);
	float width;

	memset(iter, 0, (*iter).sizeof);

	if (stash is null) return false;
	if (state.font < 0 || state.font >= stash.nfonts) return false;
	iter.font = stash.fonts[state.font];
	if (iter.font.data is null) return false;

	iter.isize = cast(short)(state.size*10.0f);
	iter.iblur = cast(short)state.blur;
	iter.scale = fons__tt_getPixelHeightScale(&iter.font.font, cast(float)iter.isize/10.0f);

	// Align horizontally
	if (state.talign.left) {
		// empty
	} else if (state.talign.right) {
		width = fonsTextBounds(stash, x, y, str, null);
		x -= width;
	} else if (state.talign.center) {
		width = fonsTextBounds(stash, x, y, str, null);
		x -= width*0.5f;
	}
	// Align vertically.
	y += fons__getVertAlign(stash, iter.font, state.talign, iter.isize);

	iter.x = iter.nextx = x;
	iter.y = iter.nexty = y;
	iter.spacing = state.spacing;
	static if (is(T == char)) {
		if (str.ptr is null) str = "";
		iter.str = str.ptr;
		iter.next = str.ptr;
		iter.end = str.ptr+str.length;
		iter.isChar = true;
	} else {
		iter.dstr = str.ptr;
		iter.dnext = str.ptr;
		iter.dend = str.ptr+str.length;
		iter.isChar = false;
	}
	iter.codepoint = 0;
	iter.prevGlyphIndex = -1;

	return true;

}

public bool fonsTextIterNext (FONScontext* stash, FONStextIter* iter, FONSquad* quad) {

	if (stash is null || iter is null) return false;
	FONSglyph* glyph = null;

	if (iter.isChar) {
		const(char)* str = iter.next;
		iter.str = iter.next;
		if (str is iter.end) return false;
		const(char)*e = iter.end;
		for (; str !is e; ++str) {
			/*if (fons__decutf8(&iter.utf8state, &iter.codepoint, *cast(const(ubyte)*)str)) continue;*/
			mixin(DecUtfMixin!("iter.utf8state", "iter.codepoint", "*cast(const(ubyte)*)str"));
			if (iter.utf8state) continue;
			++str; // 'cause we'll break anyway
			// get glyph and quad
			iter.x = iter.nextx;
			iter.y = iter.nexty;
			glyph = fons__getGlyph(stash, iter.font, iter.codepoint, iter.isize, iter.iblur);
			if (glyph !is null) {
				fons__getQuad(stash, iter.font, iter.prevGlyphIndex, glyph, iter.scale, iter.spacing, &iter.nextx, &iter.nexty, quad);
				iter.prevGlyphIndex = glyph.index;
			} else {
				iter.prevGlyphIndex = -1;
			}
			break;
		}
		iter.next = str;
	} else {
		const(dchar)* str = iter.dnext;
		iter.dstr = iter.dnext;
		if (str is iter.dend) return false;
		iter.codepoint = cast(uint)(*str++);
		if (iter.codepoint > dchar.max) iter.codepoint = '?';
		// Get glyph and quad
		iter.x = iter.nextx;
		iter.y = iter.nexty;
		glyph = fons__getGlyph(stash, iter.font, iter.codepoint, iter.isize, iter.iblur);
		if (glyph !is null) {
			fons__getQuad(stash, iter.font, iter.prevGlyphIndex, glyph, iter.scale, iter.spacing, &iter.nextx, &iter.nexty, quad);
			iter.prevGlyphIndex = glyph.index;
		} else {
			iter.prevGlyphIndex = -1;
		}
		iter.dnext = str;
	}

	return true;

}

debug public void fonsDrawDebug (FONScontext* stash, float x, float y) {

	int i;
	int w = stash.params.width;
	int h = stash.params.height;
	float u = (w == 0 ? 0 : 1.0f/w);
	float v = (h == 0 ? 0 : 1.0f/h);

	if (stash.nverts+6+6 > FONS_VERTEX_COUNT) fons__flush(stash);

	// Draw background
	fons__vertex(stash, x+0, y+0, u, v, 0x0fffffff);
	fons__vertex(stash, x+w, y+h, u, v, 0x0fffffff);
	fons__vertex(stash, x+w, y+0, u, v, 0x0fffffff);

	fons__vertex(stash, x+0, y+0, u, v, 0x0fffffff);
	fons__vertex(stash, x+0, y+h, u, v, 0x0fffffff);
	fons__vertex(stash, x+w, y+h, u, v, 0x0fffffff);

	// Draw texture
	fons__vertex(stash, x+0, y+0, 0, 0, 0xffffffff);
	fons__vertex(stash, x+w, y+h, 1, 1, 0xffffffff);
	fons__vertex(stash, x+w, y+0, 1, 0, 0xffffffff);

	fons__vertex(stash, x+0, y+0, 0, 0, 0xffffffff);
	fons__vertex(stash, x+0, y+h, 0, 1, 0xffffffff);
	fons__vertex(stash, x+w, y+h, 1, 1, 0xffffffff);

	// Drawbug draw atlas
	for (i = 0; i < stash.atlas.nnodes; i++) {
		FONSatlasNode* n = &stash.atlas.nodes[i];

		if (stash.nverts+6 > FONS_VERTEX_COUNT)
			fons__flush(stash);

		fons__vertex(stash, x+n.x+0, y+n.y+0, u, v, 0xc00000ff);
		fons__vertex(stash, x+n.x+n.width, y+n.y+1, u, v, 0xc00000ff);
		fons__vertex(stash, x+n.x+n.width, y+n.y+0, u, v, 0xc00000ff);

		fons__vertex(stash, x+n.x+0, y+n.y+0, u, v, 0xc00000ff);
		fons__vertex(stash, x+n.x+0, y+n.y+1, u, v, 0xc00000ff);
		fons__vertex(stash, x+n.x+n.width, y+n.y+1, u, v, 0xc00000ff);
	}

	fons__flush(stash);

}

public struct FonsTextBoundsIterator {
	private:
		FONScontext* stash;
		FONSstate* state;
		uint codepoint;
		uint utf8state = 0;
		FONSquad q;
		FONSglyph* glyph = null;
		int prevGlyphIndex = -1;
		short isize, iblur;
		float scale;
		FONSfont* font;
		float startx, x, y;
		float minx, miny, maxx, maxy;

	public:
		this (FONScontext* astash, float ax, float ay) { reset(astash, ax, ay); }

		void reset (FONScontext* astash, float ax, float ay) {
			this = this.init;
			if (astash is null) return;
			stash = astash;
			state = fons__getState(stash);
			if (state is null) { stash = null; return; } // alas

			x = ax;
			y = ay;

			isize = cast(short)(state.size*10.0f);
			iblur = cast(short)state.blur;

			if (state.font < 0 || state.font >= stash.nfonts) { stash = null; return; }
			font = stash.fonts[state.font];
			if (font.data is null) { stash = null; return; }

			scale = fons__tt_getPixelHeightScale(&font.font, cast(float)isize/10.0f);

			// align vertically
			y += fons__getVertAlign(stash, font, state.talign, isize);

			minx = maxx = x;
			miny = maxy = y;
			startx = x;
			//assert(prevGlyphIndex == -1);
		}

	public:
		@property bool valid () const pure nothrow @safe @nogc { pragma(inline, true); return (state !is null); }

		void put(T) (const(T)[] str...) if (is(T == char) || is(T == dchar)) {
			enum DoCodePointMixin = q{
				glyph = fons__getGlyph(stash, font, codepoint, isize, iblur);
				if (glyph !is null) {
					fons__getQuad(stash, font, prevGlyphIndex, glyph, scale, state.spacing, &x, &y, &q);
					if (q.x0 < minx) minx = q.x0;
					if (q.x1 > maxx) maxx = q.x1;
					if (stash.params.flags&FONS_ZERO_TOPLEFT) {
						if (q.y0 < miny) miny = q.y0;
						if (q.y1 > maxy) maxy = q.y1;
					} else {
						if (q.y1 < miny) miny = q.y1;
						if (q.y0 > maxy) maxy = q.y0;
					}
					prevGlyphIndex = glyph.index;
				} else {
					prevGlyphIndex = -1;
				}
			};

			if (state is null) return; // alas
			static if (is(T == char)) {
				foreach (char ch; str) {
					mixin(DecUtfMixin!("utf8state", "codepoint", "cast(ubyte)ch"));
					if (utf8state) continue; // full char is not collected yet
					mixin(DoCodePointMixin);
				}
			} else {
				if (str.length == 0) return;
				if (utf8state) {
					utf8state = 0;
					codepoint = '?';
					mixin(DoCodePointMixin);
				}
				foreach (dchar dch; str) {
					if (dch > dchar.max) dch = '?';
					codepoint = cast(uint)dch;
					mixin(DoCodePointMixin);
				}
			}
		}

		// return current advance
		@property float advance () const pure nothrow @safe @nogc { pragma(inline, true); return (state !is null ? x-startx : 0); }

		void getBounds (ref float[4] bounds) const pure nothrow @safe @nogc {
			if (state is null) { bounds[] = 0; return; }
			float lminx = minx, lmaxx = maxx;
			// align horizontally
			if (state.talign.left) {
				// empty
			} else if (state.talign.right) {
				float ca = advance;
				lminx -= ca;
				lmaxx -= ca;
			} else if (state.talign.center) {
				float ca = advance*0.5f;
				lminx -= ca;
				lmaxx -= ca;
			}
			bounds[0] = lminx;
			bounds[1] = miny;
			bounds[2] = lmaxx;
			bounds[3] = maxy;
		}

		// Return current horizontal text bounds.
		void getHBounds (out float xmin, out float xmax) {
			if (state !is null) {
				float lminx = minx, lmaxx = maxx;
				// align horizontally
				if (state.talign.left) {
					// empty
				} else if (state.talign.right) {
					float ca = advance;
					lminx -= ca;
					lmaxx -= ca;
				} else if (state.talign.center) {
					float ca = advance*0.5f;
					lminx -= ca;
					lmaxx -= ca;
				}
				xmin = lminx;
				xmax = lmaxx;
			}
		}

		// Return current vertical text bounds.
		void getVBounds (out float ymin, out float ymax) {
			if (state !is null) {
				ymin = miny;
				ymax = maxy;
			}
		}
}

public float fonsTextBounds(T) (FONScontext* stash, float x, float y, const(T)[] str, float[] bounds) if (is(T == char) || is(T == dchar)) {

	FONSstate* state = fons__getState(stash);
	uint codepoint;
	uint utf8state = 0;
	FONSquad q;
	FONSglyph* glyph = null;
	int prevGlyphIndex = -1;
	short isize = cast(short)(state.size*10.0f);
	short iblur = cast(short)state.blur;
	float scale;
	FONSfont* font;
	float startx, advance;
	float minx, miny, maxx, maxy;

	if (stash is null) return 0;
	if (state.font < 0 || state.font >= stash.nfonts) return 0;
	font = stash.fonts[state.font];
	if (font.data is null) return 0;

	scale = fons__tt_getPixelHeightScale(&font.font, cast(float)isize/10.0f);

	// Align vertically.
	y += fons__getVertAlign(stash, font, state.talign, isize);

	minx = maxx = x;
	miny = maxy = y;
	startx = x;

	static if (is(T == char)) {
		foreach (char ch; str) {
			//if (fons__decutf8(&utf8state, &codepoint, *cast(const(ubyte)*)str)) continue;
			mixin(DecUtfMixin!("utf8state", "codepoint", "(cast(ubyte)ch)"));
			if (utf8state) continue;
			glyph = fons__getGlyph(stash, font, codepoint, isize, iblur);
			if (glyph !is null) {
				fons__getQuad(stash, font, prevGlyphIndex, glyph, scale, state.spacing, &x, &y, &q);
				if (q.x0 < minx) minx = q.x0;
				if (q.x1 > maxx) maxx = q.x1;
				if (stash.params.flags&FONS_ZERO_TOPLEFT) {
					if (q.y0 < miny) miny = q.y0;
					if (q.y1 > maxy) maxy = q.y1;
				} else {
					if (q.y1 < miny) miny = q.y1;
					if (q.y0 > maxy) maxy = q.y0;
				}
				prevGlyphIndex = glyph.index;
			} else {
				prevGlyphIndex = -1;
			}
		}
	} else {
		foreach (dchar ch; str) {
			if (ch > dchar.max) ch = '?';
			codepoint = cast(uint)ch;
			glyph = fons__getGlyph(stash, font, codepoint, isize, iblur);
			if (glyph !is null) {
				fons__getQuad(stash, font, prevGlyphIndex, glyph, scale, state.spacing, &x, &y, &q);
				if (q.x0 < minx) minx = q.x0;
				if (q.x1 > maxx) maxx = q.x1;
				if (stash.params.flags&FONS_ZERO_TOPLEFT) {
					if (q.y0 < miny) miny = q.y0;
					if (q.y1 > maxy) maxy = q.y1;
				} else {
					if (q.y1 < miny) miny = q.y1;
					if (q.y0 > maxy) maxy = q.y0;
				}
				prevGlyphIndex = glyph.index;
			} else {
				prevGlyphIndex = -1;
			}
		}
	}

	advance = x-startx;

	// Align horizontally
	if (state.talign.left) {
		// empty
	} else if (state.talign.right) {
		minx -= advance;
		maxx -= advance;
	} else if (state.talign.center) {
		minx -= advance*0.5f;
		maxx -= advance*0.5f;
	}

	if (bounds.length) {
		if (bounds.length > 0) bounds.ptr[0] = minx;
		if (bounds.length > 1) bounds.ptr[1] = miny;
		if (bounds.length > 2) bounds.ptr[2] = maxx;
		if (bounds.length > 3) bounds.ptr[3] = maxy;
	}

	return advance;

}

public void fonsVertMetrics (FONScontext* stash, float* ascender, float* descender, float* lineh) {
	FONSfont* font;
	FONSstate* state = fons__getState(stash);
	short isize;

	if (stash is null) return;
	if (state.font < 0 || state.font >= stash.nfonts) return;
	font = stash.fonts[state.font];
	isize = cast(short)(state.size*10.0f);
	if (font.data is null) return;

	if (ascender) *ascender = font.ascender*isize/10.0f;
	if (descender) *descender = font.descender*isize/10.0f;
	if (lineh) *lineh = font.lineh*isize/10.0f;
}

public void fonsLineBounds (FONScontext* stash, float y, float* miny, float* maxy) {
	FONSfont* font;
	FONSstate* state = fons__getState(stash);
	short isize;

	if (stash is null) return;
	if (state.font < 0 || state.font >= stash.nfonts) return;
	font = stash.fonts[state.font];
	isize = cast(short)(state.size*10.0f);
	if (font.data is null) return;

	y += fons__getVertAlign(stash, font, state.talign, isize);

	if (stash.params.flags&FONS_ZERO_TOPLEFT) {
		*miny = y-font.ascender*cast(float)isize/10.0f;
		*maxy = *miny+font.lineh*isize/10.0f;
	} else {
		*maxy = y+font.descender*cast(float)isize/10.0f;
		*miny = *maxy-font.lineh*isize/10.0f;
	}
}

public const(ubyte)* fonsGetTextureData (FONScontext* stash, int* width, int* height) {
	if (width !is null) *width = stash.params.width;
	if (height !is null) *height = stash.params.height;
	return stash.texData;
}

public int fonsValidateTexture (FONScontext* stash, int* dirty) {
	if (stash.dirtyRect[0] < stash.dirtyRect[2] && stash.dirtyRect[1] < stash.dirtyRect[3]) {
		dirty[0] = stash.dirtyRect[0];
		dirty[1] = stash.dirtyRect[1];
		dirty[2] = stash.dirtyRect[2];
		dirty[3] = stash.dirtyRect[3];
		// Reset dirty rect
		stash.dirtyRect[0] = stash.params.width;
		stash.dirtyRect[1] = stash.params.height;
		stash.dirtyRect[2] = 0;
		stash.dirtyRect[3] = 0;
		return 1;
	}
	return 0;
}

public void fonsDeleteInternal (FONScontext* stash) {
	if (stash is null) return;

	if (stash.params.renderDelete) stash.params.renderDelete(stash.params.userPtr);

	foreach (int i; 0..stash.nfonts) fons__freeFont(stash.fonts[i]);

	if (stash.atlas) fons__deleteAtlas(stash.atlas);
	if (stash.fonts) free(stash.fonts);
	if (stash.texData) free(stash.texData);
	if (stash.scratch) free(stash.scratch);
	free(stash);
}

public void fonsSetErrorCallback (FONScontext* stash, void function (void* uptr, int error, int val) callback, void* uptr) {
	if (stash is null) return;
	stash.handleError = callback;
	stash.errorUptr = uptr;
}

public void fonsGetAtlasSize (FONScontext* stash, int* width, int* height) {
	if (stash is null) return;
	*width = stash.params.width;
	*height = stash.params.height;
}

public int fonsExpandAtlas (FONScontext* stash, int width, int height) {

	int i, maxy = 0;
	ubyte* data = null;
	if (stash is null) return 0;

	width = nvg__max(width, stash.params.width);
	height = nvg__max(height, stash.params.height);

	if (width == stash.params.width && height == stash.params.height) return 1;

	// Flush pending glyphs.
	fons__flush(stash);

	// Create new texture
	if (stash.params.renderResize !is null) {
		if (stash.params.renderResize(stash.params.userPtr, width, height) == 0) return 0;
	}
	// Copy old texture data over.
	data = cast(ubyte*)malloc(width*height);
	if (data is null) return 0;
	for (i = 0; i < stash.params.height; i++) {
		ubyte* dst = &data[i*width];
		ubyte* src = &stash.texData[i*stash.params.width];
		memcpy(dst, src, stash.params.width);
		if (width > stash.params.width)
			memset(dst+stash.params.width, 0, width-stash.params.width);
	}
	if (height > stash.params.height) memset(&data[stash.params.height*width], 0, (height-stash.params.height)*width);

	free(stash.texData);
	stash.texData = data;

	// Increase atlas size
	fons__atlasExpand(stash.atlas, width, height);

	// Add existing data as dirty.
	for (i = 0; i < stash.atlas.nnodes; i++) maxy = nvg__max(maxy, stash.atlas.nodes[i].y);
	stash.dirtyRect[0] = 0;
	stash.dirtyRect[1] = 0;
	stash.dirtyRect[2] = stash.params.width;
	stash.dirtyRect[3] = maxy;

	stash.params.width = width;
	stash.params.height = height;
	stash.itw = 1.0f/stash.params.width;
	stash.ith = 1.0f/stash.params.height;

	return 1;

}

public int fonsResetAtlas (FONScontext* stash, int width, int height) {

	int i, j;
	if (stash is null) return 0;

	// Flush pending glyphs.
	fons__flush(stash);

	// Create new texture
	if (stash.params.renderResize !is null) {
		if (stash.params.renderResize(stash.params.userPtr, width, height) == 0) return 0;
	}

	// Reset atlas
	fons__atlasReset(stash.atlas, width, height);

	// Clear texture data.
	stash.texData = cast(ubyte*)realloc(stash.texData, width*height);
	if (stash.texData is null) return 0;
	memset(stash.texData, 0, width*height);

	// Reset dirty rect
	stash.dirtyRect[0] = width;
	stash.dirtyRect[1] = height;
	stash.dirtyRect[2] = 0;
	stash.dirtyRect[3] = 0;

	// Reset cached glyphs
	for (i = 0; i < stash.nfonts; i++) {
		FONSfont* font = stash.fonts[i];
		font.nglyphs = 0;
		for (j = 0; j < FONS_HASH_LUT_SIZE; j++) font.lut[j] = -1;
	}

	stash.params.width = width;
	stash.params.height = height;
	stash.itw = 1.0f/stash.params.width;
	stash.ith = 1.0f/stash.params.height;

	// Add white rect at 0, 0 for debug drawing.
	fons__addWhiteRect(stash, 2, 2);

	return 1;

}
