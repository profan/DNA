module dna.platform.event;

import derelict.sdl2.sdl;

alias EventReceiver = void delegate(ref SDL_Event);

struct EventManager(Listeners...) {

	EventReceiver[Listeners.length] receivers;

	void attach(ref Listeners args) {

		foreach (i, ref arg; args) {
			receivers[i] = &arg.handleEvent;
		}

	} // attach

	void handleEvents() {

		SDL_Event event;

		while (SDL_PollEvent(&event)) {
			foreach (receiver; receivers) {
				receiver(event);
			}
		}

	} // handleEvents

} // EventManager
