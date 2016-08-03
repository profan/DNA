module dna.runtime;

import dna.platform.window;
import dna.platform.input;
import dna.text;

import gland.gl;

alias FreeUpdateFunc = void function();
alias FreeDrawFunc = void function(double);
alias FreeRunFunc = void function();

alias UpdateFunc = void delegate();
alias DrawFunc = void delegate(double);
alias RunFunc = void delegate();

struct Engine {

	enum Error {

		WindowInitFailed = "Window failed to initialize!",
		FontInitFailed = "FontAtlas failed to initialize!",
		Success = "Successfully initialized engine!"

	} // Error

	private {

		// modules go here
		Window window_;

		// default graphics data
		FontAtlas text_atlas_;

		// how fast are we going?
		double update_time_;
		double frame_time_;
		double draw_time_;

		double time_since_last_update_;

		// runtime pacing goes here
		int update_rate_ = 60;
		int draw_rate_ = 60;

		// function pointers to delegates to run on update and draw
		UpdateFunc update_fn_;
		DrawFunc draw_fn_;
		RunFunc run_fn_;

	}

	@property {

		int update_rate () { return update_rate_; }
		int update_rate (int new_rate) {
			if (new_rate > 0) { update_rate_ = new_rate; }
			return update_rate_;
		}
		int draw_rate() { return draw_rate_; }
		int draw_rate(int new_rate) {
			if (new_rate > 0) { draw_rate_ = new_rate; }
			return draw_rate_;
		}

	}

	@disable this(this);
	@disable ref Engine opAssign(ref typeof(this) other);

	/**
	 * Quits the engine.
	*/
	void quit() {

		window_.quit();

	} // quit

	/**
	 * Destroys resources and unloads libraries and such.
	*/
	~this () {

		FontAtlas.unload();

	} // ~this

	/**
	 * Convenience overload that allows passing two free functions and automatically converts them to
	 *  delegates internally.
	*/
	static Error create(ref Engine engine, FreeUpdateFunc update_fn, FreeDrawFunc draw_fn) {

		import std.functional : toDelegate;

		return create(engine, toDelegate(update_fn), toDelegate(draw_fn));

	} // create

	/**
	 * Initializes the engine and its modules, returning an error code if something goes wrong.
	*/
	static Error create(ref Engine engine, UpdateFunc update_fn, DrawFunc draw_fn) {

		import std.stdio : writefln;

		auto result = Window.create(engine.window_, 640, 480);
		final switch (result) with (Window.Error) {
			/* return from main if we failed, print stuff. */
			case WindowCreationFailed, ContextCreationFailed:
				writefln("[DNA] Error: %s", cast(string)result);
				return Error.WindowInitFailed;
			/* we succeeded, just continue. */
			case Success:
				writefln("[DNA] %s", cast(string)result);
				break;
		}

		// init input modules (depends on previous currently)
		Input.initialize();

		auto atlas_result = FontAtlas.create(engine.text_atlas_, "fonts/OpenSans-Regular.ttf", 12);
		final switch (atlas_result) with (FontAtlas.Error) {
			case CouldNotOpenFont:
				writefln("[DNA] Could not open font: %s, exiting!", "fonts/OpenSans-Regular.ttf");
				return Error.FontInitFailed; // error!
			case Success:
				writefln("[DNA] %s", cast(string)atlas_result);
				break;
		}

		engine.update_fn_ = update_fn;
		engine.draw_fn_ = draw_fn;

		return Error.Success;

	} // create

	void draw() {

		Renderer.clearColour(0x428bca);

		// user draw
		draw_fn_(1.0);

		window_.present();

	} // draw

	void renderFmtString(string fmt, Args...)(float x, float y, Args args) {

		import gland.util : orthographic, transpose;
		import dna.util : renderFmtString;

		text_atlas_.renderFmtString!fmt([window_.projection], x, y, args);

	} // renderString

	void renderString(in char[] str, float offset_x = 0, float offset_y = 0) {

		import gland.util : orthographic, transpose;

		text_atlas_.renderText([window_.projection], str, offset_x, offset_y, 1, 1, 0xffffff);

	} // renderString

	void run() {

		import dna.platform.timer : StopWatch;

		StopWatch main_timer;
		StopWatch update_timer;
		StopWatch draw_timer;
		StopWatch frame_timer;

		long tps = StopWatch.ticksPerSecond();

		long last_update;
		long last_draw;

		main_timer.start();
		update_timer.start();
		draw_timer.start();
		frame_timer.start();

		while (window_.isAlive) {

			// update iters in case update rate or draw rate changes
			ulong update_iter = tps / update_rate_;
			ulong draw_iter = tps / draw_rate_;

			// time to update?
			if (main_timer.peek() - last_update > update_iter) {

				update_timer.start();

				// handle window events
				window_.handleEvents();

				// update ze things
				update_fn_();

				update_time_ = cast(double)update_timer.peek() / cast(double)tps;
				last_update = main_timer.peek();
				update_timer.reset();

			}

			auto ticks_since_last_update = main_timer.peek() - last_update;
			time_since_last_update_ = (cast(double)ticks_since_last_update / cast(double)tps)
				/ (cast(double)update_iter / cast(double)tps);

			draw_timer.start();
			draw();
			draw_time_ = cast(double)draw_timer.peek() / cast(double)tps;
			last_draw = draw_timer.peek();
			draw_timer.reset();

			import dna.platform.timer : waitUntilTick;
			frame_timer.waitUntilTick(draw_iter);

			frame_time_ = cast(double)frame_timer.peek() / cast(double)tps;
			frame_timer.reset();

		}

	} // run

} // Engine
