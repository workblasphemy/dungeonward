extends RefCounted
## M1 local-only device ownership. Device IDs are transient and never profile IDs.
## Host session_player_id is assigned by the lobby, not this registry.
const MAX_LOCAL_SLOTS := 4

var _devices: Dictionary = {}
var _slots: Dictionary = {}

func _result(ok: bool, code: String, extra: Dictionary = {}) -> Dictionary:
    var result := {"ok": ok, "error_code": code}
    result.merge(extra)
    return result

func bind_device(device_id: int, local_slot_id: int) -> Dictionary:
    if device_id < 0 or local_slot_id < 0 or local_slot_id >= MAX_LOCAL_SLOTS:
        return _result(false, "INVALID_ID")
    if _devices.has(device_id):
        return _result(false, "DEVICE_ASSIGNED")
    if _slots.has(local_slot_id):
        return _result(false, "SLOT_OCCUPIED")
    _devices[device_id] = {"local_slot_id": local_slot_id, "connected": true}
    _slots[local_slot_id] = device_id
    return _result(true, "OK")

func disconnect_device(device_id: int) -> Dictionary:
    if not _devices.has(device_id):
        return _result(false, "NOT_FOUND")
    _devices[device_id]["connected"] = false
    return _result(true, "OK")

func reconnect_device(device_id: int) -> Dictionary:
    if not _devices.has(device_id):
        return _result(false, "NOT_FOUND")
    _devices[device_id]["connected"] = true
    return _result(true, "OK")

func unbind_device(device_id: int) -> Dictionary:
    if not _devices.has(device_id):
        return _result(true, "OK")
    var local_slot_id: int = _devices[device_id]["local_slot_id"]
    _devices.erase(device_id)
    _slots.erase(local_slot_id)
    return _result(true, "OK")

func slot_for_device(device_id: int) -> int:
    if not _devices.has(device_id):
        return -1
    return _devices[device_id]["local_slot_id"]

func device_for_slot(local_slot_id: int) -> int:
    return _slots.get(local_slot_id, -1)

func is_connected(device_id: int) -> bool:
    return _devices.has(device_id) and _devices[device_id]["connected"]

func assignments() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for slot_id in _slots.keys():
        var device_id: int = _slots[slot_id]
        result.append({"local_slot_id": slot_id, "device_id": device_id,
            "connected": _devices[device_id]["connected"]})
    result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return a["local_slot_id"] < b["local_slot_id"])
    return result
