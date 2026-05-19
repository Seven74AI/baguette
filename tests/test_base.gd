extends Node
## Base class for test scripts. Provides assertion methods.
## The test harness calls these assertions, which record failures for later reporting.


func assert_true(value: bool, message: String = "") -> void:
	if not value:
		_record_fail(message if message else "Expected true, got false")


func assert_false(value: bool, message: String = "") -> void:
	if value:
		_record_fail(message if message else "Expected false, got true")


func assert_eq(actual, expected, message: String = "") -> void:
	if actual != expected:
		_record_fail(message if message else "Expected %s, got %s" % [str(expected), str(actual)])


func assert_ne(actual, unexpected, message: String = "") -> void:
	if actual == unexpected:
		_record_fail(message if message else "Expected != %s" % str(unexpected))


func assert_gt(actual, threshold, message: String = "") -> void:
	if not (actual > threshold):
		_record_fail(message if message else "Expected %s > %s" % [str(actual), str(threshold)])


func assert_lt(actual, threshold, message: String = "") -> void:
	if not (actual < threshold):
		_record_fail(message if message else "Expected %s < %s" % [str(actual), str(threshold)])


func assert_not_null(value, message: String = "") -> void:
	if value == null:
		_record_fail(message if message else "Expected non-null value")


func assert_null(value, message: String = "") -> void:
	if value != null:
		_record_fail(message if message else "Expected null, got %s" % str(value))


func _record_fail(message: String) -> void:
	# Push failure up to the test harness via root meta
	var harness = get_tree().root.get_meta("__test_harness__")
	if harness and harness.has_method("_fail"):
		harness._fail(message)
	else:
		push_error("TEST FAIL: %s" % message)
