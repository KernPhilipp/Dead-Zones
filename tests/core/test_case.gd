extends RefCounted
class_name TestCase

var name: String = ""
var checks: int = 0
var failures: Array[String] = []
var notes: Array[String] = []

func _init(test_name: String = ""):
	name = test_name

func add_note(message: String):
	notes.append(message)

func assert_true(condition: bool, message: String):
	checks += 1
	if not condition:
		failures.append(message)

func assert_false(condition: bool, message: String):
	assert_true(not condition, message)

func assert_eq(actual, expected, message: String):
	checks += 1
	if actual != expected:
		failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])

func assert_near(actual: float, expected: float, epsilon: float, message: String):
	checks += 1
	if absf(actual - expected) > epsilon:
		failures.append("%s | expected=%f actual=%f eps=%f" % [message, expected, actual, epsilon])

func assert_in_range(value: float, min_value: float, max_value: float, message: String):
	checks += 1
	if value < min_value or value > max_value:
		failures.append("%s | expected_range=[%f,%f] actual=%f" % [message, min_value, max_value, value])

func passed() -> bool:
	return failures.is_empty()

func to_dict() -> Dictionary:
	return {
		"name": name,
		"checks": checks,
		"passed": passed(),
		"failure_count": failures.size(),
		"failures": failures.duplicate(),
		"notes": notes.duplicate()
	}
