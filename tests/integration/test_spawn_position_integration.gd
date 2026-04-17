extends RefCounted

const TestCase = preload("res://tests/core/test_case.gd")
const SpawnPositionValidator = preload("res://scripts/wave/spawn_position_validator.gd")

class StubSpawnProvider:
	extends RefCounted

	var samples: Array[Dictionary] = []
	var index: int = 0

	func _init(initial_samples: Array[Dictionary]):
		samples = initial_samples.duplicate(true)
		index = 0

	func pick_random_position(_rng: RandomNumberGenerator) -> Dictionary:
		if samples.is_empty():
			return {"valid": false, "position": Vector3.ZERO, "point_name": ""}
		var current: Dictionary = samples[min(index, samples.size() - 1)]
		index += 1
		return current

class StubPlayer:
	extends Node3D

func run(seed: int = 1337) -> Dictionary:
	var tc := TestCase.new("integration.spawn_position")
	var validator: SpawnPositionValidator = SpawnPositionValidator.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(seed)

	var player := StubPlayer.new()
	player.global_position = Vector3.ZERO

	var provider_success := StubSpawnProvider.new([
		{"valid": true, "position": Vector3(2, 1, 1), "point_name": "near_1"},
		{"valid": true, "position": Vector3(3, 1, 2), "point_name": "near_2"},
		{"valid": true, "position": Vector3(15, 1, 15), "point_name": "far_ok"}
	])
	var found: Dictionary = validator.find_valid_position(provider_success, player, 10.0, 6, rng)
	tc.assert_true(bool(found.get("valid", false)), "validator_accepts_far_point")
	tc.assert_true(Vector3(found.get("position", Vector3.ZERO)).distance_to(player.global_position) >= 10.0, "validator_distance_respected")
	tc.assert_eq(String(found.get("point_name", "")), "far_ok", "validator_retried_until_valid")

	var provider_fail := StubSpawnProvider.new([
		{"valid": true, "position": Vector3(1, 1, 1), "point_name": "near_only"}
	])
	var not_found: Dictionary = validator.find_valid_position(provider_fail, player, 10.0, 3, rng)
	tc.assert_false(bool(not_found.get("valid", true)), "validator_reports_invalid_after_retries")
	tc.assert_eq(int(not_found.get("attempts", 0)), 3, "validator_retry_count")

	return tc.to_dict()
