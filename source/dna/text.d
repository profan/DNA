module dna.text;

import core.stdc.stdio : printf;

import std.algorithm.mutation : move;
import std.typecons : tuple;
import std.algorithm : max;

import derelict.freetype.ft;

import gland.util;
import gland.win;
import gland.gl;

private {

	immutable char* vs_shader = q{
		#version 330 core

		uniform mat4 projection;

		layout (location = 0) in vec4 coord;

		out vec2 tex_coord;

		void main() {
			gl_Position = projection * vec4(coord.xy, 0.0, 1.0);
			tex_coord = coord.zw;
		}
	};

	immutable char* fs_shader = q{
		#version 330 core

		in vec2 tex_coord;

		uniform sampler2D tex;
		uniform vec4 colour;

		void main() {
			gl_FragColor = vec4(colour.rgb, texture2D(tex, tex_coord).r);
		}
	};

	alias Mat4f = float[4][4];
	alias Vec4f = float[4];

	struct Vertex4f {
		Vec4f coord;
		alias coord this;
	} // Vertex4f

	struct TextUniform {

		Mat4f[] projection;
		float[4] colour;

		@TextureUnit(0)
		Texture2D* tex;

	} // TextUniform

	alias TextShader = Shader!(
		[ShaderType.VertexShader, ShaderType.FragmentShader], [
			AttribTuple("coord", 0)
		], TextUniform
	);

	@(DrawType.DrawArrays)
	struct TextData {

		@(DrawHint.StaticDraw)
		@(BufferTarget.ArrayBuffer)
		@VertexCountProvider
		Vertex4f[] vertices;

	} // TextData

	alias TextVao = VertexArrayT!TextData;

}

struct FontAtlas {

	private struct CharacterInfo {

		float advance_x; // advance.x
		float advance_y; // advance.y

		float bitmap_width; // bitmap.width;
		float bitmap_height; // bitmap.rows;

		float bitmap_left; // bitmap_left;
		float bitmap_top; // bitmap_top;

		float tx_offset; // x offset of glyph in texture coordinates
		float tx_offset_y;

	} //CharacterInfo

	enum Error {
		Success = "FontAtlas successfully created.",
		CouldNotOpenFont = "FreeType could not open font!"
	} // Error

	private {
		
		// FT LIB, this should probably go elsewhere, for now it is here
		static FT_Library ft_;

		// text shader shite
		static TextShader text_shader_;

		TextVao vertices_;
		TextShader shader_;
		Texture2D texture_;

		CharacterInfo[96] chars_;

		int atlas_width_;
		int atlas_height_;

		int char_width_;
		int char_height_;

	}

	static void load() {

		shared static bool is_initialized = false;
		if (is_initialized) return;

		import derelict.util.exception;
		
		ShouldThrow ignoreMissing(string symbolName) {
		
			if (symbolName == "FT_Stream_OpenBzip2" ||
				symbolName == "FT_Get_CID_Registry_Ordering_Supplement" ||
				symbolName == "FT_Get_CID_Is_Internally_CID_Keyed" ||
				symbolName == "FT_Get_CID_From_Glyph_Index") {
				return ShouldThrow.No;
			}
			
			return ShouldThrow.Yes;
		
		}

		DerelictFT.missingSymbolCallback = &ignoreMissing;
		DerelictFT.load();
		
		// load FreeType library
		if (FT_Init_FreeType(&ft_)) { //TODO move this
			printf("[FontAtlas] Could not init freetype.");
		}

		// load graphics and stuff
		auto shader_result = TextShader.compile(text_shader_, &vs_shader, &fs_shader);

		if (shader_result != TextShader.Error.Success) {
			printf("[FontAtlas] Shader compile failed, exiting!");
			return; // exit now
		}

		is_initialized = true;

	} // load
	
	static unload() {
		
		FT_Done_FreeType(ft_);
		
	} // unload

	static Error create(ref FontAtlas atlas, in char* font_name, int font_size) {

		// loadan libs
		FontAtlas.load();

		// freetype shit
		FT_Face face;

		if (FT_New_Face(ft_, font_name, 0, &face)) {
			printf("[FontAtlas] Could not open font.");
			return Error.CouldNotOpenFont;
		}

		scope(exit) {
			FT_Done_Face(face);
		}

		FT_Set_Pixel_Sizes(face, 0, font_size);
		FT_GlyphSlot glyph = face.glyph;

		int w = 0, h = 0;
		for (uint i = 32; i < 128; ++i) {

			if (FT_Load_Char(face, i, FT_LOAD_RENDER)) {
				printf("[FontAtlas] Character %c failed to load.", i);
				continue;
			}

			w += glyph.bitmap.width;
			h = max(h, glyph.bitmap.rows);

			atlas.atlas_width_ = w;
			atlas.atlas_height_ = h;

		}

		TextureParams params = {
			internal_format : InternalTextureFormat.R8,
			pixel_format : PixelFormat.Red,
			unpack_alignment : PixelPack.One,
			filtering : TextureFiltering.Linear,
			wrapping : TextureWrapping.ClampToEdge
		};

		auto texture_result = Texture2D.create(atlas.texture_, cast(ubyte*)null, w, h, params);

		int x = 0; // current x position in the resulting texture to write to
		for (uint i = 32; i < 128; ++i) {

			if (FT_Load_Char(face, i, FT_LOAD_RENDER)) {
				continue;
			}

			float top_distance = face.glyph.metrics.horiBearingY; //used to adjust for eventual hang

			atlas.texture_.update(x, 0, glyph.bitmap.width, glyph.bitmap.rows, glyph.bitmap.buffer);

			int ci = i - 32;
			atlas.chars_[ci].advance_x = glyph.advance.x >> 6;
			atlas.chars_[ci].advance_y = glyph.advance.y >> 6;

			atlas.chars_[ci].bitmap_width = glyph.bitmap.width;
			atlas.chars_[ci].bitmap_height = glyph.bitmap.rows;

			atlas.chars_[ci].bitmap_left = glyph.bitmap_left;
			atlas.chars_[ci].bitmap_top = glyph.bitmap_top;

			atlas.chars_[ci].tx_offset = cast(float)x / w;
			atlas.chars_[ci].tx_offset_y = (top_distance/64 - (face.glyph.metrics.height>>6));

			x += glyph.bitmap.width; // adjust x position by the width of the current bitmap

		}

		// TODO document this part
		atlas.char_width_ = cast(typeof(char_width_))face.glyph.metrics.width >> 6;
		atlas.char_height_ = cast(typeof(char_height_))face.glyph.metrics.height >> 6;

		/**
		 * EVERYTHING ELSE
		*/

		TextData data;
		auto vao = TextVao.upload(data, DrawPrimitive.Triangles);
		move(vao, atlas.vertices_);

		return Error.Success;

	} // create

	void renderText(DeviceType)(ref DeviceType device, Mat4f[] projection_data, in char[] text, float x, float y, float sx, float sy, int colour) 
		if (isDevice!DeviceType) {

		import core.stdc.stdlib : malloc, free;
		Vertex4f[] coords = (cast(Vertex4f*)malloc(Vertex4f.sizeof * (text.length * 6)))[0..text.length*6];
		scope(exit) { free(cast(void*)coords.ptr); }

		int n = 0; // current index into coords
		foreach (ch; text) {

			if (ch < 32 || ch > 127) {
				continue;
			}

			int ci = ch - 32; // char index into chars_ array

			float x2 =  x + chars_[ci].bitmap_left * sx;
			float y2 = y + chars_[ci].bitmap_top * sy;

			float w = chars_[ci].bitmap_width * sx;
			float h = chars_[ci].bitmap_height * sy;

			x += chars_[ci].advance_x * sx;
			y += chars_[ci].advance_y * sy;

			// adjust for hang
			y2 -= (chars_[ci].bitmap_top * sy);
			y2 -= (chars_[ci].tx_offset_y * sy);

			if (!w || !h) { // continue if no width or height, invisible character
				continue;
			}

			coords[n++] = [x2, y2, chars_[ci].tx_offset, chars_[ci].bitmap_height / atlas_height_]; //top left?
			coords[n++] = [x2, y2 - h, chars_[ci].tx_offset, 0];

			coords[n++] = [x2 + w, y2, chars_[ci].tx_offset + chars_[ci].bitmap_width / atlas_width_, chars_[ci].bitmap_height / atlas_height_];
			coords[n++] = [x2 + w, y2, chars_[ci].tx_offset + chars_[ci].bitmap_width / atlas_width_, chars_[ci].bitmap_height / atlas_height_];

			coords[n++] = [x2, y2 - h, chars_[ci].tx_offset, 0];
			coords[n++] = [x2 + w, y2 - h, chars_[ci].tx_offset + chars_[ci].bitmap_width / atlas_width_, 0];

		}

		DrawParams params = {
			blend_src : BlendFunc.SrcAlpha,
			blend_dst : BlendFunc.OneMinusSrcAlpha,
			state: {
				blend_test : true,
				cull_face : false,
				depth_test : false
			}
		};

		// passes new vertex data to the vertex buffer
		auto new_coords = TextData(coords);
		TextVao.update(vertices_, new_coords, DrawPrimitive.Triangles);
		
		// do the drawings
		auto uniform_data = TextUniform(projection_data, to!GLColour(colour), &texture_);
		device.draw(text_shader_, vertices_, params, uniform_data);

	} // renderText

} // FontAtlas
