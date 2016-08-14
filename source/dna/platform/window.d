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

	auto displays() {

		static struct ModeRange {
		nothrow:
		@nogc:

			// SDL2 display index
			int display_;

			int current_mode_;
			int num_modes_;

			this(int display_index, int modes) {
				this.display_ = display_index;
				this.num_modes_ = modes;
				this.current_mode_ = 0;
			} // this

			@property bool empty() const {
				return current_mode_ == num_modes_;
			} // empty

			@property SDL_DisplayMode front() {

				SDL_DisplayMode mode;
				SDL_GetDisplayMode(display_, current_mode_, &mode);

				return mode;

			} // front

			void popFront() {

				if (current_mode_ < num_modes_) {
					current_mode_++;
				}

			} // popFront

		} // ModeRange

		static struct Display {
		nothrow:
		@nogc:
			
			// refers to SDL2 index
			int display_index_;

			const (char)* name;
			float ddpi, hdpi, vdpi;
			int num_display_modes_;

			auto modes() {
				return ModeRange(display_index_, num_display_modes_);
			} // modes

		} // Display

		static struct DisplayRange {
		nothrow:
		@nogc:

			int current_display_;
			int num_displays_;

			this(int displays) {
				this.num_displays_ = displays;
				this.current_display_ = 0;
			} // this

			@property bool empty() const {
				return current_display_ == num_displays_;
			} // empty

			@property Display front() {

				Display display;

				display.display_index_ = current_display_;
				display.name = SDL_GetDisplayName(current_display_);
				SDL_GetDisplayDPI(current_display_, &display.ddpi, &display.hdpi, &display.vdpi);
				display.num_display_modes_ = SDL_GetNumDisplayModes(current_display_);

				return display;

			} // front

			void popFront() {

				if (current_display_ < num_displays_) {
					current_display_++;
				}

			} // popFront

		} // DisplayRange

		auto num_displays = SDL_GetNumVideoDisplays();
		return DisplayRange(num_displays);

	} // displays

	@nogc
	void printDisplayModes() {

		auto displays = displays();
		printf("[DNA] Listing displays and their modes. \n");

		foreach (display; displays) {

			printf("Display: %s \n", display.name);
			printf(" DPI: ddpi: %f, hdpi: %f, vdpi: %f \n", display.ddpi, display.hdpi, display.vdpi);

			auto modes = display.modes();
			foreach (mode; modes) {
				printf("  - w: %d, h: %d, refresh rate: %d \n", mode.w, mode.h, mode.refresh_rate);
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

	nothrow @nogc
	void present() {

		SDL_GL_SwapWindow(window_);

	} // present

	nothrow @nogc
	bool isKeyDown(SDL_Scancode key) {

		return cast(bool)keyboard_[key];

	} // isKeyDown

	nothrow @nogc
	auto getMousePosition() {

		int x, y;
		SDL_GetMouseState(&x, &y);

		return tuple(x, y);

	} // getMousePosition

	nothrow @nogc
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
