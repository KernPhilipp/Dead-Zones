extends RefCounted
class_name SpawnExecutor

func execute_due_entries(
	wave_plan: Dictionary,
	elapsed_wave_time: float,
	alive_count: int,
	alive_cap: int,
	delay_step_seconds: float,
	retry_limit: int,
	spawn_callback: Callable
) -> Dictionary:
	var plan: Dictionary = wave_plan.duplicate(true)
	var entries: Array = plan.get("entries", [])
	var pending_index: int = int(plan.get("pending_index", 0))
	var local_alive: int = max(0, alive_count)
	var local_delay: float = maxf(0.05, delay_step_seconds)
	var local_retry_limit: int = max(1, retry_limit)
	var cap_enabled: bool = alive_cap > 0

	var spawned_now: int = 0
	var delayed_now: int = 0
	var failed_now: int = 0

	while pending_index < entries.size():
		var entry: Dictionary = entries[pending_index]
		var planned_time: float = float(entry.get("planned_earliest_time", 0.0))
		if planned_time > elapsed_wave_time:
			break

		if cap_enabled and local_alive >= alive_cap:
			entry["state"] = "delayed"
			entry["planned_earliest_time"] = planned_time + local_delay
			entries[pending_index] = entry
			delayed_now += 1
			break

		var spawn_success: bool = false
		if spawn_callback.is_valid():
			spawn_success = bool(spawn_callback.call(entry))

		if spawn_success:
			entry["state"] = "spawned"
			entries[pending_index] = entry
			pending_index += 1
			spawned_now += 1
			local_alive += 1
			continue

		var attempts: int = int(entry.get("spawn_attempts", 0)) + 1
		entry["spawn_attempts"] = attempts
		if attempts >= local_retry_limit:
			entry["state"] = "failed"
			entries[pending_index] = entry
			pending_index += 1
			failed_now += 1
		else:
			entry["state"] = "delayed"
			entry["planned_earliest_time"] = planned_time + local_delay
			entries[pending_index] = entry
			delayed_now += 1
			break

	plan["entries"] = entries
	plan["pending_index"] = pending_index

	return {
		"wave_plan": plan,
		"pending_index": pending_index,
		"spawned_now": spawned_now,
		"delayed_now": delayed_now,
		"failed_now": failed_now
	}
