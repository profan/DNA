module dna.platform.input;

import core.stdc.stdio : printf;
import std.typecons : Tuple;
import derelict.sdl2.sdl;

enum Key {

	Unknown = SDL_SCANCODE_UNKNOWN,

	A = SDL_SCANCODE_A,
	B = SDL_SCANCODE_B,
	C = SDL_SCANCODE_C,
	D = SDL_SCANCODE_D,
	E = SDL_SCANCODE_E,
	F = SDL_SCANCODE_F,
	G = SDL_SCANCODE_G,
	H = SDL_SCANCODE_H,
	I = SDL_SCANCODE_I,
	J = SDL_SCANCODE_J,
	K = SDL_SCANCODE_K,
	L = SDL_SCANCODE_L,
	M = SDL_SCANCODE_M,
	N = SDL_SCANCODE_N,
	O = SDL_SCANCODE_O,
	P = SDL_SCANCODE_P,
	Q = SDL_SCANCODE_Q,
	R = SDL_SCANCODE_R,
	S = SDL_SCANCODE_S,
	T = SDL_SCANCODE_T,
	U = SDL_SCANCODE_U,
	V = SDL_SCANCODE_V,
	W = SDL_SCANCODE_W,
	X = SDL_SCANCODE_X,
	Y = SDL_SCANCODE_Y,
	Z = SDL_SCANCODE_Z,
	One = SDL_SCANCODE_1,
	Two = SDL_SCANCODE_2,
	Three = SDL_SCANCODE_3,
	Four = SDL_SCANCODE_4,
	Five = SDL_SCANCODE_5,
	Six = SDL_SCANCODE_6,
	Seven = SDL_SCANCODE_7,
	Eight = SDL_SCANCODE_8,
	Nine = SDL_SCANCODE_9,
	Zero = SDL_SCANCODE_0,
	Return = SDL_SCANCODE_RETURN,
	Escape = SDL_SCANCODE_ESCAPE,
	Backspace = SDL_SCANCODE_BACKSPACE,
	Tab = SDL_SCANCODE_TAB,
	Space = SDL_SCANCODE_SPACE,
	Minus = SDL_SCANCODE_MINUS,
	Equals = SDL_SCANCODE_EQUALS,
	Leftbracket = SDL_SCANCODE_LEFTBRACKET,
	Rightbracket = SDL_SCANCODE_RIGHTBRACKET,
	Backslash = SDL_SCANCODE_BACKSLASH,
	Nonushash = SDL_SCANCODE_NONUSHASH,
	Semicolon = SDL_SCANCODE_SEMICOLON,
	Apostrophe = SDL_SCANCODE_APOSTROPHE,
	Grave = SDL_SCANCODE_GRAVE,
	Comma = SDL_SCANCODE_COMMA,
	Period = SDL_SCANCODE_PERIOD,
	Slash = SDL_SCANCODE_SLASH,
	Capslock = SDL_SCANCODE_CAPSLOCK,
	F1 = SDL_SCANCODE_F1,
	F2 = SDL_SCANCODE_F2,
	F3 = SDL_SCANCODE_F3,
	F4 = SDL_SCANCODE_F4,
	F5 = SDL_SCANCODE_F5,
	F6 = SDL_SCANCODE_F6,
	F7 = SDL_SCANCODE_F7,
	F8 = SDL_SCANCODE_F8,
	F9 = SDL_SCANCODE_F9,
	F10 = SDL_SCANCODE_F10,
	F11 = SDL_SCANCODE_F11,
	F12 = SDL_SCANCODE_F12,
	Printscreen = SDL_SCANCODE_PRINTSCREEN,
	Scrolllock = SDL_SCANCODE_SCROLLLOCK,
	Pause = SDL_SCANCODE_PAUSE,
	Insert = SDL_SCANCODE_INSERT,
	Home = SDL_SCANCODE_HOME,
	Pageup = SDL_SCANCODE_PAGEUP,
	Delete = SDL_SCANCODE_DELETE,
	End = SDL_SCANCODE_END,
	Pagedown = SDL_SCANCODE_PAGEDOWN,
	Right = SDL_SCANCODE_RIGHT,
	Left = SDL_SCANCODE_LEFT,
	Down = SDL_SCANCODE_DOWN,
	Up = SDL_SCANCODE_UP,
	NumlockClear = SDL_SCANCODE_NUMLOCKCLEAR,
	Kp_Divide = SDL_SCANCODE_KP_DIVIDE,
	Kp_Multiply = SDL_SCANCODE_KP_MULTIPLY,
	Kp_Minus = SDL_SCANCODE_KP_MINUS,
	Kp_Plus = SDL_SCANCODE_KP_PLUS,
	Kp_Enter = SDL_SCANCODE_KP_ENTER,
	Kp_1 = SDL_SCANCODE_KP_1,
	Kp_2 = SDL_SCANCODE_KP_2,
	Kp_3 = SDL_SCANCODE_KP_3,
	Kp_4 = SDL_SCANCODE_KP_4,
	Kp_5 = SDL_SCANCODE_KP_5,
	Kp_6 = SDL_SCANCODE_KP_6,
	Kp_7 = SDL_SCANCODE_KP_7,
	Kp_8 = SDL_SCANCODE_KP_8,
	Kp_9 = SDL_SCANCODE_KP_9,
	Kp_0 = SDL_SCANCODE_KP_0,
	Kp_Period = SDL_SCANCODE_KP_PERIOD,
	NonusBackslash = SDL_SCANCODE_NONUSBACKSLASH,
	Application = SDL_SCANCODE_APPLICATION,
	Power = SDL_SCANCODE_POWER,
	Kp_Equals = SDL_SCANCODE_KP_EQUALS,
	F13 = SDL_SCANCODE_F13,
	F14 = SDL_SCANCODE_F14,
	F15 = SDL_SCANCODE_F15,
	F16 = SDL_SCANCODE_F16,
	F17 = SDL_SCANCODE_F17,
	F18 = SDL_SCANCODE_F18,
	F19 = SDL_SCANCODE_F19,
	F20 = SDL_SCANCODE_F20,
	F21 = SDL_SCANCODE_F21,
	F22 = SDL_SCANCODE_F22,
	F23 = SDL_SCANCODE_F23,
	F24 = SDL_SCANCODE_F24,
	Execute = SDL_SCANCODE_EXECUTE,
	Help = SDL_SCANCODE_HELP,
	Menu = SDL_SCANCODE_MENU,
	Select = SDL_SCANCODE_SELECT,
	Stop = SDL_SCANCODE_STOP,
	Again = SDL_SCANCODE_AGAIN,
	Undo = SDL_SCANCODE_UNDO,
	Cut = SDL_SCANCODE_CUT,
	Copy = SDL_SCANCODE_COPY,
	Paste = SDL_SCANCODE_PASTE,
	Find = SDL_SCANCODE_FIND,
	Mute = SDL_SCANCODE_MUTE,
	VolumeUp = SDL_SCANCODE_VOLUMEUP,
	VolumeDown = SDL_SCANCODE_VOLUMEDOWN,

	// TODO: patch Derelict SDL2 library
	// LockingCapslock = SDL_SCANCODE_LOCKINGCAPSLOCK,
	// LockingNumlock = SDL_SCANCODE_LOCKINGNUMLOCK,
	// LockingScrolllock = SDL_SCANCODE_LOCKINGSCROLLLOCK,

	Kp_Comma = SDL_SCANCODE_KP_COMMA,
	Kp_EqualsAs400 = SDL_SCANCODE_KP_EQUALSAS400,
	International1 = SDL_SCANCODE_INTERNATIONAL1,
	International2 = SDL_SCANCODE_INTERNATIONAL2,
	International3 = SDL_SCANCODE_INTERNATIONAL3,
	International4 = SDL_SCANCODE_INTERNATIONAL4,
	International5 = SDL_SCANCODE_INTERNATIONAL5,
	International6 = SDL_SCANCODE_INTERNATIONAL6,
	International7 = SDL_SCANCODE_INTERNATIONAL7,
	International8 = SDL_SCANCODE_INTERNATIONAL8,
	International9 = SDL_SCANCODE_INTERNATIONAL9,
	Lang1 = SDL_SCANCODE_LANG1,
	Lang2 = SDL_SCANCODE_LANG2,
	Lang3 = SDL_SCANCODE_LANG3,
	Lang4 = SDL_SCANCODE_LANG4,
	Lang5 = SDL_SCANCODE_LANG5,
	Lang6 = SDL_SCANCODE_LANG6,
	Lang7 = SDL_SCANCODE_LANG7,
	Lang8 = SDL_SCANCODE_LANG8,
	Lang9 = SDL_SCANCODE_LANG9,
	Alterase = SDL_SCANCODE_ALTERASE,
	Sysreq = SDL_SCANCODE_SYSREQ,
	Cancel = SDL_SCANCODE_CANCEL,
	Clear = SDL_SCANCODE_CLEAR,
	Prior = SDL_SCANCODE_PRIOR,
	Return2 = SDL_SCANCODE_RETURN2,
	Separator = SDL_SCANCODE_SEPARATOR,
	Out = SDL_SCANCODE_OUT,
	Oper = SDL_SCANCODE_OPER,
	ClearAgain = SDL_SCANCODE_CLEARAGAIN,
	Crsel = SDL_SCANCODE_CRSEL,
	Exsel = SDL_SCANCODE_EXSEL,
	Kp_00 = SDL_SCANCODE_KP_00,
	Kp_000 = SDL_SCANCODE_KP_000,
	ThousandsSeparator = SDL_SCANCODE_THOUSANDSSEPARATOR,
	DecimalSeparator = SDL_SCANCODE_DECIMALSEPARATOR,
	CurrencyUnit = SDL_SCANCODE_CURRENCYUNIT,
	CurrencySubUnit = SDL_SCANCODE_CURRENCYSUBUNIT,
	Kp_LeftParen = SDL_SCANCODE_KP_LEFTPAREN,
	Kp_RightParen = SDL_SCANCODE_KP_RIGHTPAREN,
	Kp_LeftBrace = SDL_SCANCODE_KP_LEFTBRACE,
	Kp_RighBbrace = SDL_SCANCODE_KP_RIGHTBRACE,
	Kp_Tab = SDL_SCANCODE_KP_TAB,
	Kp_Backspace = SDL_SCANCODE_KP_BACKSPACE,
	Kp_A = SDL_SCANCODE_KP_A,
	Kp_B = SDL_SCANCODE_KP_B,
	Kp_C = SDL_SCANCODE_KP_C,
	Kp_D = SDL_SCANCODE_KP_D,
	Kp_E = SDL_SCANCODE_KP_E,
	Kp_F = SDL_SCANCODE_KP_F,
	Kp_Xor = SDL_SCANCODE_KP_XOR,
	Kp_Power = SDL_SCANCODE_KP_POWER,
	Kp_Percent = SDL_SCANCODE_KP_PERCENT,
	Kp_Less = SDL_SCANCODE_KP_LESS,
	Kp_Greater = SDL_SCANCODE_KP_GREATER,
	Kp_Ampersand = SDL_SCANCODE_KP_AMPERSAND,
	Kp_DblAmpersand = SDL_SCANCODE_KP_DBLAMPERSAND,
	Kp_Verticalbar = SDL_SCANCODE_KP_VERTICALBAR,
	Kp_DblVerticalbar = SDL_SCANCODE_KP_DBLVERTICALBAR,
	Kp_Colon = SDL_SCANCODE_KP_COLON,
	Kp_Hash = SDL_SCANCODE_KP_HASH,
	Kp_Space = SDL_SCANCODE_KP_SPACE,
	Kp_At = SDL_SCANCODE_KP_AT,
	Kp_Exclam = SDL_SCANCODE_KP_EXCLAM,
	Kp_MemStore = SDL_SCANCODE_KP_MEMSTORE,
	Kp_MemRecall = SDL_SCANCODE_KP_MEMRECALL,
	Kp_MemClear = SDL_SCANCODE_KP_MEMCLEAR,
	Kp_MemAdd = SDL_SCANCODE_KP_MEMADD,
	Kp_MemSubtract = SDL_SCANCODE_KP_MEMSUBTRACT,
	Kp_MemMultiply = SDL_SCANCODE_KP_MEMMULTIPLY,
	Kp_MemDivide = SDL_SCANCODE_KP_MEMDIVIDE,
	Kp_PlusMinus = SDL_SCANCODE_KP_PLUSMINUS,
	Kp_Clear = SDL_SCANCODE_KP_CLEAR,
	Kp_ClearEntry = SDL_SCANCODE_KP_CLEARENTRY,
	Kp_Binary = SDL_SCANCODE_KP_BINARY,
	Kp_Octal = SDL_SCANCODE_KP_OCTAL,
	Kp_Decimal = SDL_SCANCODE_KP_DECIMAL,
	Kp_Hexadecimal = SDL_SCANCODE_KP_HEXADECIMAL,
	LCtrl = SDL_SCANCODE_LCTRL,
	LShift = SDL_SCANCODE_LSHIFT,
	LAlt = SDL_SCANCODE_LALT,
	Lgui = SDL_SCANCODE_LGUI,
	RCtrl = SDL_SCANCODE_RCTRL,
	RShift = SDL_SCANCODE_RSHIFT,
	Ralt = SDL_SCANCODE_RALT,
	Rgui = SDL_SCANCODE_RGUI,
	Mode = SDL_SCANCODE_MODE,
	AudioNext = SDL_SCANCODE_AUDIONEXT,
	AudioPrev = SDL_SCANCODE_AUDIOPREV,
	AudioStop = SDL_SCANCODE_AUDIOSTOP,
	AudioPlay = SDL_SCANCODE_AUDIOPLAY,
	AudioMute = SDL_SCANCODE_AUDIOMUTE,
	MediaSelect = SDL_SCANCODE_MEDIASELECT,
	Www = SDL_SCANCODE_WWW,
	Mail = SDL_SCANCODE_MAIL,
	Calculator = SDL_SCANCODE_CALCULATOR,
	Computer = SDL_SCANCODE_COMPUTER,
	Ac_Search = SDL_SCANCODE_AC_SEARCH,
	Ac_Home = SDL_SCANCODE_AC_HOME,
	Ac_Back = SDL_SCANCODE_AC_BACK,
	Ac_Forward = SDL_SCANCODE_AC_FORWARD,
	Ac_Stop = SDL_SCANCODE_AC_STOP,
	Ac_Refresh = SDL_SCANCODE_AC_REFRESH,
	Ac_Bookmarks = SDL_SCANCODE_AC_BOOKMARKS,
	BrightnessDown = SDL_SCANCODE_BRIGHTNESSDOWN,
	BrightnessUp = SDL_SCANCODE_BRIGHTNESSUP,
	DisplaySwitch = SDL_SCANCODE_DISPLAYSWITCH,
	KbdIllumToggle = SDL_SCANCODE_KBDILLUMTOGGLE,
	KbdIllumDown = SDL_SCANCODE_KBDILLUMDOWN,
	KbdIllumUp = SDL_SCANCODE_KBDILLUMUP,
	Eject = SDL_SCANCODE_EJECT,
	Sleep = SDL_SCANCODE_SLEEP

} // Key

alias MousePos = Tuple!(int, "x", int, "y");

struct Input {

	static {

		ubyte* keys_;
		int mouse_btns_;
		MousePos mouse_pos_;

	}

	static void initialize() {

		keys_ = SDL_GetKeyboardState(null);
		assert(keys_ != null, "keys_ was null, SDL_GetKeyboardState failed!");

	} // initialize

	static ref MousePos mousePos() {

		mouse_btns_ = SDL_GetMouseState(&mouse_pos_.x, &mouse_pos_.y);
		return mouse_pos_;

	} // mousePos

	nothrow @nogc
	static auto mouseState(out MousePos pos) {

		return SDL_GetMouseState(&pos.x, &pos.y);

	} // mouseState


	static bool isKeyDown(Key key) {

		return cast(bool)keys_[key];

	} // isKeyDown

	void setRelativeMouseMode(bool state) {

		auto status = SDL_SetRelativeMouseMode(state);
		if (status == -1) { printf("SDL_SetRelativeMouseMode not supported on this platform!"); }

	} // setRelativeMouseMode

} // Input
