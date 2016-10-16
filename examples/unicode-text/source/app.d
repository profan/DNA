import std.stdio;

import dna;

void main() {

	Game game;
	auto result = Game.create(game);
	final switch (result) with (Engine.Error) {
		case WindowInitFailed, FontInitFailed, SoundInitFailed:
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

		import dna.unitext : FontAtlas = FAtlas;
		FAtlas atlas;

	}

	static auto create(ref Game game) {

		auto atlas_err = FAtlas.create(atlas, game.engine.device, "fonts/OpenSans-Regular.ttf");

		return Engine.create(game, game.engine);

	} // create
	
	void update() {

		import dna.platform.input;

		if (Input.isKeyDown(Key.Escape)) {
			engine.quit();
		} // update

	} // update

	void draw(double dt) {

		auto mouse_pos = Input.mousePos();

		engine.renderFmtString!("X: %d, Y: %d")(mouse_pos.x, mouse_pos.y, mouse_pos.x, mouse_pos.y);

	} // draw

	void run() {

		engine.run();

	} // run

} // Game
