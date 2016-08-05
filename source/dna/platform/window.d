module dna.platform.window;

import core.stdc.stdio;
import core.stdc.stdlib : exit;
import std.typecons : tuple;

import derelict.sdl2.sdl;
import glad.gl.loader;
import glad.gl.gl;

struct Window {

	enum Error {

		Success = "Window Creation Succeeded!",
		WindowCreationFailed = "Failed to create window!",
		ContextCreationFailed = "Failed to create OpenGL context of at least version 3.3!"

	} // Error

	private {
		
		// view projection
		float[4][4] view_projection_;

		SDL_Window* window_;
		SDL_GLContext context_;
		int width_, height_;
		bool alive_;

		// keyboard state
		ubyte* keyboard_;

	}

	@property
	const nothrow @nogc {

		float[4][4] projection() { return view_projection_; }
		bool isAlive() { return alive_; }
		int width() { return width_; }
		int height() { return height_; }

	}
		
	void quit() { alive_ = false; }

	@disable this(this);
	@disable ref Window opAssign(ref Window window);

	~this() {

		if (window_) {
			debug printf("[GLAND] Destroying Window. \n");
			SDL_GL_DeleteContext(context_);
			SDL_DestroyWindow(window_);
			SDL_Quit();
		}

	} // ~this

	/**
	 * Loads necessary libraries for this module.
	 * TODO: error codes for when things go wrong.
	*/
	static void load() {

		shared static bool is_initialized = false;
		if (is_initialized) return;

		DerelictSDL2.load();
		SDL_Init(SDL_INIT_EVENTS | SDL_INIT_VIDEO);
		is_initialized = true;

	} // load

	static Error create(ref Window window, uint width, uint height) {

		// initialize
		Window.load();

		uint flags = 0;
		flags |= SDL_WINDOW_OPENGL;

		window.window_ = SDL_CreateWindow(
			"SDL2 Window",
			SDL_WINDOWPOS_UNDEFINED,
			SDL_WINDOWPOS_UNDEFINED,
			width, height,
			flags
		);	

		// is valid?
		if (!window.window_) { return Error.WindowCreationFailed; }

		// get window dimensions and set vars in struct
		SDL_GetWindowSize(window.window_, &window.width_, &window.height_);

		// try creating context, TODO is setting a "min" version
		auto result = window.createGLContext(3, 3);
		if (result != 0) { return Error.ContextCreationFailed; }

		// it's alive!
		window.alive_ = true;

		// set up keyboard
		window.keyboard_ = SDL_GetKeyboardState(null);

		// set up screen space projection matrix
		window.adjustProjection();

		// display modes
		window.printDisplayModes();

		return Error.Success;

	} // create

	void printDisplayModes() {

		auto result = SDL_GetNumVideoDisplays();
		assert(result > 1);

		foreach(d_i; 0 .. result) {

			printf("[DNA] Display: %s \n", SDL_GetDisplayName(d_i));

			float ddpi, hdpi, vdpi;
			SDL_GetDisplayDPI(d_i, &ddpi, &hdpi, &vdpi);
			printf("	- DPI: ddpi: %f, hdpi: %f, vdpi: %f \n", ddpi, hdpi, vdpi);

			auto modes_result = SDL_GetNumDisplayModes(d_i);
			assert(modes_result > 1);

			printf("	- modes: ");
			foreach (m_i; 0 .. modes_result) {
				SDL_DisplayMode mode;
				SDL_GetDisplayMode(d_i, m_i, &mode);
				printf("		- w: %d, h: %d, refresh rate: %d \n", mode.w, mode.h, mode.refresh_rate);
			}

		}

	} // printDisplayModes

	private int createGLContext(int gl_major, int gl_minor) {

		import std.functional : toDelegate;

		// OpenGL related attributes
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, gl_major);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, gl_minor);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
		SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
		SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

		// debuggering!
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, SDL_GL_CONTEXT_DEBUG_FLAG);

		// actually create context now
		context_ = SDL_GL_CreateContext(window_);

		if (!context_) {
			auto err = SDL_GetError();
			printf("[OpenGL] context creation error: %s \n", err);
			return -1;
		}

		// loader here
		auto glv = gladLoadGL((const (char)* load) => SDL_GL_GetProcAddress(load));

		if (!context_) {
			GLenum err = glGetError();
			printf("[OpenGL] Error: %d \n", err);
			return err;
		}

		const GLubyte* sGLVersion_ren = glGetString(GL_RENDERER);
		const GLubyte* sGLVersion_main = glGetString(GL_VERSION);
		const GLubyte* sGLVersion_shader = glGetString(GL_SHADING_LANGUAGE_VERSION);
		printf("[OpenGL] renderer is: %s \n", sGLVersion_ren);
		printf("[OpenGL] version is: %s \n", sGLVersion_main);
		printf("[OpenGL] GLSL version is: %s \n", sGLVersion_shader);
		printf("[OpenGL] Loading GL Extensions. \n");

		glEnable(GL_DEBUG_OUTPUT);
		glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS);
		glDebugMessageCallback(&openGLCallbackFunction, null);

		// enable all
		glDebugMessageControl(
			GL_DONT_CARE, GL_DONT_CARE, GL_DONT_CARE, 0, null, true
		);

		// disable notification messages
		glDebugMessageControl(
			GL_DONT_CARE, GL_DONT_CARE, GL_DEBUG_SEVERITY_NOTIFICATION, 0, null, false
		);

		return 0; // all is well

	}

	void adjustProjection() {

		import gland.util : transpose, orthographic;
		view_projection_ = transpose(orthographic(0.0f, width_, height_, 0.0f, 0.0f, 1.0f));

	} // adjustProjection

	version (Windows) {
		extern(Windows) nothrow @nogc
			static void openGLCallbackFunction(
					GLenum source, GLenum type,
					GLuint id, GLenum severity,
					GLsizei length, const (GLchar*) message,
					void* userParam)
		{

			import gland.gl : to;

			printf("Message: %s \nSource: %s \nType: %s \nID: %d \nSeverity: %s\n\n",
					message, to!(char*)(source), to!(char*)(type), id, to!(char*)(severity));

			if (severity == GL_DEBUG_SEVERITY_HIGH) {
				printf("Aborting...\n");
				exit(-1);
			}

		} //openGLCallbackFunction
	}

	version (linux) {
		extern(C) nothrow @nogc
			static void openGLCallbackFunction(
					GLenum source, GLenum type,
					GLuint id, GLenum severity,
					GLsizei length, const (GLchar*) message,
					void* userParam)
		{

			import gland.gl : to;

			printf("Message: %s \nSource: %s \nType: %s \nID: %d \nSeverity: %s\n\n",
					message, to!(char*)(source), to!(char*)(type), id, to!(char*)(severity));

			if (severity == GL_DEBUG_SEVERITY_HIGH) {
				printf("Aborting...\n");
				exit(-1);
			}

		} //openGLCallbackFunction		
	}

	void present() {

		SDL_GL_SwapWindow(window_);

	} // present

	bool isKeyDown(SDL_Scancode key) {

		return cast(bool)keyboard_[key];

	} // isKeyDown

	auto getMousePosition() {

		int x, y;
		SDL_GetMouseState(&x, &y);

		return tuple(x, y);

	} // getMousePosition

	void handleEvents() {

		SDL_Event ev;

		while (SDL_PollEvent(&ev)) {

			switch (ev.type) {

				case SDL_QUIT:
					alive_ = false;
					break;

				default:
					break;

			}

		}

	} // handleEvents

} // Window
