module dna.unitext;

import core.stdc.stdio : printf;
import core.stdc.stdlib : malloc;

import dna.ports.fontstash;
import gland;

private {

	immutable char* vs_shader = q{
		#version 330 core

		layout (location = 0) in vec4 coord;
		layout (location = 1) in vec4 colour;

		out vec4 fs_colour;
		out vec2 tex_coord;

		void main() {
			gl_Position = projection * vec4(coord.xy, 0.0, 1.0);
			tex_coord = coord.zw;
			fs_colour = colour;
		}
	};

	immutable char* fs_shader = q{
		#version 330 core

		in vec2 tex_coord;
		in vec4 fs_colour;

		uniform sampler2D tex;

		void main() {
			gl_FragColor = vec4(fs_colour.rgb, texture2D(tex, tex_coord).r);
		}
	};

	alias Mat4f = float[4][4];
	alias Vec4f = float[4];

	struct Vertex4f {

		Vec4f coord;

		@Normalized
		ubyte[4] colour;

	} // Vertex4f

	struct TextUniform {

		@TextureUnit(0)
		Texture2D* tex;

	} // TextUniform

	alias TextShader = Shader!(
		[ShaderType.VertexShader, ShaderType.FragmentShader], [
			AttribTuple("coord", 0),
			AttribTuple("colour", 1)
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

struct FontParams {

	// font size
	float size;

	// font colour
	uint colour;

	// font spacing
	float spacing;

	// font blur
	float blur;

	// font alignment
	FonsTextAlign talign;

} // FontParams

struct FontAtlas {

	private {

		Context context_;

		// fontstash state
		FONScontext* internal_context_;

		// shader
		TextShader shader_;

	}

	static struct Context {

		// graphics device
		Device* device;

		// shader too
		TextShader* shader;

		// context data
		int width, height;
		Texture2D tex;
		TextVao vao;

	} // Context

	enum Error {
		Success
	} // Error

	enum DEFAULT_WIDTH = 256;
	enum DEFAULT_HEIGHT = 256;

	@disable this(this);
	@disable ref typeof(this) opAssign(ref typeof(this));

	Error create(ref FontAtlas atlas, Device* device, const char* font_name, FontParams font_params) {

		if (font_params.size == font_params.size.init) assert(0, "params.size must be set!");

		FONSparams params;

		params.width = DEFAULT_WIDTH;
		params.height = DEFAULT_HEIGHT;
		params.flags = 0;
		params.renderCreate = &renderCreate;
		params.renderResize = &renderResize;
		params.renderUpdate = &renderUpdate;
		params.renderDraw = &renderDraw;
		params.renderDelete = &renderDelete;
		params.userPtr = &context_;

		// set up device in context
		context_.device = device;

		// shader in context
		auto shader_result = TextShader.compile(atlas.shader_, &vs_shader, &fs_shader);

		atlas.internal_context_ = fonsCreateInternal(&params);

		return Error.Success;

	} // params

	~this() {

		fonsDeleteInternal(internal_context_);

	} // ~this

	nothrow @nogc {

		static bool renderCreate(void* userdata, int width, int height) {

			import std.algorithm.mutation : move;

			auto ctx = cast(Context*)userdata;

			TextureParams params = {

				internal_format : InternalTextureFormat.R8,
				pixel_format : PixelFormat.Red,
				unpack_alignment : PixelPack.One,
				filtering : TextureFiltering.Linear,
				wrapping : TextureWrapping.ClampToEdge

			};

			Texture2D new_texture;
			auto tex_err = Texture2D.create(new_texture, cast(ubyte*)null, width, height, params);
			move(new_texture, ctx.tex);

			TextData data;
			auto vao = TextVao.upload(data, DrawPrimitive.Triangles);
			move(vao, ctx.vao);

			return 0;

		} // renderCreate

		static int renderResize(void* userdata, int width, int height) {

			auto res = renderCreate(userdata, width, height);
			return cast(int)res;

		} // renderResize

		static void renderUpdate(void* userdata, int* rect, const(ubyte)* data) {

			auto ctx = cast(Context*)userdata;

			int w = rect[2] - rect[0];
			int h = rect[3] - rect[1];

			ctx.tex.update(rect[0], rect[1], w, h, data);

		} // renderUpdate

		static void renderDraw(void* userdata, const(float)* verts, const(float)* tcoords, const(uint)* colors, int nverts) {

			auto ctx = cast(Context*)userdata;

			DrawParams params = {};

			TextUniform uniform = { tex : &ctx.tex };
			(*ctx.device).draw(*ctx.shader, ctx.vao, params, uniform);

		} // renderDraw

		static void renderDelete(void* userdata) {

			auto ctx = cast(Context*)userdata;

		} // renderDelete

	}

} // FontAtlas
