extends RefCounted
class_name NumberFormatter

## Compact number formatter ported from the JS prototype.

const SUFFIXES := ["K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]


static func format_number(value: int) -> String:
	if value <= 0:
		return "0"
	if value < 1000:
		return str(value)

	var tier := int(floor(log(float(value)) / log(10.0) / 3.0))
	var suffix := _suffix_for_tier(tier)
	var scaled := float(value) / pow(1000.0, tier)
	var text := ""
	if scaled < 10.0:
		text = "%.2f" % scaled
	elif scaled < 100.0:
		text = "%.1f" % scaled
	else:
		text = str(int(floor(scaled)))

	while text.ends_with("0") and text.contains("."):
		text = text.substr(0, text.length() - 1)
	if text.ends_with("."):
		text = text.substr(0, text.length() - 1)
	return text + suffix


static func _suffix_for_tier(tier: int) -> String:
	var index := tier - 1
	if index >= 0 and index < SUFFIXES.size():
		return SUFFIXES[index]
	return _generate_aa_suffix(index - SUFFIXES.size())


static func _generate_aa_suffix(index: int) -> String:
	var result := ""
	var n := maxi(0, index) + 1
	while n > 0:
		n -= 1
		result = String.chr(97 + (n % 26)) + result
		n = int(floor(float(n) / 26.0))
	return result
