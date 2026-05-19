extends SceneTree
## Minimal test harness — runs GDScript test files headlessly without GUT.
## Usage: godot4 --headless -s res://tests/test_harness.gd -- <test_files...>
##
## Test files should extend Node and define methods prefixed with "test_".
## They can use assert_* functions inherited from the harness.

var _passed: int = 0
var _failed: int = 0
var _current_test: String = ""
var _test_errors: Array[String] = []


func _init() -> void:
	# Can't await in _init() for SceneTree scripts. Defer to first frame.
	process_frame.connect(_run_all_tests, CONNECT_ONE_SHOT)


func _run_all_tests() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() == 0:
		print("Usage: godot4 --headless -s res://tests/test_harness.gd -- <test_files...>")
		print("  Each test file should define test_* methods on a Node script.")
		quit(1)
		return

	# Register self so test scripts can find us for _fail reporting
	get_root().set_meta("__test_harness__", self)

	for test_path in args:
		await _run_file(test_path)

	_print_summary()
	quit(0 if _failed == 0 else 1)


func _run_file(path: String) -> void:
	print("--- Loading: %s ---" % path)
	var script := load(path) as GDScript
	if not script:
		push_error("Failed to load: %s" % path)
		return

	var instance = script.new()
	if not instance:
		push_error("Failed to instantiate: %s" % path)
		return

	get_root().add_child(instance)

	# Discover test methods
	var methods: Array[String] = []
	for method: Dictionary in instance.get_method_list():
		var mname: String = method["name"]
		if mname.begins_with("test_"):
			methods.append(mname)

	if methods.size() == 0:
		print("  (no test_* methods found)")
		instance.queue_free()
		return

	# Run before_all if present
	if instance.has_method("before_all"):
		print("  [before_all]")
		await instance.before_all()
		await _wait_frames(2)

	for method_name in methods:
		_current_test = "%s::%s" % [path, method_name]
		_test_errors.clear()

		# Run before_each if present
		if instance.has_method("before_each"):
			await instance.before_each()
			await _wait_frames(2)

		# Run the test method (await to handle async methods)
		await instance.call(method_name)

		# Run after_each if present
		if instance.has_method("after_each"):
			await instance.after_each()
			await _wait_frames(2)

		if _test_errors.size() > 0:
			_failed += 1
			print("  FAIL: %s" % method_name)
			for err in _test_errors:
				print("    %s" % err)
		else:
			_passed += 1
			print("  PASS: %s" % method_name)

	# Run after_all if present
	if instance.has_method("after_all"):
		print("  [after_all]")
		await instance.after_all()
		await _wait_frames(2)

	instance.queue_free()


func _wait_frames(n: int) -> void:
	for _i in range(n):
		await process_frame


func _fail(message: String) -> void:
	_test_errors.append(message)


# --- Assertions (also available to test scripts via call) ---

func assert_true(value: bool, message: String = "") -> void:
	if not value:
		_fail(message if message else "Expected true, got false")

func assert_false(value: bool, message: String = "") -> void:
	if value:
		_fail(message if message else "Expected false, got true")

func assert_eq(actual, expected, message: String = "") -> void:
	if actual != expected:
		_fail(message if message else "Expected %s, got %s" % [str(expected), str(actual)])

func assert_ne(actual, unexpected, message: String = "") -> void:
	if actual == unexpected:
		_fail(message if message else "Expected != %s" % str(unexpected))

func assert_gt(actual, threshold, message: String = "") -> void:
	if not (actual > threshold):
		_fail(message if message else "Expected %s > %s" % [str(actual), str(threshold)])

func assert_lt(actual, threshold, message: String = "") -> void:
	if not (actual < threshold):
		_fail(message if message else "Expected %s < %s" % [str(actual), str(threshold)])

func assert_not_null(value, message: String = "") -> void:
	if value == null:
		_fail(message if message else "Expected non-null value")

func assert_null(value, message: String = "") -> void:
	if value != null:
		_fail(message if message else "Expected null, got %s" % str(value))


func _print_summary() -> void:
	var total := _passed + _failed
	print("\n=== Test Results ===")
	print("  Total:  %d" % total)
	print("  Passed: %d" % _passed)
	print("  Failed: %d" % _failed)
	if _failed == 0:
		print("  ALL TESTS PASSED")
	else:
		print("  SOME TESTS FAILED")
