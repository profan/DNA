import std.stdio;

import dna;

void main() {

	// init
	Game.load();

	Game game;
	auto result = Game.create(game);
	final switch (result) with (Engine.Error) {
		case WindowInitFailed, FontInitFailed:
			writefln("[WINDOW] Error: %s", cast(string)result);
			break;
		case Success: break;
	}

	// wap wap wap
	game.run();

}

struct Game {

	private {
		Engine engine;
	}

	static void load() {

		// load libs
		Engine.load();

	} // load

	static auto create(ref Game game) {

		return Engine.create(game.engine, &game.update, &game.draw);

	} // create
	
	void update() {

		import dna.platform.input;

		if (Input.isKeyDown(Key.Escape)) {
			engine.quit();
		} // update

	} // update

	void draw(double dt) {

		engine.renderFmtString!("Update Rate: %d, Draw Rate: %d")(640/2, 480/2, engine.update_rate, engine.draw_rate);

	} // draw

	void run() {

		engine.run();

	} // run

} // Game
