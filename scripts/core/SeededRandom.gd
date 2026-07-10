extends RefCounted
class_name SeededRandom

## Xorshift32-compatible deterministic RNG ported from js/core/SeededRandom.js.

var seed: int = 0xa5a5a5a5


func _init(seed_value: int = 0) -> void:
	seed = seed_value if seed_value != 0 else 0xa5a5a5a5


func next_u32() -> int:
	var x := seed & 0xffffffff
	x = (x ^ ((x << 13) & 0xffffffff)) & 0xffffffff
	x = (x ^ (x >> 17)) & 0xffffffff
	x = (x ^ ((x << 5) & 0xffffffff)) & 0xffffffff
	seed = x & 0xffffffff
	return seed


func next_float() -> float:
	return float(next_u32()) / 4294967296.0


func next_int(max_exclusive: int) -> int:
	return next_u32() % maxi(1, max_exclusive)


static func hash_to_seed(text: String) -> int:
	var h := 0x811c9dc5
	for i in text.length():
		h = h ^ text.unicode_at(i)
		h = (h * 0x01000193) & 0xffffffff
	return h
