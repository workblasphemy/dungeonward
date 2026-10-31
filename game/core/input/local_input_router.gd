extends RefCounted
## Pure local device-to-slot routing. No scene, transport, or gameplay command ownership.
## The caller owns lifecycle reset; device IDs are transient, not player identities.
var _registry: RefCounted
var _allowed: Dictionary = {}
var _sequences: Dictionary = {}

func _init(device_registry: RefCounted, allowed_actions: Array = []) -> void:
    _registry = device_registry
    # Invalid configuration fails closed; set_allowed_actions returns a visible error.
    set_allowed_actions(allowed_actions)

func _result(ok: bool, code: String, event: Dictionary = {}) -> Dictionary:
    return {"ok": ok, "error_code": code, "event": event}

func set_allowed_actions(actions: Array) -> Dictionary:
    var validated: Dictionary = {}
    for value in actions:
        if not (value is String):
            _allowed.clear()
            return _result(false, "INVALID_ACTION_TYPE")
        var action: String = value
        if action.is_empty():
            _allowed.clear()
            return _result(false, "EMPTY_ACTION")
        validated[action] = true
    _allowed = validated
    return _result(true, "OK")

func reset_device_sequence(device_id: int) -> Dictionary:
    if device_id < 0:
        return _result(false, "INVALID_ID")
    # Trusted adapter only, on an explicitly acknowledged new device stream.
    _sequences.erase(device_id)
    return _result(true, "OK")

func route_action(device_id: int, action: String, pressed: bool, sequence: int) -> Dictionary:
    if device_id < 0:
        return _result(false, "INVALID_ID")
    if sequence < 0:
        return _result(false, "INVALID_SEQUENCE")
    if action.is_empty():
        return _result(false, "EMPTY_ACTION")
    if not _allowed.has(action):
        return _result(false, "ACTION_NOT_ALLOWED")
    if _registry == null:
        return _result(false, "REGISTRY_UNAVAILABLE")
    var slot: int = _registry.slot_for_device(device_id)
    if slot < 0:
        return _result(false, "NOT_FOUND")
    if not _registry.device_is_connected(device_id):
        return _result(false, "DEVICE_DISCONNECTED")
    if sequence <= int(_sequences.get(device_id, -1)):
        return _result(false, "STALE_OR_DUPLICATE_SEQUENCE")
    _sequences[device_id] = sequence
    return _result(true, "OK", {"local_slot_id": slot, "device_id": device_id,
        "action": action, "pressed": pressed, "sequence": sequence})
