module dna.platform.timer;

import derelict.sdl2.sdl;

struct StopWatch {

	import core.time : MonoTimeImpl, ClockType;
	alias Clock = MonoTimeImpl!(ClockType.precise);
	alias TicksPerSecond = Clock.ticksPerSecond;

	private {

		bool started_;
		long initial_ticks_;
		long passed_ticks_;

	}

	static @property auto currTicks() {

		return Clock.currTime.ticks;

	} // currTicks

	void start() {

		initial_ticks_ = currTicks;
		started_ = true;

	} // start

	void stop() {

		passed_ticks_ += currTicks - initial_ticks_;
		started_ = false;

	} // stop

	void reset() {

		if (started_) {
			initial_ticks_ = currTicks;
		} else {
			initial_ticks_ = 0;
		}

	} // reset

	static long ticksPerSecond() {

		return TicksPerSecond;

	} // ticksPerSecond

	long peek() {

		if (started_) {
			return currTicks - initial_ticks_ + passed_ticks_;
		}

		return passed_ticks_;

	} // peek

} // StopWatch

/**
 * Sleep/Wait function which understands the granularity of the OS sleep function, so it
 * uses a busy-wait function when the time to wait is too short for the thread sleep
 * functionality to be accurate enough, often 1-2ms is the limit, after which point the 
 * busy wait will kick in and be used instead, without the user needing to worry.
*/
void waitUntilTick(ref StopWatch sw, ulong ticks_per_frame) {

	long clock_ticks_per_second = sw.ticksPerSecond();

	// calculate milliseconds current frame has taken
	int frame_ms = cast(int)((cast(double)sw.peek() / cast(double)clock_ticks_per_second) * 1000.0);

	// calculate milliseconds for a normal frame
	int wanted_time = cast(int)((cast(double)ticks_per_frame / cast(double)clock_ticks_per_second) * 1000.0);

	// calculate time to wait in milliseconds
	int wait_time = wanted_time - frame_ms;

	if (wait_time > 2) {
		// account for granularity when waiting, min 1ms wait
		delayMs(cast(uint)wait_time - 2U);
	}

	// do the busywait!
	busyWaitTicks(sw, ticks_per_frame);

} // waitUntil

void delayMs(uint ms) {

	SDL_Delay(ms);

} // delayMs

void busyWaitTicks(ref StopWatch sw, ulong total_ticks) {

	long ticks_left = total_ticks - sw.peek();
	while (ticks_left > 0) {
		ticks_left = total_ticks - sw.peek();
	}

} // busyWaitTicks
