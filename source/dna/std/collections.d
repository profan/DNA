module dna.std.collections;

/* a set of datastructures which utilize the allocators built for the engine. */
import std.experimental.allocator : allocatorObject, IAllocator, theAllocator, make, makeArray, expandArray, shrinkArray, dispose;
import std.experimental.allocator.building_blocks.free_list : FreeList;
import std.experimental.allocator.mallocator : Mallocator;

/* testulon */
import tested : name;

struct Array(T) {

	import std.algorithm : move;

	private {

		IAllocator allocator_;

		T[] array_;
		size_t capacity_;
		size_t length_;

	}

	//@disable this(); //TODO: take a look at why this was done
	@disable this(this);

	this(IAllocator allocator, size_t initial_size = 1) @trusted {

		assert(allocator, "array allocator was null?");

		this.allocator_ = allocator;
		this.array_ = allocator_.makeArray!T(initial_size);
		this.capacity_ = initial_size;
		this.length_ = 0;

	} // this

	~this() @trusted {
		if (allocator_ !is null) {
			this.free();
		}
	} // ~this

	void free() {

		this.allocator_.dispose(array_);

	} // free

	void clear() @safe nothrow @nogc { // note, does not run destructors!
		this.length_ = 0;
	} // clear

	@property size_t capacity() @safe const nothrow @nogc {
		return capacity_;
	} // capacity

	@property size_t length() @safe const nothrow @nogc {
		return length_;
	} // length

	@property size_t length(size_t new_length) @safe nothrow @nogc { //no-op if length is too large
		if (new_length <= capacity_) {
			length_ = new_length;
		}
		return length_;
	} // length

	@property T[] data() nothrow @nogc {
		return array_;
	} // data

	@property const(T*) ptr() const nothrow {
		return array_.ptr;
	} // ptr

	@property T* ptr() nothrow {
		return array_.ptr;
	} // ptr

	int opApply(scope int delegate(ref size_t i, ref T) dg) {

		int result = 0;

		foreach (i, ref e; this[]) {
			result = dg(i, e);
			if (result) break;
		}

		return result;

	} // opApply

	int opApply(scope int delegate(ref T) dg) {

		int result = 0;

		foreach (ref e; this[]) {
			result = dg(e);
			if (result) break;
		}

		return result;

	} // opApply

	size_t opDollar(int dim)() const nothrow {
		static assert(dim == 0); //TODO remember what this does..
		return length_;
	} // opDollar

	const(T[]) opSlice() @safe const nothrow {
		return array_[0..length_];
	} // opSlice

	T[] opSlice() @safe nothrow {
		return array_[0..length_];
	} // opSlice

	T[] opSlice(size_t h, size_t t) nothrow {
		return array_[h..t];
	} // opSlice

	void opOpAssign(string op: "~")(T item) @trusted {
		this.add(move(item));
	} // opOpAssign

	void opOpAssign(string op: "~")(ref T item) @safe {
		this.add(item);
	} // opOpAssign

	void opOpAssign(string op: "~")(in T[] items) @safe {
		foreach (ref item; items) {
			this.add(item);
		}
	} // opOpAssign

	void opIndexAssign(T value, size_t index) @trusted {
		array_[index] = move(value);
	} // opIndexAssign

	static if (isCopyable!T) {
		void opIndexAssign(ref T value, size_t index) nothrow {
			array_[index] = value;
		} // opIndexAssign
	}

	ref T opIndex(size_t index) @nogc nothrow {
		return array_[index];
	} // opIndex

	void reserve(size_t requested_size) @trusted {

		if (capacity_ < requested_size) {
			this.expand(requested_size - capacity_);
		}

	} // reserve

	void expand(size_t extra_size) @trusted {

		bool success = allocator_.expandArray(array_, extra_size);
		capacity_ += extra_size;

		assert(success, "failed to expand array!");

	} // expand

	/**
	 * Rellocates the array to match the currently used length, rather than the current capacity (if they differ).
	*/
	void shrink() @trusted {

		auto shrinkage = capacity_ - length_;
		bool success = allocator_.shrinkArray(array_, shrinkage);
		capacity_ = length_;

		assert(success, "failed to shrink array!");

	} // shrink

	void add(T item) @trusted {

		if (length_ == capacity_) {
			this.expand(length_);
		}

		array_[length_++] = move(item);

	} // add

	static if (isCopyable!T) {
		void add(ref T item) @safe {

			if (length_ == capacity_) {
				this.expand(length_);
			}

			array_[length_++] = item;

		} // add
	}

	ref T get(size_t index) {
		return array_[index];
	} // get

	void remove(size_t index) {

		import std.string : format;
		import dna.platform.memory : memmove;

		assert(index < length_,
			   format("removal index was greater or equal to length of array, cap/len was: %d:%d", capacity_, length_));

		// [0, 1, 2, 3, 4, 5] -- remove 3, need to shift 4 and 5 one position down
		//FIXME maybe.. not do this, because it is potentially an *awful* idea.
		memmove(array_[index+1..length_], array_[index..length_-1]);
		length_--;

	} // remove

	bool remove(ref T thing) @trusted {

		foreach(ref i, ref e; this) {
			if (e == thing) {
				this.remove(i);
				return true;
			}
		}

		return false;

	} // remove

} // Array

/* set up allocator for tests */
version(unittest) {

	shared static this() {
		theAllocator = allocatorObject(Mallocator.instance);
	}

}

@name("Array 1")
unittest {

	auto free_list = FreeList!(Mallocator, 0, 128)();
	auto array = Array!long(allocatorObject(free_list), 64);

	array.add(25);
	assert(array.get(0) == 25, "didnt' equal 25, wtf?");
	array.add(42);
	array.remove(0);
	assert(array.length == 1, "didn't equal 1, wut?");
	assert(array.get(0) == 42, "didn't equal 42, wat?");

}

@name("Array 2: add/find")
unittest {

	auto array = Array!long(theAllocator, 4);

	auto to_find = [1, 2, 3, 4];

	foreach (e; to_find) {
		array.add(e);
	}

	foreach (i, e; array) {
		assert(to_find[i] == e);
	}

}

@name("Array 3: reserve")
unittest {

	auto array = Array!int(theAllocator, 0);
	array.reserve(32);

	assert(array.capacity == 32);

}

/**
 * Array type to represent an n-dimensional array with uniform dimensions.
*/
struct FixedArrayN(T, int N) {

	private {

		IAllocator allocator_;

		/* the backing array */
		Array!T array_;

	}

	this(size_t size) {

	} // this

} // FixedArrayN

@name("FixedArrayN 1 (unimplemented)")
unittest {

	assert(0);

}

/**
 * Array which loads the contents for a given identifier through a user-supplied delegate, useful
 * for lazy loading of resources or similar.
*/
struct LazyArray(T) {

} // LazyArray

@name("LazyArray 1 (unimplemented)")
unittest {

	assert(0);

}

/**
 * Simple non-resizeable heap allocated array, useful when internal moves are not desired.
*/
struct FixedArray(T) {

	private {

		Array!T array_;

	}

	@disable this(this);

	this(IAllocator allocator, size_t size) {

		this.array_ = typeof(array_)(allocator, size);

	} // this

	@property size_t length() @safe @nogc const {
		return array_.length;
	} // length

	bool add(ref T item) @safe {

		if (array_.length + 1 == array_.capacity) {
			return false; //cant add more to fixed size array, is full
		}

		array_.add(item);
		return true;

	} // add

	void remove(size_t index) {
		array_.remove(index);
	} // remove

	ref T opIndex(size_t index) nothrow @nogc {
		return array_[index];
	} // opIndex

} // FixedArray

@name("FixedArray 1 (unimplemented)")
unittest {

}

/**
 * Array type which never moves its contents in memory, is composed of $(D FixedArray)'s.
 * Useful for when stable pointers are desired without the need to notify the allocator of memory
 * moves.
*/
struct SegmentedArray(T) {

	private {

		IAllocator allocator_;

		immutable size_t segment_size_;
		Array!(FixedArray!T) arrays_;

	}

	@disable this(this);

	this(IAllocator allocator, size_t segment_size) {

		this.allocator_ = allocator;
		this.segment_size_ = segment_size;
		this.arrays_ = typeof(arrays_)(allocator_, 1);
		this.arrays_ ~= typeof(arrays_[0])(allocator_, segment_size_);

	} // this

	void add(T item) {

		auto num_segments = arrays_.length;

		if (arrays_[$-1].length == segment_size_) {
			arrays_ ~= typeof(arrays_[0])(allocator_, segment_size_); 
		}

		arrays_[$-1].add(item);

	} // add

	void remove(size_t index) {

		auto sz = segment_size_;
		auto which_arr_idx = index / sz;
		return arrays_[which_arr_idx].remove(index % sz);

	} // remove

	ref T opIndex(size_t index) nothrow @nogc {

		auto sz = segment_size_;
		auto which_arr_idx = index / sz;
		return arrays_[which_arr_idx][index % sz];

	} // opIndex

} // SegmentedArray

@name("SegmentedArray 1: add/find")
unittest {

	auto integers = SegmentedArray!int(theAllocator, 32);

	auto tests = [1, 5, 72, 432, 632, 532, 52];

	foreach (i, t; tests) {
		integers.add(t);
		assert(integers[i] == t);
	}

}

private mixin template SOAImpl() {

	import std.traits : Erase, Unqual, staticMap;
	import std.typetuple : TypeTuple;

	alias U = Unqual!T;

	// T may have methods and non-field members, preventing the use of the
	//  allMembers trait.  We work around this by getting the names of the fields
	//  by using tupleof.
	template Iota(size_t I, size_t Len) {
		static if (I < Len)
			alias Iota = TypeTuple!(I, Iota!(I + 1, Len));
		else
			alias Iota = TypeTuple!();
	}
	static enum GetFieldName(size_t I) = T.tupleof[I].stringof;

	// The names of the fields in order
	static enum Fields = Erase!("this", staticMap!(GetFieldName, Iota!(0, T.tupleof.length)));

	// This is required to initialize the arrays to corresponding init values from
	//  the user's T definition
	private static enum T initValues = T.init;

} //https://github.com/economicmodeling/soa MIT License

/**
 * Array type which stores data internally as separate arrays for each given member of
 * the struct it is templated on, useful for when operating on data is done in a member-wise
 * fashion, or pointers to sub-arrays are necessary for passing to GPU, sound subsystem or similar.
 */
struct ArraySOA(T) {

	static assert(is(T == struct), "can only create SOA array from a struct definition.");

	mixin SOAImpl;

	static private string makeMemberArrays() pure {

		import std.array : appender;
		import std.string : format;

		auto app = appender!string();

		foreach (field; Fields) {
			app ~= q{Array!(typeof(U.%s)) %s;}.format(field, field);
		}

		return app.data;

	} // makeMemberArrays

	private void initMemberArrays(Args...)(Args args) {

		import std.string : format;

		foreach (field; Fields) {
			mixin(q{%s = typeof(%s)(%s);}.format(field, field, "args"));
		}

	} // initMemberArrays

	mixin(makeMemberArrays());

	@property {

		import std.string : format;

		void reserve(size_t new_size) {

			foreach(field; Fields) {
				mixin(q{%s.reserve(new_size);}.format(field));
			}

		}

		size_t capacity() const {
			mixin(q{return %s.capacity;}.format(Fields[0]));
		}

		size_t length() const {
			mixin(q{return %s.length;}.format(Fields[0]));
		}

		size_t length(size_t new_length) {

			size_t last_return;

			foreach (field; Fields) {
				mixin(q{last_return = %s.length = new_length;}.format(field));
			}

			return last_return;

		}

	}

	@disable this(this);

	this(IAllocator allocator, size_t initial_size) {

		initMemberArrays(allocator, initial_size);

	} // this

	void add(in T thing) {

		import std.string : format;

		foreach (field; Fields) {
			mixin(q{%s.add(%s.%s);}.format(field, thing.stringof, field));
		}

	} // add

	void remove(size_t index) {

		import std.string : format;

		foreach (field; Fields) {
			mixin(q{%s.remove(%s);}.format(field, index.stringof));
		}

	} // remove

} // ArraySOA

version(unittest) {

	import std.stdio : writefln;

	struct Floats {
		float x, y, z;
	}

}

@name("ArraySOA 1: layout test")
unittest {

	auto array = ArraySOA!Floats(theAllocator, 32);
	auto added_thing = Floats(1.0, 2.0, 3.0);

	array.add(added_thing);
	assert(array.x[0] == added_thing.x);
	assert(array.y[0] == added_thing.y);
	assert(array.z[0] == added_thing.z);

}

size_t toHash(string str) @trusted nothrow {
	return typeid(str).getHash(&str) % 31;
} // toHash for string

size_t toHash(int k) @nogc @safe pure nothrow {
	return k % 31;
} // toHash

size_t toHash(in void* p) @nogc @safe pure nothrow {
	return cast(size_t)p % 31UL;
} // toHash

template isCopyable(T) {
	enum isCopyable = __traits(compiles, function T(T t) { return t; });
} // isCopyable

/**
 * HashMap implementation which uses open addressing rather than separate chaining for
 * cache-efficiency and memory usage reasons, currently linear probing. Currently uses a 
 * fixed load factor threshold of 0.75 as the signal for when to rehash the hashmap.
 * Complexity:
 * * Insertion:
 *    * Best Case: O(1)
 *    * Worst Case: O(N)
 * * Deletion:
 *    * Best Case: O(1)
 *    * Worst Case: O(N)
*/
struct HashMap(K, V) {

	import std.algorithm : move;

	// when used_capacity_ / capacity_ > threshold, expand & rehash!
	enum LOAD_FACTOR_THRESHOLD = 0.75;

	enum State {
		Free,
		Data
	} // State

	struct Entry {
		K key;
		V value;
		State state = State.Free;
		alias value this;
	} // Entry

	private {

		IAllocator allocator_;

		Entry[] array_;
		size_t capacity_;
		size_t used_capacity_;

	}

	@disable this(this);

	this(IAllocator allocator, size_t initial_size) @trusted {

		this.allocator_ = allocator;
		this.array_ = allocator.makeArray!Entry(initial_size);
		this.capacity_ = initial_size;

	} // this

	~this() @trusted {
		if (allocator_ !is null) {
			this.free();
		}
	} // ~this

	void free() {
		this.allocator_.dispose(array_);
	} // free

	static if (isCopyable!K) { /* define only if key type is copyable too */
		@property Array!K keys() @trusted {

			auto arr = Array!K(allocator_, used_capacity_);

			foreach (ref k, ref v; this) {
				arr.add(k);
			}

			return arr;

		} // keys
	}

	static if (isCopyable!V) { /* it only makes sense to define this if value type is copyable */
		@property Array!V values() @trusted {

			auto arr = Array!V(allocator_, used_capacity_);

			foreach (ref k, ref v; this) {
				arr.add(v);
			}

			return arr;

		} // values
	}

	@property size_t length() @safe const {
		return capacity_;
	} // length

	/* move other instance into self */
	private void moveFrom(ref typeof(this) other) {

		this.free();
		this.array_ = move(other.array_);
		this.capacity_ = move(other.capacity_);
		this.used_capacity_ = move(other.used_capacity_);
		this.allocator_ = move(other.allocator_);

		other.allocator_ = null;
		assert(other.allocator_ is null);

	} // moveFrom

	V* opBinaryRight(string op = "in")(in K key) nothrow {

		bool found = false;
		auto index = findIndex(key, found);
		V* ptr = null;

		if (found) {
			ptr = &array_[index].value;
		}

		return ptr;

	} // opBinaryRight

	int opApply(scope int delegate(ref K, ref V) dg) {

		int result = 0;

		foreach (ref i, ref e; array_) {
			if (e.state == State.Data) {
				result = dg(e.key, e.value);
			}
			if (result) break;
		}

		return result;

	} // opApply

	int opApply(scope int delegate(ref V) dg) {

		int result = 0;

		foreach (ref e; array_) {
			if (e.state == State.Data) {
				result = dg(e.value);
			}
			if (result) break;
		}

		return result;

	} // opApply

	void opIndexAssign(V value, K key) @trusted {
		put(key, move(value));
	} // opIndexAssign

	ref V opIndex(in K key) @safe {
		return get(key);
	} // opIndex

	void rehash() @trusted {

		auto temp_map = HashMap!(K, V)(allocator_, capacity_ * 2);

		foreach (ref k, ref v; this) {
			temp_map[k] = move(v);
		}

		this.moveFrom(temp_map);

	} // rehash

	/**
	 * Returns a reference to the value to which the key corresponds, if any,
	 * else it returns a default-constructed value, essentially $(D V.init).
	*/
	ref V get(in K key) @safe nothrow {
		return get_(key);
	} // get

	/*
	 * Finds the index for a given key, if any.
	*/
	private size_t findIndex(in K key, out bool found) @safe nothrow {

		auto index = key.toHash() % capacity_;
		uint searched_elements = 0;
		size_t fallback_index = -1;
		found = true;

		while (array_[index].key != key || array_[index].state == State.Free) {

			if (array_[index].state == State.Free) {
				fallback_index = index;
			}

			if (array_[index].key == key && array_[index].state == State.Data) {
				found = true;
				return index; // found!
			}

			searched_elements++;
			index = (index + 1) % capacity_;

			if (searched_elements == capacity_) {
				found = false;
				return fallback_index;
			}

		}

		return index;

	} // findIndex

	private ref V get_(in K key) @safe nothrow {

		bool found = false;
		auto index = findIndex(key, found);
		return array_[index].value;

	} // get

	/**
	 * Inserts a given value at the position to which the key corresponds, if the spot is free,
	 * else it searches linearly forwards until a free spot is found and it is placed there.
	 * If the number of slots free in the $(D HashMap) is found to be less than the $(D LOAD_FACTOR_THRESHOLD)
	 * then a $(D rehash) operation is performed.
	*/
	void put(ref K key, V value) @trusted {

		import std.algorithm : move;

		auto index = key.toHash() % capacity_;
		auto default_value = K.init;

		if ((cast(float)used_capacity_ / cast(float)capacity_) > LOAD_FACTOR_THRESHOLD) {
			this.rehash();
		}

		while (array_[index].key != key && array_[index].state != State.Free) {
			index = (index + 1) % capacity_;
		}

		if (array_[index].state == State.Free) { // new key/value pair!
			used_capacity_++;
		}

		array_[index] = Entry(key, move(value), State.Data);

	} // put

	bool remove(K key) @trusted {

		auto index = key.toHash() % capacity_;
		uint searched_elements = 0;

		while (array_[index].key != key) {

			if (searched_elements == capacity_) {
				return false;
			}

			searched_elements++;
			index = (index + 1) % capacity_;

		}
		
		array_[index].key = K.init;
		array_[index].value = V.init;
		array_[index].state = State.Free;
		used_capacity_--;

		return true;
		
	} // remove

	/**
	 * Traverses the whole HashMap and sets each element to its $(D .init) value,
	 *  logically clearing it as the length is set to 0 afterwards.
	 * It does not shrink the underlying storage.
	*/
	void clear() @trusted {

		foreach (i, ref e; array_[]) {
			e = Entry.init;
		}

		used_capacity_ = 0;

	} // clear

} // HashMap

version(unittest) {

	struct HashThing {

		string content;

		size_t toHash() const @safe pure nothrow {
			return content.hashOf() * 31;
		} // toHash

		bool opEquals(const typeof(this) s) @safe pure nothrow {
			return content == s.content;
		} // opEquals

		bool opEquals(ref const typeof(this) s) @safe pure nothrow {
			return content == s.content;
		} // opEquals

		bool opEquals(const typeof(this) s) const @safe pure nothrow {
			return content == s.content;
		} // opEquals

	} // HashThing

}

@name("HashMap 1: add/in test")
unittest {

	auto hash_map = HashMap!(HashThing, uint)(theAllocator, 32);

	auto thing = HashThing("hello");

	hash_map[thing] = 255;
	assert(hash_map[thing] == 255);
	assert(thing in hash_map);

	hash_map[thing] = 128;
	assert(hash_map[thing] == 128);
	assert(thing in hash_map);

}

@name("HashMap 2: adding/finding/removing")
unittest {

	import std.string : format;

	auto hash_map = HashMap!(string, uint)(theAllocator, 16);
	enum str = "yes";

	{

		hash_map[str] = 128;
		assert(hash_map[str] == 128);
		auto p = str in hash_map;
		assert(p && *p == 128);

	}

	{

		hash_map[str] = 324;
		assert(hash_map[str] == 324);
		bool success = hash_map.remove(str);
		assert(success, "failed to remove str?");
		assert(hash_map[str] != 324, "entry was still 324?");
		hash_map[str] = 500;
		auto p = str in hash_map;
		assert(p && *p == 500);

	}

	foreach (ref key, ref value; hash_map) {
		assert(key == str && value == 500, format("key or value didn't match, %s : %s", key, value));
	}

}

@name("HashMap 3: rehashing")
unittest { //test expansion

	enum initial_size = 4, rounds = 128;
	auto hash_map = HashMap!(uint, bool)(theAllocator, 4);

	foreach (i; 0..rounds) {
		hash_map[i] = true;
	}

	foreach (i; 0..rounds) {
		assert(hash_map[i]);
	}

}

/**
 * HashMap implementation which instead of hashing to single array places has an array at each
 * key/value index for values to reside in, meaning each key can be associated with several values.
 * Internally uses the aforemented $(D HashMap) implementation, and behaves as such.
*/
struct MultiHashMap(K, V) {

	import std.algorithm : move;

	private {

		HashMap!(K, Array!V) map_;
		size_t start_bucket_size_;

	}

	@disable this(this);

	this(IAllocator allocator, size_t initial_size, size_t bucket_size = 8) {

		this.map_ = typeof(map_)(allocator, initial_size);
		this.start_bucket_size_ = bucket_size;

		foreach(i; 0..initial_size) {
			map_.array_[i].value = Array!V(allocator, bucket_size);
		}

	} // this

	Array!(V)* opBinaryRight(string op = "in")(in K key) nothrow {

		return key in map_;

	} // opBinaryRight

	int opApply(scope int delegate(ref K, ref Array!V) dg) {
		return map_.opApply(dg);
	} // opApply

	int opApply(scope int delegate(ref Array!V) dg) {
		return map_.opApply(dg);
	} // opApply

	ref Array!V opIndex(in K key) @safe {
		return map_.get(key);
	} // opIndex

	void put(K key, V value) @trusted {

		auto bkt = key in map_;

		if (bkt) {
			if (bkt.allocator_ is null) {
				*bkt = typeof(*bkt)(map_.allocator_, start_bucket_size_);
			}
			bkt.add(value);
		} else {
			auto new_bucket = typeof(*bkt)(map_.allocator_, start_bucket_size_);
			new_bucket.add(value);
			map_[key] = move(new_bucket);
		}

	} // put

	bool remove(K key, V value) {

		auto bkt = key in map_;

		if (bkt) {
			return bkt.remove(value);
		}

		return false;

	} // remove

	bool remove(K key) {
		return map_.remove(key);
	} // remove

	ref Array!V get(in K key) @safe {
		return map_.get(key);
	} // get

} // MultiHashMap

@name("MultiHashMap 1")
unittest {

	auto map = MultiHashMap!(int, bool)(theAllocator, 16);

	enum key = 32;
	map.put(key, true);
	map.put(key, false);

	assert(map[key][0] == true);
	assert(map[key][1] == false);

}

struct LinkedList(T) {

	struct Node {
		Node* next;
		T data;
	} // Node
	
	private {

		IAllocator allocator_;

		Node* head_;
		Node* tail_;

	}

	@disable this();
	@disable this(this);

	this(IAllocator allocator) {
		this.allocator_ = allocator;
	}  // this

	~this() {

		auto cur = head_;
		while (cur != null) {
			auto last = cur;
			cur = cur.next;
			allocator_.dispose(last);
		}

	} // ~this

	void add(T item) {

		this.push(&head_, item);

	} // add

	void push(Node** node, ref T data) {

		auto new_node = allocator_.make!Node(null, data);
		new_node.next = *node;

		*node = new_node;

	} // push

	void poll() {

		if (head_) {
			auto last_head = head_;
			head_ = head_.next;
			allocator_.dispose(last_head);
		}

	} // poll

	T* head() {
		return &head_.data;
	} // head

	T* tail() {
		return &tail_.data;
	} // tail

} // LinkedList

version(unittest) {

}

@name("LinkedList 1")
unittest {

	auto list = LinkedList!int(theAllocator);

	list.add(35);
	assert(*list.head() == 35);

}

/**
 * Intrusive single linked list, uses next pointer already present in the type
 * to avoid extra dynamic memory allocation.
*/
struct ILinkedList(T) {

	T* head_;

	void add(T* item) {

		this.add(&head_, item);

	} // add

	private void add(T** node, T* new_node) {

		new_node.next = *node;
		*node = new_node;

	} // add

	void opOpAssign(string op: "~")(T* item) {

		this.add(&head_, item);

	} // opOpAssign

	int opApply(scope int delegate(T*) dg) {

		int result = 0;

		for (auto cur = head_; cur != null; cur = cur.next) {
			result = dg(cur);
			if (result) break;
		}

		return result;

	} // opApply

	/**
	 * Unlinks the head of the linked list, making the next element
	 * the new head of the list. (1, 2, 3, 4) -> (2, 3, 4)
	*/
	void poll() {

		if (head_) {
			head_ = head_.next;
		}

	} // poll

	T* head() {

		return head_;

	} // head

	void clear() {

		head_ = null;

	} // clear

	@property bool empty() {

		return head_ == null;

	} // empty

} // ILinkedList

version(unittest) {

}

@name("ILinkedList 1 (unimplemented)")
unittest {

	assert(0);

}

struct Stack(T) {

	private LinkedList!T list_;

	@disable this();
	@disable this(this);

	this(IAllocator allocator) {
		this.list_ = LinkedList!T(allocator);
	} // this

	void push(T item) {
		list_.add(item);
	} // push

	T* peek() {
		return list_.head();
	} // peek

	T pop() {
		auto item = list_.head();
		if (!item) {
			return T.init;
		} else {
			list_.poll();
			return *item;
		}
	} // pop

} // Stack

version(unittest) {

}

@name("Stack 1")
unittest {

	auto stack = Stack!int(theAllocator);
	stack.push(25);

	assert(*stack.peek() == 25);

}

struct Queue(T) {

	private LinkedList!T list_;

} // Queue

@name("Queue 1 (unimplemented)")
unittest {

	assert(0);

}

struct AtomicQueue(T) {

} // AtomicQueue

@name("AtomicQueue 1 (unimplemented)")
unittest {

	assert(0);

}

/**
 * A ringbuffer/cyclic buffer implementation, internally uses the $(D Array) implementation.
 * Indexes wrap around with respect to the length of the buffer in order to achieve the circularity,
 * useful for instances where discarding older data is not a problem and the zero-allocation characteristic
 * may be deemed useful, for example in a profiler which continually discards old samples as new samples come in,
 * graphing these in the process.
*/
struct CircularBuffer(T) {

	private {

		Array!T array_;
		size_t cur_index;

	}

	@disable this();
	@disable this(this);

	this(IAllocator allocator, size_t buffer_size) {
		this.array_ = typeof(array_)(allocator, buffer_size);
	} // this

	ref T opIndex(size_t index) @safe @nogc nothrow {
		return array_[index % array_.capacity];
	} // opIndex

	void opOpAssign(string op: "~")(T item) @safe @nogc nothrow {
		array_[cur_index % array_.capacity] = item;
		cur_index = (cur_index + 1) % array_.capacity;
	} // opOpAssign

	int opApply(scope int delegate(ref size_t i, ref T) dg) {
		return array_.opApply(dg);
	} // opApply

	int opApply(scope int delegate(ref T) dg) {
		return array_.opApply(dg);
	} // opApply

	@property size_t length() @safe {
		return array_.capacity;
	} // length

	@property const(T*) ptr() {
		return array_.ptr;
	} // ptr

	@property T last(int idx) {
		auto i = (idx + cur_index) % array_.capacity;
		return array_[i];
	} // last

} // CircularBuffer

@name("CircularBuffer 1: circularity test")
unittest {

	auto c_buf = CircularBuffer!double(theAllocator, 32);

	c_buf ~= 15;
	c_buf ~= 25;

	foreach (sample; c_buf) {

	}

	assert(0); //TODO actually implement this

}

/**
 * A d-ary heap implementation, useful as a priority queue for example. Tuning of children count can be set for each
 * use case, depending on the amount of deleteMin, and respectively decreaseKey operations.
 * (one which favors shallow heaps, one which favors deeper ones)
*/
struct DHeap(int N, T) {

	import std.algorithm : move;

	private {

		Array!T array_;
		size_t size_;

	}

	@disable this();
	@disable this(this);

	this(IAllocator allocator, size_t initial_size) {
		this.array_ = typeof(array_)(allocator, initial_size);
	} // this

	size_t nthChild(size_t n, size_t i) {

		return (N * i) + n;

	} // nthChild

	size_t parent(size_t i) {

		return (i-1) / N;

	} // parent

	void percolateUp(size_t cur) {

		if (cur == 0) return;

		auto p = parent(cur);
		if (array_[cur] > array_[p] || array_[cur] == array_[p]) {
			return;
		} else {
			swap(cur, p);
			percolateUp(p);
		}

	} // percolateUp

	void swap(size_t source, size_t target) {

		import smidig.memory : memswap;
		memswap(&array_[source], &array_[target]);

	} // swap

	void insert(T thing) {

		array_[size_] = thing;
		percolateUp(size_);
		size_++;

	} // insert

	void minHeapify(size_t cur) {

		size_t[N] children;
		foreach (i, ref c; children) {
			c = nthChild(i+1, cur);
		}

		auto capacity = size_;
		foreach (c; children) { 
			if (c > capacity) { return; }
		}

		// check if it's actually bigger
		foreach (c; children) {
			if (array_[cur] > array_[c]) {

				size_t smallest_child = size_t.max;

				foreach (inner_c; children) {
					if (smallest_child == size_t.max || array_[smallest_child] > array_[inner_c]) {
						smallest_child = inner_c;
					}
				}

				swap(cur, smallest_child);
				minHeapify(smallest_child);
				return;

			}
		}

	} // minHeapify

	T deleteMin() {

		size_--;
		swap(0, size_); // swap root and last (we want root)
		auto min = &array_[size_];
		auto min_data = move(*min);
		*min = T.max; // value should define a max, so it can be put out of the way in the heap
		minHeapify(0);

		return min_data;

	} // deleteMin

	void increaseKey(size_t i) {

	} // increaseKey

	void decreaseKey(size_t i) {

	} // decreaseKey

} // DHeap

version (unittest) {

	struct CompThing {

		int thing = int.max;

		int opCmp(ref CompThing other) {

			if (thing > other.thing) return 1;
			if (thing < other.thing) return -1;

			return 0;

		} // opCmp

		@property static CompThing max() {

			return CompThing(int.max);

		} // max

	} // CompThing

} 

@name("DHeap 1: insert and deleteMin")
unittest {

	import std.string : format;
	import std.stdio : writefln;
	import std.algorithm : filter;

	auto heap = DHeap!(3, CompThing)(theAllocator, 24);

	heap.insert(CompThing(10));
	heap.insert(CompThing(32));
	heap.insert(CompThing(52));
	heap.insert(CompThing(12));
	heap.insert(CompThing(65));
	heap.insert(CompThing(11));
	heap.insert(CompThing(7));

	auto checks = [7, 10, 11, 12, 32, 52, 65];

	foreach (c; checks) {

		auto min_val = heap.deleteMin();
		auto expected = CompThing(c);
		assert(min_val == expected, format("expected: %s, got: %s, \n tree was: %s", expected, min_val, heap.array_.array_));

	}
}

/**
 * Set implementation ontop of a $(D HashMap).
 * amortized constant time add/exists/remove operations.
*/
struct HashSet(T) {

	HashMap!(T, bool) hashmap_;

	this(IAllocator allocator, size_t initial_size) {
		this.hashmap_ = typeof(hashmap_)(allocator, initial_size);
	} // this

	bool add(T item) {

		auto exists = item in hashmap_;

		if (!exists) {
			hashmap_[item] = true;
		}

		return !exists;

	} // add

	bool exists(T item) {

		auto ptr = item in hashmap_;
		return !!ptr;

	} // exists

	bool remove(T item) {

		return hashmap_.remove(item);

	} // remove

} // HashSet

@name("HashSet 1: add/exists test")
unittest {

	auto set = HashSet!int(theAllocator, 32);

	set.add(24);
	assert(set.exists(24));

}

struct QuadTree {

	struct Quadrant {

		Quadrant*[4] quads;

	} // Quadrant

	IAllocator allocator_;
	Array!Quadrant quadrants_;

	this(IAllocator allocator, size_t initial_size) {

	} // this

	~this() {

	} // ~this

} // QuadTree

@name("QuadTree 1 (unimplemented)")
unittest {

	assert(0);

}

/**
 * Immutable String type, has a length and guaranteed null terminator.
 * The null terminator is in place to make interaction with C and C++ code which
 * expects one easier and more performant.
*/
struct String {

	import std.algorithm : move;

	private {

		IAllocator allocator_;
		Array!char array_ = void; //TODO look at this, is this right?

	}

	@disable this(this);

	this(ref String str, in char[] input) {
		
		auto input_length = input.length;
		if(input[$-1] == '\0') {
			input_length -= 1;
		}

		this.allocator_ = theAllocator;
		this.array_ = typeof(array_)(allocator_, str.length + input_length + 1);
		this.array_.length = str.length + input_length;

		this.array_[][0..str.length] = str[];
		this.array_[][str.length..str.length+input_length] = input[0..input_length];
		this.array_[$] = '\0'; // HELLA NULL TERMINATION SON

	} // this

	this(in char[] input) {

		auto input_length = input.length;

		if (input_length != 0) {
			if(input[$-1] == '\0') {
				input_length -= 1;
			}
		}

		this.allocator_ = theAllocator;
		this.array_ = typeof(array_)(allocator_, input_length + 1);
		this.array_.length = input_length;

		this.array_[][0..input_length] = input[0..input_length];
		this.array_[$] = '\0'; //HELLA NULL TERMINATION SON

	} // this

	void opAssign(String other) {
		this.array_ = move(other.array_);
	} // opAssign

	@property size_t length() const nothrow @nogc {
		return array_.length;
	} // length

	size_t toHash() @safe const nothrow {
		return d_str().toHash();
	} // toHash

	const(char[]) opSlice() nothrow {
		return array_[0..length];
	} // opSlice

	const(char[]) opSlice(size_t h, size_t t) nothrow {
		return array_[h..t];
	} // opSlice

	bool opEquals(in char[] other) {

		foreach (i, ref c; array_) {
			if (array_[i] != other[i]) {
				return false;
			}
		}

		return true;

	} // opEquals

	bool opEquals(ref String other) {

		if (other is this) {
			return true;
		}

		return this.opEquals(other.array_[]);

	} // opEquals

	String opBinary(string op: "~")(ref String str) {
		return String(this, str.d_str);
	} // opBinary

	String opBinary(string op: "~")(in char[] chars) {
		return String(this, chars);
	} // opBinary

	const(char*) c_str() const nothrow @nogc {
		return array_.ptr;
	} // c_str

	string d_str() const nothrow @nogc @trusted {
		return cast(immutable(char)[])array_[];
	} // d_str

} // String

@name("String 1")
unittest {

	auto str = String("yes");
	auto new_string = str ~ "other_thing";

	assert(new_string == "yes" ~ "other_thing");
	assert(new_string.d_str == "yes" ~ "other_thing");

}

/**
 * A mutable string buffer, intended for when the replace-everything on mutation characteristic of $(D String) isn't desireable,
 * for example with a text buffer for a chat window or similar. Uses a $(D Array) internally to hold the chars.
 * Also Maintains a guaranteed null terminator, just like the equivalent String type.
*/
struct StringBuffer {

	private {

		Array!char array_;

	}

	@disable this();
	@disable this(this);

	this(size_t initial_size) {

		this.array_ = typeof(array_)(theAllocator, initial_size);

	} // this

	@property size_t length() const @nogc {
		return array_.length;
	} // length

	void opOpAssign(string op: "~")(in char[] str) {

		array_ ~= str;

		if (str[$-1] != '\0') {
			array_ ~= '\0';
		}

		array_.length(array_.length-1);

	} // opOpAssign

	void opOpAssign(string op: "~")(ref String str) {

		array_ ~= str[];

	} /// opOpAssign

	const(char*) c_str() const nothrow @nogc {
		return array_.ptr;
	} // c_str

	void scanToNull() {

		auto index = 0;
		while (index < array_.capacity-1 && array_[index] != '\0') {
			index++;
		}

		if (index < array_.capacity-1 && array_[index] == '\0') {
			array_.length = index+1;
		}

	} // scanToNull

} // StringBuffer

@name("StringBuffer 1")
unittest {

	import core.stdc.stdio : printf;
	import core.stdc.string : strlen;

	auto strbuf = StringBuffer(32);
	strbuf ~= "yes \n";

	assert(strlen(strbuf.c_str()) == strbuf.length);

}

/**
 * Buffer based on an Array, meant to be an output stream for data.
*/
struct ByteBuffer {

	private {
		Array!ubyte buffer_;
	}

} // ByteBuffer

struct ScopedBuffer(T) {

	private {

		IAllocator allocator_;
		T[] buffer_;

	}

	@disable this(this);

	this(IAllocator allocator, size_t elements) {
		this.buffer_ = allocator.makeArray!T(elements);
		this.allocator_ = allocator;
	} // this

	~this() {
		if (allocator_ !is null) {
			this.allocator_.dispose(buffer_);
		}
	} // ~this

	alias buffer_ this; // careful!

} // ScopedBuffer

version (unittest) {

	struct DestructTest {

		int* var;
		int target;

		this(int* v, int t) {
			this.var = v;
			this.target = t;
		}

		~this() {
			if (var != typeof(var).init) {
				*var = target;
			}
		}

	}

}

@name("ScopedBuffer 1: indexing")
unittest {

	import std.range : iota;
	import std.string : format;
	import std.random : uniform;

	enum runs = 500, size = 128;

	auto buf = ScopedBuffer!int(theAllocator, size);

	foreach (i; iota(runs)) {
		auto index = uniform(0, size-1);
		buf[index] = i;
		assert(buf[index] == i, format("buf[index] was %d, expected %d", buf[index], i));
	}

}

@name("ScopedBuffer 2: destructors")
unittest {

	int testing_var = 256;
	enum target = int.max;

	{
		auto buf = ScopedBuffer!DestructTest(theAllocator, 4);
		buf[2] = DestructTest(&testing_var, target);
	}

	assert(testing_var == target, "destructor didn't fire for DestructTest?");

}

/**
 * Stack allocated array implementation, used when a heap allocation isn't desirable, or the size of the data
 * is known and is small enough to fit on the stack. Tries to behave largely like the built in arrays.
*/
struct StaticArray(T, size_t size) {

	private size_t elements = 0;
	private T[size] array;

	this(T[] items) {
		foreach(ref e; items) {
			array[elements++] = e;
		}
	} // this

	@property size_t length() const {
		return elements;
	} // length

	@property void length(size_t new_length) {
		elements = new_length;
	} // length

	@property size_t capacity() const {
		return array.length;
	} // capacity

	@property T* ptr() {
		return array.ptr;
	} // ptr

	/**
	 * Adjusts the buffer's length var to where the null-terminator is (if any).
	 * Used when the buffer has a null-terminator and it is manipulated by a C function,
	 * so that the length var has not changed, but the buffer contents have, requiring
	 * a manual adjustment. (only applies if buffer data is of type char)
	*/
	static if (is(T == char)) {
		void scanToNull() {

			auto index = 0;
			while (index < array.length-1 && array[index] != '\0') {
				index++;
			}

			if (index < array.length-1 && array[index] == '\0') {
				elements = index+1;
			}

		} // scanToNull
	}

	size_t opDollar(int dim)() const {
		static assert(dim == 0);
		return elements;
	} // opDollar

	void opOpAssign(string op: "~")(T item) {
		array[elements++] = item;
	} // opOpAssign

	void opOpAssign(string op: "~")(in T[] items) {
		foreach(e; items) {
			array[elements++] = e;
		}
	} // opOpAssign

	ref T opIndex(size_t i) {
		return array[i];
	} // opIndex

	// whole thing
	T[] opSlice() {
		return array[0..elements];
	} // opSlice

	T[] opSlice(size_t h, size_t t) {
		return array[h..t];
	} // opSlice

	ref T opIndexAssign(T value, size_t i) {
		return array[i] = value;
	} // opIndexAssign

	void opAssign(StaticArray!(T, size) other) { //TODO should it clean up the contents it has in it first?
		this.array = other.array;
		this.elements = other.elements;
	} // opAssign

} // StaticArray

@name("StaticArray 1")
unittest {

	import std.conv : to;
	import std.string : format;

	// StaticArray
	const int size = 10;
	auto arr = StaticArray!(int, size)();
	arr[size-1] = 100;
	assert(arr[size-1] == 100, format("expected arr[%d] to be %d, was %d", size-1, 100, arr[size-1]));

	int[5] int_a = [1, 2, 3, 4, 5];
	arr ~= int_a;
	assert(arr.elements == 5, format("expected num of elements to be 5, was: %s", arr.elements));
	assert(arr[$-1] == 5, format("expected last element to be 5, was: %s", arr[$]));

}
