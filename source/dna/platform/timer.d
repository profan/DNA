module dna.platform.timer;

import derelict.sdl2.sdl;

/**
 * Structure meant to represent a timespan in native clock ticks, can be used to represent time in seconds by
 *  using the ticksPerSecond method.
*/
struct StopWatch {

	import core.time : MonoTimeImpl, ClockType;
	alias Clock = MonoTimeImpl!(ClockType.precise);
	alias TicksPerSecond = Clock.ticksPerSecond;

	private {

		bool started_;
		long initial_ticks_;
		long passed_ticks_;

	}

	/**
	 * Returns the current tick value of the system clock, usually time passed since startup.
	*/
	static @property auto currTicks() {

		return Clock.currTime.ticks;

	} // currTicks

	/**
	 * Starts the StopWatch, setting the initial tick to the current tick the system clock is at.
	*/
	void start() {

		initial_ticks_ = currTicks;
		started_ = true;

	} // start

	/**
	 * Stops the StopWatch, setting the passed ticks to time between the initial tick and
	 *  the current point in time.
	*/
	void stop() {

		passed_ticks_ += currTicks - initial_ticks_;
		started_ = false;

	} // stop

	/**
	 * Resets the StopWatch, setting the initial tick (starting point) to current time passed by the system clock
	 *  if already started, otherwise to zero. TODO: WHY?
	*/
	void reset() {

		if (started_) {
			initial_ticks_ = currTicks;
		} else {
			initial_ticks_ = 0;
		}

	} // reset

	/**
	 * Returns the amount of clock ticks per second for this StopWatch type.
	*/
	static long ticksPerSecond() {

		return TicksPerSecond;

	} // ticksPerSecond

	/**
	 * Returns the amount of time passed since starting the StopWatch, or the time between start and stop
	 *  if it is currently paused.
	*/
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

/**
 * Uses SDL2's sleep function to wait a certain amount of milliseconds
 *  granularity is rarely better than a few milliseconds (1-2 at best),
 *  use when this is acceptable.
*/
void delayMs(uint ms) {

	SDL_Delay(ms);

} // delayMs

/**
 * Uses a loop to wait until a certain tick value is reached, used when
 *  the system sleep function's granularity is not high enough, or when one might
 *  otherwise not want to invoke it.
*/
void busyWaitTicks(ref StopWatch sw, ulong total_ticks) {

	long ticks_left = total_ticks - sw.peek();
	while (ticks_left > 0) {
		ticks_left = total_ticks - sw.peek();
	}

} // busyWaitTicks
